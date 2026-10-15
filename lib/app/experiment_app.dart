import 'package:flutter/material.dart';

import '../chat/chat_backend.dart';
import '../chat/stub_chat_backend.dart';
import '../screens/experiment_screen.dart';

class ExperimentApp extends StatelessWidget {
  final Uri uri;
  final ChatBackend chatBackend;

  const ExperimentApp({
    super.key,
    required this.uri,
    this.chatBackend = const StubChatBackend(),
  });

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
      home: ExperimentScreen(uri: uri, chatBackend: chatBackend),
    );
  }
}
