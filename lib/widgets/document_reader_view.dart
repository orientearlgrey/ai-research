import 'package:flutter/material.dart';

import 'markdown_content_view.dart';

/// Scrollable rendering of the full shuffled document for the manual
/// condition.
class DocumentReaderView extends StatelessWidget {
  final String documentMarkdown;

  const DocumentReaderView({super.key, required this.documentMarkdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: MarkdownContentView(data: documentMarkdown),
      ),
    );
  }
}
