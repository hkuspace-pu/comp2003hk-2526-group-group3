// lib/aquarium/aquarium_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'bubble.dart';
import 'fish.dart';

class AquariumPainter extends CustomPainter {
  final List<Fish> fishes;
  final List<Bubble> bubbles;
  final double time;

  AquariumPainter({
    required this.fishes,
    required this.bubbles,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawSurfaceHighlight(canvas, size, time); // subtle top wave
    _drawGlassRim(canvas, size);
    _drawSandTray(canvas, size);
    _drawSeaweed(canvas, size, time);
    for (final b in bubbles) b.draw(canvas);
    for (final f in fishes) f.draw(canvas, time);
    _drawCausticsOverlay(canvas, size, time);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0FB2F2), Color(0xFF0D92D2), Color(0xFF0A78B5)],
        stops: [0.0, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawSurfaceHighlight(Canvas canvas, Size size, double time) {
    final baseY = 20.0;
    const amp = 4.0;
    final k = 2 * pi / (size.width * 0.8);
    const speed = 0.7;

    final path = Path();
    for (double x = 0; x <= size.width; x += 6) {
      final y = baseY + sin(x * k + time * speed) * amp;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withOpacity(0.20);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = Colors.white.withOpacity(0.06);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);
  }

  void _drawGlassRim(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
      const Radius.circular(18),
    );
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.25);
    canvas.drawRRect(r, rimPaint);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = Colors.white.withOpacity(0.05);
    canvas.drawRRect(r.deflate(3), glowPaint);
  }

  void _drawSandTray(Canvas canvas, Size size) {
    final trayHeight = 16.0;
    final trayWidth = size.width - 32;
    final trayRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(16, size.height - 60, trayWidth, trayHeight),
      const Radius.circular(12),
    );

    final sandPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFD9BE8F).withOpacity(0.65),
          const Color(0xFFC9A873).withOpacity(0.65),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(trayRect.outerRect);
    canvas.drawRRect(trayRect, sandPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(trayRect.inflate(0.5), highlightPaint);
  }

  void _drawSeaweed(Canvas canvas, Size size, double time) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final baseY = size.height - 62;
    for (int i = 0; i < 4; i++) {
      final x = 22.0 + i * 12.0; // left cluster
      final sway = sin(time * 1.1 + i) * 8.0;
      final path = Path()..moveTo(x, baseY);
      for (int j = 1; j <= 8; j++) {
        final t = j / 8.0;
        final y = baseY - t * 64;
        final dx = sin(time * 1.4 + t * 5 + i) * (6.0 * (1.0 + t)) + sway * t;
        path.lineTo(x + dx, y);
      }
      paint.color = Colors.green.shade700.withOpacity(0.75);
      canvas.drawPath(path, paint);
    }
  }

  void _drawCausticsOverlay(Canvas canvas, Size size, double time) {
    final p = Paint()..blendMode = BlendMode.plus;
    const bandCount = 3;
    for (int i = 0; i < bandCount; i++) {
      final phase = time * 0.28 + i * 1.05;
      final y = (sin(phase) * 0.5 + 0.5) * size.height * 0.78 + 36;
      final rect = Rect.fromLTWH(0, y, size.width, 22);
      final g = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.02),
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.02),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      p.shader = g.createShader(rect);
      canvas.drawRect(rect, p);
    }
  }

  @override
  bool shouldRepaint(covariant AquariumPainter oldDelegate) => true;
}
