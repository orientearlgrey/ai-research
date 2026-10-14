import 'package:ai_research/models/product.dart';
import 'package:ai_research/utils/markdown_document_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildDocumentMarkdown', () {
    test('joins product bodies in the given order, separated by a divider', () {
      final products = [
        const Product(
          id: 'a',
          name: 'A',
          isFocal: true,
          bodyMarkdown: '**A**\n\nBody A',
        ),
        const Product(
          id: 'b',
          name: 'B',
          isFocal: false,
          bodyMarkdown: '**B**\n\nBody B',
        ),
      ];

      final result = buildDocumentMarkdown(products);

      expect(result, '**A**\n\nBody A\n\n---\n\n**B**\n\nBody B');
    });

    test('returns an empty string for an empty list', () {
      expect(buildDocumentMarkdown([]), '');
    });
  });
}
