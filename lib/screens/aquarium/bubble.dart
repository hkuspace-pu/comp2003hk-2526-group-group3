import 'dart:math';
import 'package:flutter/material.dart';

/// A lightweight bubble particle that rises and fades.
class Bubble {
  Offset pos; // current position
  double radius; // visual radius in pixels
  double vy; // vertical velocity (negative => rising)
  double alpha; // transparency 0..1
  bool dead = false;

  Bubble({
    required this.pos,
    required this.radius,
    required this.vy,
    required this.alpha,
  });

  /// Random bubble anywhere in the bounds (fallback default size if null).
  factory Bubble.random(Random rng, {Size? bounds}) {
    final w = bounds?.width ?? 360;
    final h = bounds?.height ?? 220;
    final x = rng.nextDouble() * (w - 40) + 20;
    final y = rng.nextDouble() * (h - 40) + 20;
    return Bubble(
      pos: Offset(x, y),
      radius: rng.nextDouble() * 4 + 2,
      vy: -(rng.nextDouble() * 30 + 20), // -20 .. -50 px/s
      alpha: rng.nextDouble() * 0.6 + 0.3, // 0.3 .. 0.9
    );
  }

  /// Spawn from the bottom edge, drifting upward.
  factory Bubble.spawnFromBottom(Random rng, Size size) {
    final x = rng.nextDouble() * size.width;
    final y = size.height - 30;
    return Bubble(
      pos: Offset(x, y),
      radius: rng.nextDouble() * 4 + 2,
      vy: -(rng.nextDouble() * 25 + 15), // -15 .. -40 px/s
      alpha: rng.nextDouble() * 0.5 + 0.4, // 0.4 .. 0.9
    );
  }

  /// Advance motion & fade; mark dead when off-screen or fully transparent.
  void update(double dt, Size bounds) {
    // Horizontal drift depending on vertical position (gives a gentle wobble)
    final drift = sin(pos.dy * 0.03) * 8.0;
    pos = Offset(pos.dx + drift * dt, pos.dy + vy * dt);

    // Fade slightly as rising
    alpha = (alpha - dt * 0.05).clamp(0.0, 1.0);

    // Recycle when out of view or nearly transparent
    if (pos.dy < -10 || alpha <= 0.02) {
      dead = true;
    }
  }

  /// Draw bubble circle + small specular highlight.
  void draw(Canvas canvas) {
    final ring = Paint()
      ..color = Colors.white.withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(pos, radius, ring);

    // Tiny highlight on the upper-left for a glassy look
    final highlight = Paint()
      ..color = Colors.white.withOpacity(alpha * 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      pos.translate(-radius * 0.35, -radius * 0.35),
      radius * 0.25,
      highlight,
    );
  }
}
