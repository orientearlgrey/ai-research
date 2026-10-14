import 'package:ai_research/models/product.dart';
import 'package:ai_research/utils/seeded_shuffle.dart';
import 'package:flutter_test/flutter_test.dart';

List<Product> _sampleProducts(int count) {
  return List.generate(
    count,
    (i) => Product(
      id: 'prod_$i',
      name: 'Product $i',
      isFocal: i == 0,
      bodyMarkdown: '**Product $i**',
    ),
  );
}

void main() {
  group('shuffledProducts', () {
    test('is deterministic for the same Prolific ID', () {
      final products = _sampleProducts(10);

      final first = shuffledProducts(products, 'participant-123');
      final second = shuffledProducts(products, 'participant-123');

      expect(first.map((p) => p.id), second.map((p) => p.id));
    });

    test('does not mutate the input list', () {
      final products = _sampleProducts(10);
      final originalOrder = products.map((p) => p.id).toList();

      shuffledProducts(products, 'participant-123');

      expect(products.map((p) => p.id), originalOrder);
    });

    test('preserves the same set of products', () {
      final products = _sampleProducts(10);

      final shuffled = shuffledProducts(products, 'participant-123');

      expect(
        shuffled.map((p) => p.id).toSet(),
        products.map((p) => p.id).toSet(),
      );
    });

    test('different Prolific IDs tend to produce different orders', () {
      final products = _sampleProducts(10);

      final a = shuffledProducts(products, 'participant-abc');
      final b = shuffledProducts(products, 'participant-xyz');

      expect(a.map((p) => p.id), isNot(b.map((p) => p.id)));
    });
  });

  group('seedFromProlificId', () {
    test('is deterministic', () {
      expect(
        seedFromProlificId('participant-123'),
        seedFromProlificId('participant-123'),
      );
    });

    test('is non-negative', () {
      expect(seedFromProlificId('participant-123') >= 0, isTrue);
    });
  });
}
