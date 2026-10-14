import 'package:flutter/material.dart';

import '../screens/experiment_screen.dart';

class ExperimentApp extends StatelessWidget {
  final Uri uri;

  const ExperimentApp({super.key, required this.uri});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Research Task',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3B5BDB),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      ),
      home: ExperimentScreen(uri: uri),
    );
  }
}
