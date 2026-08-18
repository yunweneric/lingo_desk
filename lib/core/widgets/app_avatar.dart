import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';

/// The square badge that stands for an app wherever it is listed.
///
/// Shows the app's own icon when it has one, and otherwise its initials
/// on a colour picked from [_palette] by name — so an app without an
/// icon still looks like itself and stays distinguishable in a list.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    required this.initials,
    this.iconImage,
    this.size = 36,
  });

  /// Used for the tooltip-free semantics label and to pick the fallback
  /// colour, so the same app keeps the same colour everywhere.
  final String name;

  /// Letters drawn when there is no [iconImage]; `App.initials`.
  final String initials;

  /// Base64-encoded PNG, or null to fall back to [initials].
  final String? iconImage;

  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final radius = size < 30 ? 8.0 : LingoDeskTheme.radius;
    final bytes = _decode(iconImage);

    if (bytes != null) {
      return Semantics(
        label: '$name icon',
        child: Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: tokens.border),
          ),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            // A stored icon that will not decode is still an app: fall
            // back rather than dropping an error box into the list.
            errorBuilder: (context, error, stack) => _Initials(
              name: name,
              initials: initials,
              size: size,
              radius: radius,
            ),
          ),
        ),
      );
    }

    return _Initials(
      name: name,
      initials: initials,
      size: size,
      radius: radius,
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({
    required this.name,
    required this.initials,
    required this.size,
    required this.radius,
  });

  final String name;
  final String initials;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final color = _colorFor(name);

    return Semantics(
      label: name,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: tokens.isDark ? 0.26 : 0.14),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: color.withValues(alpha: tokens.isDark ? 0.5 : 0.32),
          ),
        ),
        child: FittedBox(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.16),
            child: Text(
              initials,
              maxLines: 1,
              style: TextStyle(
                // Sized off the badge so one widget covers a 24px row
                // marker and a 64px settings tile.
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: tokens.isDark ? _lighten(color) : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fallback colours. Brand teal leads; the rest are chosen to sit beside
/// it without competing, and to stay legible as text on their own tint.
const List<Color> _palette = [
  LingoDeskColors.brandTeal,
  Color(0xFF4F46E5), // indigo
  Color(0xFFB45309), // amber
  Color(0xFFBE185D), // rose
  Color(0xFF15803D), // green
  Color(0xFF7C3AED), // violet
  Color(0xFF0369A1), // sky
  Color(0xFFC2410C), // orange
];

/// Same name, same colour, every session — a plain character sum rather
/// than [Object.hashCode], which is not stable across runs.
Color _colorFor(String name) {
  final key = name.trim().toLowerCase();
  if (key.isEmpty) {
    return _palette.first;
  }
  var sum = 0;
  for (final unit in key.codeUnits) {
    sum = (sum + unit * 31) % 100003;
  }
  return _palette[sum % _palette.length];
}

/// Lifts a palette colour into the range that reads on a dark surface.
Color _lighten(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + 0.28).clamp(0.0, 1.0)).toColor();
}

/// Decoded icons, keyed by their base64 string.
///
/// Rows rebuild on hover and on every table refresh; without this each
/// rebuild would re-decode the same PNG. Bounded because an icon is at
/// most a couple of hundred KB and a workspace holds a handful of apps.
final Map<String, Uint8List?> _decodeCache = {};

Uint8List? _decode(String? encoded) {
  if (encoded == null || encoded.isEmpty) {
    return null;
  }
  return _decodeCache.putIfAbsent(encoded, () {
    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  });
}
