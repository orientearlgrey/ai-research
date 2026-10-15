import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../chat/chat_backend.dart';
import '../chat/stub_chat_backend.dart';
import '../config/session_config.dart';
import '../models/document_content.dart';
import '../utils/markdown_document_builder.dart';
import '../utils/seeded_shuffle.dart';
import '../widgets/chat_view.dart';
import '../widgets/document_reader_view.dart';
import '../widgets/phone_mockup_frame.dart';
import '../widgets/shelf_image_panel.dart';
import 'session_error_screen.dart';

class ExperimentScreen extends StatefulWidget {
  final Uri uri;

  /// Where chat replies come from. Defaults to the stub until the real
  /// backend exists.
  final ChatBackend chatBackend;

  const ExperimentScreen({
    super.key,
    required this.uri,
    this.chatBackend = const StubChatBackend(),
  });

  @override
  State<ExperimentScreen> createState() => _ExperimentScreenState();
}

class _ExperimentScreenState extends State<ExperimentScreen> {
  static const double _maxPhoneWidthShare = 0.55;

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

          // The phone takes at most this share of the width so the shelf
          // image always keeps room, whatever size the iframe is.
          return LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                const Expanded(child: ShelfImagePanel()),
                PhoneMockupFrame(
                  maxWidth: constraints.maxWidth * _maxPhoneWidthShare,
                  child: session.isChatCondition
                      ? ChatView(
                          backend: widget.chatBackend,
                          session: session,
                          documentMarkdown: buildDocumentMarkdown(
                            orderedProducts,
                          ),
                        )
                      : DocumentReaderView(
                          sections: [
                            for (final p in orderedProducts)
                              p.bodyMarkdown.trim(),
                          ],
                        ),
                ),
              ],
            ),
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
