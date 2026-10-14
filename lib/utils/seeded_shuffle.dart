import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/product.dart';

/// Derives a deterministic seed from a Prolific ID so the same participant
/// always sees the same shuffled order (reproducible for analysis) without
/// needing to separately store "what order did we show them."
int seedFromProlificId(String prolificId) {
  final digestBytes = sha256.convert(utf8.encode(prolificId)).bytes;
  return (digestBytes[0] << 24) |
      (digestBytes[1] << 16) |
      (digestBytes[2] << 8) |
      digestBytes[3];
}

/// Returns a new list with [products] shuffled via Fisher-Yates, seeded
/// deterministically from [prolificId]. The input list is not mutated.
List<Product> shuffledProducts(List<Product> products, String prolificId) {
  final random = Random(seedFromProlificId(prolificId));
  final shuffled = List<Product>.of(products);
  for (var i = shuffled.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final swap = shuffled[i];
    shuffled[i] = shuffled[j];
    shuffled[j] = swap;
  }
  return shuffled;
}
