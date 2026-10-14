import 'package:flutter/material.dart';

/// Static, non-interactive shelf/product image panel. Renders a placeholder
/// until the real shelf image asset is supplied.
class ShelfImagePanel extends StatelessWidget {
  const ShelfImagePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEDEDED),
      alignment: Alignment.center,
      child: const Text(
        'Shelf / product image placeholder',
        style: TextStyle(color: Colors.black45, fontSize: 16),
      ),
    );
  }
}
