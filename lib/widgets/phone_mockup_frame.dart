import 'dart:math';

import 'package:flutter/material.dart';

/// Decorative phone-shaped frame; task content renders inside it so the
/// participant appears to be using a phone, regardless of condition.
class PhoneMockupFrame extends StatelessWidget {
  /// Width as a multiple of a standard 9:19.5 phone at the same height.
  static const double _widthScale = 1.03;
  static const double _margin = 24;

  /// Zoom applied to the content inside the screen, like browser zoom: below
  /// 1 shows smaller text and more content. Applies to every condition, so
  /// the document reader and the chat look alike.
  static const double contentZoom = 0.9;

  final Widget child;

  /// Widest the frame (including its margin) may be. The frame shrinks,
  /// keeping its proportions, rather than exceed this.
  final double maxWidth;

  const PhoneMockupFrame({
    super.key,
    required this.child,
    this.maxWidth = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    // Height comes from the available space and width follows from it, unless
    // that would exceed [maxWidth] (a tall, narrow viewport); then the width
    // wins and the height shrinks to match.
    return LayoutBuilder(
      builder: (context, constraints) {
        const ratio = (9 / 19.5) * _widthScale;
        var frameHeight = max(0.0, constraints.maxHeight - 2 * _margin);
        var frameWidth = frameHeight * ratio;
        final maxFrameWidth = max(0.0, maxWidth - 2 * _margin);
        if (frameWidth > maxFrameWidth) {
          frameWidth = maxFrameWidth;
          frameHeight = frameWidth / ratio;
        }
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
                child: _ZoomedContent(zoom: contentZoom, child: child),
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

/// Lays [child] out at 1/[zoom] of the available size and paints it scaled by
/// [zoom], so it fills the same space but everything (text, padding, bullets)
/// renders smaller. Hit testing follows the transform, so scrolling works.
class _ZoomedContent extends StatelessWidget {
  final double zoom;
  final Widget child;

  const _ZoomedContent({required this.zoom, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth / zoom;
        final height = constraints.maxHeight / zoom;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: Transform.scale(
              scale: zoom,
              alignment: Alignment.topLeft,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
