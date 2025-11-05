
import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  final VoidCallback onStartPressed;

  const StartScreen({super.key, required this.onStartPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Angry Flutter',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onStartPressed,
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
