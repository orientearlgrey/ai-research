import 'package:flutter/material.dart';

import 'markdown_content_view.dart';

/// Scrollable rendering of the full shuffled document for the manual
/// condition. Each product is its own markdown section, separated by
/// whitespace rather than a divider line.
class DocumentReaderView extends StatelessWidget {
  static const double sectionSpacing = 80;

  final List<String> sections;

  const DocumentReaderView({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) const SizedBox(height: sectionSpacing),
              MarkdownContentView(data: sections[i]),
            ],
          ],
        ),
      ),
    );
  }
}
