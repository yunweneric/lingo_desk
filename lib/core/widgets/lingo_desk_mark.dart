import 'package:flutter/material.dart';

import '../assets/lingo_desk_assets.dart';

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

    if (showWordmark) {
      return Image.asset(
        useReversed
            ? LingoDeskAssets.brandLockupReversed
            : LingoDeskAssets.brandLockup,
        width: size * 5,
        height: size * 1.45,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        filterQuality: FilterQuality.high,
      );
    }

    final mark = Image.asset(
      useReversed
          ? LingoDeskAssets.brandMarkReversed
          : LingoDeskAssets.brandMark,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    return mark;
  }
}
