// import 'package:flutter/material.dart';

// class TermsConditionsPage extends StatelessWidget {
//   const TermsConditionsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Terms & Conditions'),
//         backgroundColor: Colors.deepPurple,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: const [
//             Text(
//               'Look2Speak – Terms & Conditions',
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 16),
//             Text(
//               '1. Introduction\n'
//               'Look2Speak is an eye-tracking communication system designed to help individuals with physical disabilities communicate using eye movements. By signing up or using this application, you agree to the following terms and conditions.\n',
//             ),
//             SizedBox(height: 12),
//             Text(
//               '2. User Data & Privacy\n'
//               '- We store your email and name securely using Supabase.\n'
//               '- We do not sell or share your personal data with third parties.\n'
//               '- Your data is encrypted and protected.\n',
//             ),
//             SizedBox(height: 12),
//             Text(
//               '3. Medical Disclaimer\n'
//               '- Look2Speak is an assistive tool and not a replacement for professional medical advice.\n'
//               '- The system is intended to support communication, not diagnose or treat conditions.\n',
//             ),
//             SizedBox(height: 12),
//             Text(
//               '4. Accuracy and Limitations\n'
//               '- The system uses AI-powered iris tracking and may not be 100% accurate in all environments.\n'
//               '- Environmental conditions like lighting or camera quality may affect performance.\n',
//             ),
//             SizedBox(height: 12),
//             Text(
//               '5. Account Security\n'
//               '- You are responsible for maintaining the confidentiality of your login credentials.\n'
//               '- We are not responsible for unauthorized access caused by user negligence.\n',
//             ),
//             SizedBox(height: 12),
//             Text(
//               '6. Changes to Terms\n'
//               '- We may update these terms and conditions at any time.\n'
//               '- You will be notified of any significant changes.\n',
//             ),
//             SizedBox(height: 12),
//             Text(
//               '7. Contact Us\n'
//               'If you have any questions about these Terms, contact us at support@look2speak.app.\n',
//             ),
//             SizedBox(height: 24),
//             Text(
//               'By checking the box during signup, you confirm that you have read and agreed to these terms.',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'Terms and conditions content goes here...',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
