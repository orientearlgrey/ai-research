import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

// Private-use sentinel characters used to mark highlight/dotted-entity spans
// ahead of markdown parsing. See [MarkdownContentView._preprocess].
const String _markOpen = '\uE000';
const String _markClose = '\uE001';
const String _dottedOpen = '\uE002';
const String _dottedClose = '\uE003';

/// Shared markdown rendering used by BOTH the document reader and chat
/// bubbles, so visual style never differs by condition.
///
/// Study content is authored with two non-standard inline tags (matching
/// what the source content already uses, copied from Google AI Mode-style
/// output): `<mark>...</mark>` renders as a highlighted "key claim" span,
/// and `<span class="dotted">...</span>` renders as a dotted-underline
/// "recognized entity" span (product names). Citation chips and images from
/// the original AI Mode styling are intentionally omitted.
class MarkdownContentView extends StatelessWidget {
  final String data;

  const MarkdownContentView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _preprocess(data),
      selectable: false,
      extensionSet: md.ExtensionSet.gitHubWeb,
      inlineSyntaxes: [_MarkTagSyntax(), _DottedSpanSyntax()],
      builders: {
        'mark': _MarkElementBuilder(),
        'dotted': _DottedEntityElementBuilder(),
      },
      styleSheet: _styleSheet(context),
    );
  }

  /// CommonMark treats `<...>` as raw inline HTML and swallows it before any
  /// custom [md.InlineSyntax] gets a chance to match, regardless of syntax
  /// order or registration. To render `<mark>`/`<span class="dotted">`
  /// ourselves, swap them for private-use sentinel characters first, which
  /// nothing else in the markdown pipeline recognizes as meaningful.
  static String _preprocess(String raw) {
    return raw
        .replaceAllMapped(
          RegExp(r'<mark>(.*?)</mark>'),
          (m) => '$_markOpen${m[1]}$_markClose',
        )
        .replaceAllMapped(
          RegExp(r'<span class="dotted">(.*?)</span>'),
          (m) => '$_dottedOpen${m[1]}$_dottedClose',
        );
  }

  MarkdownStyleSheet _styleSheet(BuildContext context) {
    final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return base.copyWith(
      p: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF1A1A1A)),
      h2: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
      h3: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
      listBullet: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
      strong: const TextStyle(fontWeight: FontWeight.w700),
      code: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13.5,
        backgroundColor: Color(0xFFEFEFEF),
      ),
    );
  }
}

class _MarkTagSyntax extends md.InlineSyntax {
  _MarkTagSyntax() : super('$_markOpen(.*?)$_markClose');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mark', match[1]!));
    return true;
  }
}

class _DottedSpanSyntax extends md.InlineSyntax {
  _DottedSpanSyntax() : super('$_dottedOpen(.*?)$_dottedClose');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('dotted', match[1]!));
    return true;
  }
}

/// Inline elements are only routed to
/// [MarkdownElementBuilder.visitElementAfterWithContext] (`visitText` is
/// dispatched for block tags only). Returning a [Text.rich] lets the
/// markdown builder merge it into the surrounding paragraph's spans, so long
/// highlighted claims still wrap with the rest of the text.
class _MarkElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Text.rich(
      TextSpan(
        text: element.textContent,
        style: (preferredStyle ?? parentStyle)?.copyWith(
          backgroundColor: const Color(0xFFD7E3FF),
        ),
      ),
    );
  }
}

class _DottedEntityElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Text.rich(
      TextSpan(
        text: element.textContent,
        style: (preferredStyle ?? parentStyle)?.copyWith(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: const Color(0xFF6B6B6B),
          decorationThickness: 1.5,
        ),
      ),
    );
  }
}
