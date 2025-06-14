import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class StartDetectionPage extends StatefulWidget {
  final CameraDescription camera;
  const StartDetectionPage({super.key, required this.camera});

  @override
  _StartDetectionPageState createState() => _StartDetectionPageState();
}

class _StartDetectionPageState extends State<StartDetectionPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  Timer? frameTimer;
  Timer? gazeTimer;
  FlutterTts flutterTts = FlutterTts();

  double gazeX = 0.5;
  double gazeY = 0.5;
  double smoothedGazeX = 0.5;
  double smoothedGazeY = 0.5;

  int? selectedButtonIndex;
  bool isSpeaking = false;
  DateTime? lastSelectionTime;

  List<String> buttonLabels = ["Food", "Medicine", "Toilet", "Help"];
  final String serverIP = '192.168.255.239';

  @override
  void initState() {
    super.initState();
    _loadButtonNames();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.low,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize().then((_) {
      setState(() {});
      frameTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => sendFrameToServer(),
      );
      gazeTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => fetchGaze(),
      );
    }).catchError((e) {
      print('Camera initialization error: $e');
    });

    flutterTts.setSpeechRate(0.5);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);
  }

  Future<void> _loadButtonNames() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < 4; i++) {
        buttonLabels[i] = prefs.getString('button_$i') ?? buttonLabels[i];
      }
    });
  }

  Future<void> sendFrameToServer() async {
    if (!_controller.value.isInitialized) return;

    try {
      final frame = await _controller.takePicture();
      final bytes = await frame.readAsBytes();
      final base64Image = base64Encode(bytes);

      await http.post(
        Uri.parse('http://$serverIP:5000/upload_frame'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'frame': base64Image}),
      );
    } catch (e) {
      print('Error sending frame: $e');
    }
  }

  Future<void> fetchGaze() async {
    try {
      final response = await http.get(Uri.parse('http://$serverIP:5000/gaze'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          gazeX = data['x'];
          gazeY = data['y'];
          smoothedGazeX = smoothedGazeX * 0.2 + gazeX * 0.8;
          smoothedGazeY = smoothedGazeY * 0.2 + gazeY * 0.8;
        });
        checkGazeOnButton();
      } else {
        print('Failed to fetch gaze');
      }
    } catch (e) {
      print('Error fetching gaze: $e');
    }
  }

  void checkGazeOnButton() {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;
    double posX = smoothedGazeX * size.width;
    double posY = smoothedGazeY * size.height;

    int index;
    if (posY < size.height / 2) {
      index = posX < size.width / 2 ? 0 : 1;
    } else {
      index = posX < size.width / 2 ? 2 : 3;
    }

    if (selectedButtonIndex != index) {
      setState(() {
        selectedButtonIndex = index;
        lastSelectionTime = DateTime.now();
      });
      speakButton(buttonLabels[index]);
    } else if (lastSelectionTime != null &&
        DateTime.now().difference(lastSelectionTime!).inMilliseconds > 1500) {
      speakButton(buttonLabels[index]);
      lastSelectionTime = DateTime.now();
    }
  }

  Future<void> speakButton(String text) async {
    if (isSpeaking) {
      await flutterTts.stop();
    }
    isSpeaking = true;
    await flutterTts.speak(text);
    isSpeaking = false;
  }

  @override
  void dispose() {
    frameTimer?.cancel();
    gazeTimer?.cancel();
    _controller.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Look2Speak'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Row(children: [_buildButton(0), _buildButton(1)]),
                    ),
                    Expanded(
                      child: Row(children: [_buildButton(2), _buildButton(3)]),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Opacity(
                        opacity: 0.7,
                        child: CameraPreview(_controller),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: smoothedGazeX * MediaQuery.of(context).size.width - 30,
                  top: smoothedGazeY * MediaQuery.of(context).size.height - 30,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error initializing camera'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildButton(int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => speakButton(buttonLabels[index]),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color:
                selectedButtonIndex == index ? Colors.green : Colors.blueGrey,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: Text(
              buttonLabels[index],
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
