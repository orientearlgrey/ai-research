import 'package:flutter/material.dart';

/// Decorative phone-shaped frame; task content renders inside it so the
/// participant appears to be using a phone, regardless of condition.
class PhoneMockupFrame extends StatelessWidget {
  /// Width as a multiple of a standard 9:19.5 phone at the same height.
  static const double _widthScale = 1.03;
  static const double _margin = 24;

  final Widget child;

  const PhoneMockupFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Height comes from the available space; width follows from it, so the
    // frame sizes itself instead of being squeezed by a fixed layout split.
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameHeight = constraints.maxHeight - 2 * _margin;
        final frameWidth = frameHeight * (9 / 19.5) * _widthScale;
        return SizedBox(
          width: frameWidth + 2 * _margin,
          child: Center(
            child: SizedBox(
              width: frameWidth,
              height: frameHeight,
              child: _buildFrame(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrame() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: child,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 90,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
