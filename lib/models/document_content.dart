import 'dart:convert';

import 'product.dart';

class DocumentContent {
  final List<Product> products;

  const DocumentContent({required this.products});

  factory DocumentContent.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final rawProducts = decoded['products'] as List<dynamic>;
    final products = rawProducts
        .map((p) => Product.fromJson(p as Map<String, dynamic>))
        .toList();

    final focalCount = products.where((p) => p.isFocal).length;
    if (focalCount != 1) {
      throw FormatException(
        'Expected exactly one product with isFocal=true, found $focalCount',
      );
    }

    final ids = products.map((p) => p.id).toSet();
    if (ids.length != products.length) {
      throw const FormatException('Product ids must be unique');
    }

    return DocumentContent(products: products);
  }

  Product get focalProduct => products.firstWhere((p) => p.isFocal);
}
