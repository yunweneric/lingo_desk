import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class LingoDeskIcon extends StatelessWidget {
  const LingoDeskIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth = 1.8,
  });

  final List<List<dynamic>> icon;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: icon,
      size: size,
      color: color ?? IconTheme.of(context).color,
      strokeWidth: strokeWidth,
    );
  }
}
