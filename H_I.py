import cv2
import mediapipe as mp
import numpy as np
import pyttsx3
import time
import threading
from collections import deque

# Configuration
BUTTONS = [["Food", "Medicine"], ["Washroom", "Other"]]

COLORS = {
    "background": (40, 40, 40),
    "grid": (80, 80, 80),
    "button": (70, 70, 70),
    "selected": (0, 200, 0),
    "text": (255, 255, 255),
    "cursor": (0, 0, 255),
    "cooldown": (200, 0, 0),
    "debug": (0, 255, 255)  # For debugging visuals
}

FONT = cv2.FONT_HERSHEY_SIMPLEX
FONT_SCALE = 2
FONT_THICKNESS = 3

# Tracking parameters
MIN_STABLE_FRAMES = 15
MIN_CONFIDENCE = 0.85
COOLDOWN_SEC = 2.0
SMOOTHING_FACTOR = 0.8
PREVIEW_SIZE = 200
CURSOR_RADIUS = 12

# Iris tracking parameters
IRIS_SENSITIVITY = 10.0  # Greatly increased sensitivity
DEBUG_MODE = True  # Set to True to see detection visuals

class EyeGazeApp:
    def __init__(self):
        self._init_components()
        self._setup_state()

    def _init_components(self):
        self.tts_engine = pyttsx3.init()
        self.tts_engine.setProperty('rate', 150)

        self.face_mesh = mp.solutions.face_mesh.FaceMesh(
            refine_landmarks=True,
            max_num_faces=1,
            min_detection_confidence=0.90,
            min_tracking_confidence=0.90
        )

        self.cap = cv2.VideoCapture(0)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        self.cap.set(cv2.CAP_PROP_FPS, 60)

        self.thread = None
        self.running = True
        self.frame_lock = threading.Lock()
        self.latest_frame = None

    def _setup_state(self):
        self.gaze_history = deque(maxlen=30)
        self.last_spoken = None
        self.last_spoken_time = 0
        self.smoothed_gaze = np.array([0.5, 0.5])
        self.in_cooldown = False
        self.cooldown_end_time = 0

    def _enhance_frame(self, frame):
        # Convert to grayscale for better iris detection
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        # Apply histogram equalization
        gray = cv2.equalizeHist(gray)
        # Convert back to BGR
        enhanced = cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)
        return enhanced

    def _calculate_gaze(self, landmarks, width, height):
        try:
            # Iris landmarks (MediaPipe 0.10.0+)
            LEFT_IRIS = [474, 475, 476, 477]
            RIGHT_IRIS = [469, 470, 471, 472]
            
            # Get iris centers in image coordinates
            left_iris = np.mean([(landmarks[i].x * width, landmarks[i].y * height) for i in LEFT_IRIS], axis=0)
            right_iris = np.mean([(landmarks[i].x * width, landmarks[i].y * height) for i in RIGHT_IRIS], axis=0)
            
            # Calculate gaze center between both irises
            gaze_center = (left_iris + right_iris) / 2
            
            # Convert to normalized coordinates with sensitivity boost
            norm_x = 0.5 + (gaze_center[0]/width - 0.5) * IRIS_SENSITIVITY
            norm_y = 0.5 + (gaze_center[1]/height - 0.5) * IRIS_SENSITIVITY
            
            # Clip to screen boundaries
            norm_x = np.clip(norm_x, 0.0, 1.0)
            norm_y = np.clip(norm_y, 0.0, 1.0)
            
            if DEBUG_MODE:
                # Draw debug information
                debug_frame = np.zeros((height, width, 3), dtype=np.uint8)
                cv2.circle(debug_frame, (int(left_iris[0]), int(left_iris[1])), 5, COLORS["debug"], -1)
                cv2.circle(debug_frame, (int(right_iris[0]), int(right_iris[1])), 5, COLORS["debug"], -1)
                cv2.circle(debug_frame, (int(gaze_center[0]), int(gaze_center[1])), 8, (0, 255, 0), -1)
                cv2.imshow("Iris Detection Debug", debug_frame)
            
            return np.array([norm_x, norm_y]), 1.0
            
        except Exception as e:
            print(f"Gaze calculation error: {e}")
            return np.array([0.5, 0.5]), 0.0

    def _determine_selection(self, gaze_pos):
        row = 0 if gaze_pos[1] < 0.5 else 1
        col = 0 if gaze_pos[0] < 0.5 else 1
        return BUTTONS[row][col]

    def _check_stability(self, selection):
        if len(self.gaze_history) < MIN_STABLE_FRAMES:
            return False
        recent = [s for s, _ in list(self.gaze_history)[-MIN_STABLE_FRAMES:]]
        return all(sel == selection for sel in recent)

    def _speak(self, text):
        try:
            self.tts_engine.say(text)
            self.tts_engine.runAndWait()
            self.in_cooldown = True
            self.cooldown_end_time = time.time() + COOLDOWN_SEC
        except Exception as e:
            print(f"TTS error: {e}")

    def _create_ui(self, base_frame, camera_preview, selection=None):
        h, w = base_frame.shape[:2]
        cell_h, cell_w = h // 2, w // 2

        base_frame[:] = COLORS["background"]

        if self.in_cooldown:
            remaining = max(0, self.cooldown_end_time - time.time())
            cv2.putText(base_frame, f"Cooldown: {remaining:.1f}s", (w - 300, 40),
                        FONT, 0.8, COLORS["cooldown"], 2)

        for row in range(2):
            for col in range(2):
                x1, y1 = col * cell_w, row * cell_h
                x2, y2 = x1 + cell_w, y1 + cell_h
                label = BUTTONS[row][col]
                selected = (label == selection and not self.in_cooldown)
                color = COLORS["selected"] if selected else COLORS["button"]

                cv2.rectangle(base_frame, (x1, y1), (x2, y2), color, -1)
                size = cv2.getTextSize(label, FONT, FONT_SCALE, FONT_THICKNESS)[0]
                text_x = x1 + (cell_w - size[0]) // 2
                text_y = y1 + (cell_h + size[1]) // 2
                cv2.putText(base_frame, label, (text_x, text_y),
                            FONT, FONT_SCALE, COLORS["text"], FONT_THICKNESS)

        cv2.line(base_frame, (cell_w, 0), (cell_w, h), COLORS["grid"], 2)
        cv2.line(base_frame, (0, cell_h), (w, cell_h), COLORS["grid"], 2)

        preview = cv2.resize(camera_preview, (PREVIEW_SIZE, PREVIEW_SIZE))
        base_frame[10:PREVIEW_SIZE + 10, 10:PREVIEW_SIZE + 10] = preview
        cv2.rectangle(base_frame, (10, 10), (PREVIEW_SIZE + 10, PREVIEW_SIZE + 10),
                      COLORS["selected"], 2)

        cx = int(self.smoothed_gaze[0] * w)
        cy = int(self.smoothed_gaze[1] * h)
        cv2.circle(base_frame, (cx, cy), CURSOR_RADIUS, COLORS["cursor"], -1)

        if selection and not self.in_cooldown:
            info = f"Selected: {selection}"
            cv2.putText(base_frame, info, (PREVIEW_SIZE + 30, 40),
                        FONT, 0.8, COLORS["selected"], 2)

    def _camera_thread(self):
        while self.running:
            ret, frame = self.cap.read()
            if not ret:
                continue
            with self.frame_lock:
                self.latest_frame = frame

    def run(self):
        self.thread = threading.Thread(target=self._camera_thread, daemon=True)
        self.thread.start()

        try:
            while True:
                if self.in_cooldown and time.time() > self.cooldown_end_time:
                    self.in_cooldown = False

                with self.frame_lock:
                    if self.latest_frame is None:
                        continue
                    frame = self.latest_frame.copy()

                frame = cv2.flip(frame, 1)
                enhanced_frame = self._enhance_frame(frame)
                h, w = frame.shape[:2]
                rgb = cv2.cvtColor(enhanced_frame, cv2.COLOR_BGR2RGB)
                results = self.face_mesh.process(rgb)
                selection = None

                if results.multi_face_landmarks:
                    landmarks = results.multi_face_landmarks[0].landmark
                    gaze_pos, confidence = self._calculate_gaze(landmarks, w, h)

                    self.smoothed_gaze = (SMOOTHING_FACTOR * self.smoothed_gaze +
                                          (1 - SMOOTHING_FACTOR) * gaze_pos)

                    if confidence > MIN_CONFIDENCE:
                        selection = self._determine_selection(self.smoothed_gaze)

                        if not self.in_cooldown:
                            self.gaze_history.append((selection, confidence))
                            if self._check_stability(selection):
                                now = time.time()
                                if (selection != self.last_spoken or
                                        now - self.last_spoken_time > COOLDOWN_SEC):
                                    self._speak(selection)
                                    self.last_spoken = selection
                                    self.last_spoken_time = now

                display = np.zeros_like(frame)
                self._create_ui(display, frame, selection)
                cv2.imshow("Precision Iris Gaze Control", display)

                key = cv2.waitKey(1)
                if key & 0xFF == ord('q'):
                    break
                elif key & 0xFF == ord('d'):  # Toggle debug mode
                    global DEBUG_MODE
                    DEBUG_MODE = not DEBUG_MODE

        finally:
            self.running = False
            self.thread.join()
            self.cap.release()
            cv2.destroyAllWindows()
            self.face_mesh.close()

if __name__ == "__main__":
    EyeGazeApp().run()