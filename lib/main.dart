// main.dart
import 'package:flutter/material.dart';
import 'package:live_context/live_context_app.dart';

void main() {
  runApp(const MyApp());
}

// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Context Tester',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LiveContextApp(),
    );
  }
}
