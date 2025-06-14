import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeButtonNamesPage extends StatefulWidget {
  const ChangeButtonNamesPage({super.key});

  @override
  State<ChangeButtonNamesPage> createState() => _ChangeButtonNamesPageState();
}

class _ChangeButtonNamesPageState extends State<ChangeButtonNamesPage> {
  final _buttonControllers = List.generate(4, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _loadSavedNames();
  }

  Future<void> _loadSavedNames() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < 4; i++) {
        _buttonControllers[i].text = prefs.getString('button_$i') ??
            ['Food', 'Medicine', 'Toilet', 'Help'][i];
      }
    });
  }

  Future<void> _saveNames() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < 4; i++) {
      await prefs.setString('button_$i', _buttonControllers[i].text);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Button names saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    for (var controller in _buttonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Button Names'),
        backgroundColor: Colors.black, // Dark background for app bar
      ),
      backgroundColor: Colors.black, // Dark background for the whole screen
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: List.generate(4, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                controller: _buttonControllers[index],
                style: const TextStyle(
                    color: Colors.white), // White text color for input
                decoration: InputDecoration(
                  labelText: 'Button ${index + 1}',
                  labelStyle:
                      const TextStyle(color: Colors.white), // White label text
                  filled: true,
                  fillColor: Colors.grey[800], // Dark input field background
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            );
          })
            ..add(
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: _saveNames,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Set button color to green
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white, // Set button text color to white
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
        ),
      ),
    );
  }
}
