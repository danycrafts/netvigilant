import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleApp());
}

class SimpleApp extends StatelessWidget {
  const SimpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Test',
      home: Scaffold(
        appBar: AppBar(title: const Text('Simple Test')),
        body: const Center(
          child: Text('App is working!'),
        ),
      ),
    );
  }
}