import 'package:flutter/material.dart';

import '../theme/lingo_desk_theme.dart';

/// The LingoDesk brand mark (2026 teal rebrand): a teal rounded square
/// holding two overlapping locale tiles, the front tile carrying two
/// dots — a quiet umlaut/translation nod.
///
/// Drawn natively from the brand SVG geometry (viewBox 64) so it stays
/// crisp at every size. The lockup is not an image: the wordmark is set
/// live in Space Grotesk 700 beside the mark, per the design system.
class LingoDeskMark extends StatelessWidget {
  const LingoDeskMark({
    super.key,
    this.size = 48,
    this.reversed = false,
    this.showWordmark = false,
  });

  final double size;
  final bool reversed;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final useReversed =
        reversed || Theme.of(context).brightness == Brightness.dark;

    final mark = CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(reversed: useReversed),
    );

    if (!showWordmark) {
      return mark;
    }

    final wordmarkSize = size * 0.56;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.28),
        Text(
          'LingoDesk',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: wordmarkSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.01 * wordmarkSize,
            height: 1,
            color: useReversed ? Colors.white : LingoDeskColors.ink,
          ),
        ),
      ],
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.reversed});

  final bool reversed;

  @override
  void paint(Canvas canvas, Size size) {
    // Brand SVG geometry on a 64x64 viewBox.
    final unit = size.width / 64;
    final square = reversed ? Colors.white : LingoDeskColors.brandTeal;
    final backTile =
        reversed
            ? LingoDeskColors.brandTeal.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.45);
    final frontTile = reversed ? LingoDeskColors.brandTeal : Colors.white;
    final dots = reversed ? Colors.white : LingoDeskColors.brandTeal;

    RRect tile(double x, double y, double w, double h, double r) {
      return RRect.fromRectAndRadius(
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
        Radius.circular(r * unit),
      );
    }

    canvas
      ..drawRRect(tile(0, 0, 64, 64, 16), Paint()..color = square)
      ..drawRRect(tile(16, 20, 24, 24, 7), Paint()..color = backTile)
      ..drawRRect(tile(26, 22, 24, 24, 7), Paint()..color = frontTile)
      ..drawCircle(
        Offset(34 * unit, 34 * unit),
        3.4 * unit,
        Paint()..color = dots,
      )
      ..drawCircle(
        Offset(44 * unit, 34 * unit),
        3.4 * unit,
        Paint()..color = dots,
      );
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.reversed != reversed;
}
