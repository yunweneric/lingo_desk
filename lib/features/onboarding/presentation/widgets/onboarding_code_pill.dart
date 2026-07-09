import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_theme.dart';

class OnboardingCodePill extends StatelessWidget {
  const OnboardingCodePill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : LingoDeskColors.border,
        ),
        boxShadow:
            isDark
                ? null
                : const [
                  BoxShadow(
                    color: Color(0x0A030712),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Text(
          text,
          style: LingoDeskTheme.codeStyle.copyWith(
            color: isDark ? Colors.white : LingoDeskColors.ink,
          ),
          softWrap: true,
        ),
      ),
    );
  }
}
