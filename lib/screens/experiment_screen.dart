import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../config/session_config.dart';
import '../models/document_content.dart';
import '../utils/seeded_shuffle.dart';
import '../widgets/document_reader_view.dart';
import '../widgets/phone_mockup_frame.dart';
import '../widgets/shelf_image_panel.dart';
import 'session_error_screen.dart';

class ExperimentScreen extends StatefulWidget {
  final Uri uri;

  const ExperimentScreen({super.key, required this.uri});

  @override
  State<ExperimentScreen> createState() => _ExperimentScreenState();
}

class _ExperimentScreenState extends State<ExperimentScreen> {
  late final SessionConfig? _sessionConfig;
  late final String? _configError;
  Future<DocumentContent>? _contentFuture;

  @override
  void initState() {
    super.initState();
    try {
      _sessionConfig = SessionConfig.fromUri(widget.uri);
      _configError = null;
      _contentFuture = _loadDocumentContent();
    } on SessionConfigError catch (e) {
      _sessionConfig = null;
      _configError = e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_configError != null) {
      return SessionErrorScreen(message: _configError);
    }

    final session = _sessionConfig!;

    return Scaffold(
      body: FutureBuilder<DocumentContent>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SessionErrorScreen(
              message: 'Failed to load task content: ${snapshot.error}',
            );
          }

          final orderedProducts = shuffledProducts(
            snapshot.data!.products,
            session.prolificId,
          );

          return Row(
            children: [
              const Expanded(child: ShelfImagePanel()),
              PhoneMockupFrame(
                child: session.isChatCondition
                    ? const _ChatPlaceholder()
                    : DocumentReaderView(
                        sections: [
                          for (final p in orderedProducts)
                            p.bodyMarkdown.trim(),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<DocumentContent> _loadDocumentContent() async {
    final jsonString = await rootBundle.loadString(
      'assets/content/products.json',
    );
    return DocumentContent.fromJsonString(jsonString);
  }
}

/// Temporary stand-in for the chat UI, which is built in a later step once
/// the Cloud Functions backend exists. Lets condition routing and layout be
/// verified end-to-end before chat functionality is wired up.
class _ChatPlaceholder extends StatelessWidget {
  const _ChatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Text(
        'Chat UI placeholder — built in a later step.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black45, fontSize: 14),
      ),
    );
  }
}
