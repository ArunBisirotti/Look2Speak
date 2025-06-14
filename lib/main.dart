import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';
import 'home_page.dart';
import 'pages/auth_page.dart';
import 'pages/change_button_names_page.dart';
import 'pages/start_detection_page.dart';
import 'pages/instructions_page.dart';
import 'pages/settings_page.dart';
import 'pages/profile_page.dart';

late CameraDescription firstCamera;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fwposwmbbdxzlsxilmul.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ3cG9zd21iYmR4emxzeGlsbXVsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQwODg0MzcsImV4cCI6MjA1OTY2NDQzN30.MqmP1JURZKEA9F4NQtRSQmLZD9lIUCRNIrhUTtk_l7Y',
  );

  final cameras = await availableCameras();
  firstCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Look2Speak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFF101020),
      ),
      home: const AuthPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/start-detection': (context) =>
            StartDetectionPage(camera: firstCamera),
        '/change-button-names': (context) => const ChangeButtonNamesPage(),
        '/instructions': (context) => const InstructionsPage(),
        '/settings': (context) => const AboutPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
