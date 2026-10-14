import 'package:flutter/material.dart';

/// Static, non-interactive shelf/product image panel. The image is scaled to
/// fit the panel without cropping.
class ShelfImagePanel extends StatelessWidget {
  static const String imageAsset = 'assets/images/shelf_image.png';

  const ShelfImagePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Image.asset(
        imageAsset,
        fit: BoxFit.contain,
        semanticLabel: 'Product shelf image',
      ),
    );
  }
}
