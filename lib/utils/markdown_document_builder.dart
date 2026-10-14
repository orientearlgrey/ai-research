import '../models/product.dart';

/// Builds the single markdown document string from an already-ordered list
/// of products. Used as the single source of truth for both the on-screen
/// document reader and the context sent to the chat backend.
String buildDocumentMarkdown(List<Product> orderedProducts) {
  return orderedProducts.map((p) => p.bodyMarkdown.trim()).join('\n\n---\n\n');
}
