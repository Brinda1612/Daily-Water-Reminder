import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../app.dart';

class WavePainter extends CustomPainter {
  final double progress;
  final double waveOffset;

  WavePainter({required this.progress, required this.waveOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // Clip to circle with slight inset to avoid border cutting
    final clipPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2 - 2,
      ));
    canvas.clipPath(clipPath);

    final paint = Paint()
      ..color = WaterReminderApp.primaryWater.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path();
    final height = size.height;
    final width = size.width;

    // Calculate Y level based on progress (inverted because 0 is top)
    final yLevel = height * (1 - progress.clamp(0.0, 1.0));

    path.moveTo(0, yLevel);

    for (double i = 0; i <= width; i++) {
      // Sine wave formula: y = A * sin(k * x + offset)
      final y = yLevel + math.sin((i / width * 2 * math.pi) + waveOffset) * 10;
      path.lineTo(i, y);
    }

    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw a second, slightly different wave for depth
    final paint2 = Paint()
      ..color = WaterReminderApp.primaryWaterDark.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, yLevel);
    for (double i = 0; i <= width; i++) {
      final y = yLevel + math.sin((i / width * 2 * math.pi) + waveOffset + math.pi) * 8;
      path2.lineTo(i, y);
    }
    path2.lineTo(width, height);
    path2.lineTo(0, height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveOffset != waveOffset;
  }
}
