import 'package:ai_research/models/document_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentContent.fromJsonString', () {
    test('parses a valid document', () {
      const json = '''
      {
        "products": [
          {"id": "a", "name": "Focal", "isFocal": true, "bodyMarkdown": "**Focal**"},
          {"id": "b", "name": "Other", "isFocal": false, "bodyMarkdown": "**Other**"}
        ]
      }
      ''';

      final content = DocumentContent.fromJsonString(json);

      expect(content.products, hasLength(2));
      expect(content.focalProduct.id, 'a');
    });

    test('throws when no product is focal', () {
      const json = '''
      {
        "products": [
          {"id": "a", "name": "A", "isFocal": false, "bodyMarkdown": "**A**"}
        ]
      }
      ''';

      expect(
        () => DocumentContent.fromJsonString(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when more than one product is focal', () {
      const json = '''
      {
        "products": [
          {"id": "a", "name": "A", "isFocal": true, "bodyMarkdown": "**A**"},
          {"id": "b", "name": "B", "isFocal": true, "bodyMarkdown": "**B**"}
        ]
      }
      ''';

      expect(
        () => DocumentContent.fromJsonString(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when ids are not unique', () {
      const json = '''
      {
        "products": [
          {"id": "a", "name": "A", "isFocal": true, "bodyMarkdown": "**A**"},
          {"id": "a", "name": "B", "isFocal": false, "bodyMarkdown": "**B**"}
        ]
      }
      ''';

      expect(
        () => DocumentContent.fromJsonString(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
