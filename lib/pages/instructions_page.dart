import 'package:flutter/material.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructions'),
        backgroundColor: const Color(0xFF101020),
      ),
      backgroundColor: const Color(0xFF101020),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildInstructionCard(
              icon: Icons.account_circle,
              title: 'Account Setup',
              content: '1. Create an account using your email\n'
                  '2. Verify your email address\n',
            ),
            const SizedBox(height: 20),
            _buildInstructionCard(
              icon: Icons.camera_alt,
              title: 'Gaze Detection Setup',
              content: '1. Position your device at eye level\n'
                  '2. Ensure good lighting conditions\n'
                  '3. Keep your face centered in the frame\n',
            ),
            const SizedBox(height: 20),
            _buildInstructionCard(
              icon: Icons.touch_app,
              title: 'Using the Interface',
              content: '1. Look at buttons to select them\n'
                  '2. Hold gaze for 1 second to activate\n'
                  '3. System will speak your selection\n'
                  '4. Customize buttons in Settings',
            ),
            const SizedBox(height: 20),
            _buildInstructionCard(
              icon: Icons.settings,
              title: 'Customization',
              content: '1. Change button labels in Settings\n',
            ),
            const SizedBox(height: 20),
            _buildInstructionCard(
              icon: Icons.help,
              title: 'Troubleshooting',
              content: '1. Ensure camera permissions are granted\n'
                  '2. Restart app if detection fails\n',
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/start-detection');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D8BFF),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text(
                  'Start Using Look2Speak',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      color: const Color(0xFF1A1A3C),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF3D8BFF)),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
