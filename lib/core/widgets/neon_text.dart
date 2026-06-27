import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NeonText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  const NeonText({
    super.key,
    required this.text,
    this.fontSize = 24,
    this.color = AppColors.primary,
    this.fontWeight = FontWeight.bold,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        shadows: [
          Shadow(color: color.withOpacity(0.8), blurRadius: 8),
          Shadow(color: color.withOpacity(0.4), blurRadius: 20),
          Shadow(color: color.withOpacity(0.2), blurRadius: 40),
        ],
      ),
    );
  }
}
