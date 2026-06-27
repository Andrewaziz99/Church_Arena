import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TimerWidget extends StatelessWidget {
  final int remaining;
  final int total;

  const TimerWidget({
    super.key,
    required this.remaining,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? remaining / total : 0.0;
    final isLow = remaining <= 10;
    final color = isLow ? AppColors.error : AppColors.primary;

    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: _TimerPainter(fraction: fraction, color: color),
        child: Center(
          child: Text(
            '$remaining',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: color.withOpacity(0.8), blurRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double fraction;
  final Color color;

  _TimerPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * pi * fraction;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}
