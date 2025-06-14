import cv2
import mediapipe as mp
import numpy as np
import threading
from flask import Flask, jsonify, request
import base64
import io
from PIL import Image

# Flask app
app = Flask(__name__)

# Settings
IRIS_SENSITIVITY = 10.0
SMOOTHING_FACTOR = 0.8
MIN_CONFIDENCE = 0.85

class IrisTracker:
    def __init__(self):
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

            return np.array([norm_x, norm_y]), 1.0
        except Exception as e:
            print(f"Gaze error: {e}")
            return np.array([0.5, 0.5]), 0.0

    def process_frame(self, frame):
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

    def get_current_gaze(self):
        return self.smoothed_gaze.tolist()

# Initialize tracker
tracker = IrisTracker()

@app.route('/upload_frame', methods=['POST'])
def upload_frame():
    data = request.get_json()
    if 'frame' not in data:
        return jsonify({'error': 'No frame data'}), 400

    frame_data = base64.b64decode(data['frame'])
    image = Image.open(io.BytesIO(frame_data)).convert('RGB')
    frame = np.array(image)
    frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)

    tracker.process_frame(frame)
    return jsonify({'status': 'Frame received'})

@app.route('/gaze', methods=['GET'])
def gaze():
    gaze = tracker.get_current_gaze()
    return jsonify({
        'x': gaze[0],
        'y': gaze[1]
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
