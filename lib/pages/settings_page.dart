import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final List<Map<String, String>> developers = [
    {
      'image': 'assets/images/akshata.jpeg',
      'name': 'Akshata Khanapure',
      'details': 'CSE\n Manages Database Operations',
    },
    {
      'image': 'assets/images/arun.jpg',
      'name': 'Arun Bisirotti',
      'details': 'CSE\n Gaze Tracking Developer ',
    },
    {
      'image': 'assets/images/ramesh.jpeg',
      'name': 'Ramesh Bagi',
      'details': 'CSE\n UI/UX Designer ',
    },
    {
      'image': 'assets/images/sanjay.jpeg',
      'name': 'Sanjay',
      'details': 'CSE\n UI/UX Developer ',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
        backgroundColor: Colors.black, // AppBar background color
      ),
      backgroundColor: Colors.black, // Background color for the entire screen
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Look2Speak is an assistive communication application designed to help individuals with disabilities communicate using eye movements.',
              style: TextStyle(
                  fontSize: 16, color: Colors.white), // White text color
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Developers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text color for header
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _animation,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: developers.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  return DeveloperCard(
                    imageAsset: developers[index]['image']!,
                    name: developers[index]['name']!,
                    details: developers[index]['details']!,
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.white), // White divider line
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0 | © 2025 Look2Speak',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class DeveloperCard extends StatefulWidget {
  final String imageAsset;
  final String name;
  final String details;

  const DeveloperCard({
    super.key,
    required this.imageAsset,
    required this.name,
    required this.details,
  });

  @override
  State<DeveloperCard> createState() => _DeveloperCardState();
}

class _DeveloperCardState extends State<DeveloperCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _tapController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _tapController.reverse();
  }

  void _onTapCancel() {
    _tapController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.grey[850], // Dark card background for contrast
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(widget.imageAsset),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text color
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.details,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey, // Light grey for details
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
