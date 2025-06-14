import cv2
import mediapipe as mp
import numpy as np
import threading
import time
from collections import deque

# Colors and display settings
COLORS = {
    "background": (0, 0, 0),
    "cursor": (0, 0, 255),
    "debug": (0, 255, 255)
}

CURSOR_RADIUS = 12
IRIS_SENSITIVITY = 10.0
SMOOTHING_FACTOR = 0.8
MIN_CONFIDENCE = 0.85
DEBUG_MODE = True

class IrisTracker:
    def __init__(self):
        self.cap = cv2.VideoCapture(0)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        self.cap.set(cv2.CAP_PROP_FPS, 60)

        self.face_mesh = mp.solutions.face_mesh.FaceMesh(
            refine_landmarks=True,
            max_num_faces=1,
            min_detection_confidence=0.9,
            min_tracking_confidence=0.9
        )

        self.running = True
        self.frame_lock = threading.Lock()
        self.latest_frame = None
        self.smoothed_gaze = np.array([0.5, 0.5])  # Normalized

    def _camera_thread(self):
        while self.running:
            ret, frame = self.cap.read()
            if ret:
                with self.frame_lock:
                    self.latest_frame = frame

    def _enhance_frame(self, frame):
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        gray = cv2.equalizeHist(gray)
        return cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)

    def _calculate_gaze(self, landmarks, width, height):
        try:
            LEFT_IRIS = [474, 475, 476, 477]
            RIGHT_IRIS = [469, 470, 471, 472]

            left_iris = np.mean([(landmarks[i].x * width, landmarks[i].y * height) for i in LEFT_IRIS], axis=0)
            right_iris = np.mean([(landmarks[i].x * width, landmarks[i].y * height) for i in RIGHT_IRIS], axis=0)
            gaze_center = (left_iris + right_iris) / 2

            norm_x = 0.5 + (gaze_center[0] / width - 0.5) * IRIS_SENSITIVITY
            norm_y = 0.5 + (gaze_center[1] / height - 0.5) * IRIS_SENSITIVITY
            norm_x = np.clip(norm_x, 0.0, 1.0)
            norm_y = np.clip(norm_y, 0.0, 1.0)

            if DEBUG_MODE:
                debug_frame = np.zeros((height, width, 3), dtype=np.uint8)
                cv2.circle(debug_frame, tuple(np.int32(left_iris)), 5, COLORS["debug"], -1)
                cv2.circle(debug_frame, tuple(np.int32(right_iris)), 5, COLORS["debug"], -1)
                cv2.circle(debug_frame, tuple(np.int32(gaze_center)), 8, (0, 255, 0), -1)
                cv2.imshow("Iris Debug", debug_frame)

            return np.array([norm_x, norm_y]), 1.0

        except Exception as e:
            print(f"Gaze error: {e}")
            return np.array([0.5, 0.5]), 0.0

    def run(self):
        threading.Thread(target=self._camera_thread, daemon=True).start()

        while True:
            with self.frame_lock:
                if self.latest_frame is None:
                    continue
                frame = self.latest_frame.copy()

            frame = cv2.flip(frame, 1)
            enhanced_frame = self._enhance_frame(frame)
            rgb = cv2.cvtColor(enhanced_frame, cv2.COLOR_BGR2RGB)
            h, w = frame.shape[:2]
            results = self.face_mesh.process(rgb)

            if results.multi_face_landmarks:
                landmarks = results.multi_face_landmarks[0].landmark
                gaze_pos, confidence = self._calculate_gaze(landmarks, w, h)
                if confidence > MIN_CONFIDENCE:
                    self.smoothed_gaze = (SMOOTHING_FACTOR * self.smoothed_gaze +
                                          (1 - SMOOTHING_FACTOR) * gaze_pos)

            # Draw smoothed gaze point on preview
            cx = int(self.smoothed_gaze[0] * w)
            cy = int(self.smoothed_gaze[1] * h)
            cv2.circle(frame, (cx, cy), CURSOR_RADIUS, COLORS["cursor"], -1)

            cv2.imshow("Iris Gaze Tracker", frame)
            key = cv2.waitKey(1)

            if key & 0xFF == ord('q'):
                break
            elif key & 0xFF == ord('d'):
                global DEBUG_MODE
                DEBUG_MODE = not DEBUG_MODE

        self.running = False
        self.cap.release()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    tracker = IrisTracker()
    tracker.run()