import 'package:ai_research/widgets/markdown_content_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(String data) {
  return MaterialApp(
    home: Scaffold(body: MarkdownContentView(data: data)),
  );
}

/// Highlight/entity text is merged into the paragraph's spans, so look it up
/// as a [TextSpan] rather than a standalone [Text] widget.
TextSpan _spanWithText(WidgetTester tester, String text) {
  TextSpan? found;
  void visit(InlineSpan span) {
    if (span is! TextSpan) return;
    if (span.text == text) found = span;
    span.children?.forEach(visit);
  }

  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    visit(rich.text);
  }
  expect(found, isNotNull, reason: 'no span with text "$text"');
  return found!;
}

Finder _richText(String text) => find.textContaining(text, findRichText: true);

void main() {
  group('MarkdownContentView custom tags', () {
    testWidgets('renders <mark> content without leaking the raw tag', (
      tester,
    ) async {
      const markdown = 'This is <mark>highlighted text</mark> right here.';

      await tester.pumpWidget(_wrap(markdown));

      expect(_richText('highlighted text'), findsOneWidget);
      expect(_richText('<mark>'), findsNothing);
      expect(_richText('</mark>'), findsNothing);
    });

    testWidgets(
      'renders <span class="dotted"> content without leaking the raw tag',
      (tester) async {
        const markdown =
            '**<span class="dotted">Product Name</span> (9g)** is great.';

        await tester.pumpWidget(_wrap(markdown));

        expect(_richText('Product Name'), findsOneWidget);
        expect(_richText('<span'), findsNothing);
        expect(_richText('</span>'), findsNothing);
      },
    );

    testWidgets('applies a highlight background to <mark> text', (
      tester,
    ) async {
      const markdown = 'Normal <mark>Marked</mark> normal.';

      await tester.pumpWidget(_wrap(markdown));

      expect(_spanWithText(tester, 'Marked').style?.backgroundColor, isNotNull);
    });

    testWidgets('applies a dotted underline to dotted-span text', (
      tester,
    ) async {
      const markdown = '<span class="dotted">Entity</span> text.';

      await tester.pumpWidget(_wrap(markdown));

      expect(
        _spanWithText(tester, 'Entity').style?.decorationStyle,
        TextDecorationStyle.dotted,
      );
    });

    testWidgets('renders real product content end-to-end', (tester) async {
      const markdown =
          'The **<span class="dotted">KAHI Wrinkle Bounce Multi-Balm</span> '
          '(9g)** is <mark>a popular Korean skincare stick designed for '
          'targeted hydration, anti-aging care, and a dewy "glass skin" '
          'glow</mark>.\n\n## Key Benefits & Uses\n\n- **Multi-Use '
          'Formula:** Can be applied to the eyes, cheeks, smile lines, '
          'chin, neck, lips, and dry body patches.';

      await tester.pumpWidget(_wrap(markdown));

      expect(_richText('KAHI Wrinkle Bounce Multi-Balm'), findsOneWidget);
      expect(_richText('Key Benefits & Uses'), findsOneWidget);
      expect(_richText('<'), findsNothing);
    });
  });
}
