// lib/aquarium/fish.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'fish_types.dart';

/// Procedural fish entity (position + motion + draw).
/// - If [sprite] is provided, draws the image (best visual match to emoji art).
/// - Otherwise, falls back to a vector-drawn style per [type].
class Fish {
  final FishType type;

  Offset pos; // current position
  double speed; // pixels per second
  double heading; // radians (0 = right)
  double wiggleAmp; // amplitude for tail/body wiggle
  double wiggleFreq; // wiggle frequency in Hz
  double size; // scale factor; ~1.0 is medium fish

  Color bodyColor; // base body color (used by vector fallback)
  ui.Image? sprite; // optional loaded sprite image asset

  Fish({
    required this.type,
    required this.pos,
    required this.speed,
    required this.heading,
    required this.wiggleAmp,
    required this.wiggleFreq,
    required this.size,
    required this.bodyColor,
    this.sprite,
  });

  /// Construct a fish of a given type with type‑specific palette & speed.
  /// [bounds] helps pick a reasonable initial position.
  factory Fish.randomOfType(Random rng, FishType type, {Size? bounds}) {
    final s = rng.nextDouble() * 1.1 + 0.7;
    final freq = rng.nextDouble() * 1.3 + 0.6;
    final amp = rng.nextDouble() * 0.22 + 0.12;
    double speed;
    Color color;

    switch (type) {
      case FishType.clown:
        speed = rng.nextDouble() * 70 + 50;
        color = const Color(0xFFF77F00); // vivid orange
        break;
      case FishType.gold:
        speed = rng.nextDouble() * 65 + 45;
        color = const Color(0xFFFFC300); // golden yellow
        break;
      case FishType.blue:
        speed = rng.nextDouble() * 80 + 55;
        color = const Color(0xFF2E86DE); // ocean blue
        break;
      case FishType.shrimp:
        speed = rng.nextDouble() * 35 + 20; // slower
        color = const Color(0xFFE74C3C); // reddish
        break;
    }

    // Initial position: shrimp near bottom band; fish distributed
    final w = bounds?.width ?? 360;
    final h = bounds?.height ?? 220;
    final initPos = (type == FishType.shrimp)
        ? Offset(
            rng.nextDouble() * (w - 80) + 40, h - (rng.nextDouble() * 60 + 60))
        : Offset(rng.nextDouble() * (w - 80) + 40,
            rng.nextDouble() * (h - 120) + 60);

    return Fish(
      type: type,
      pos: initPos,
      speed: speed,
      heading: rng.nextDouble() * 2 * pi,
      wiggleAmp: amp,
      wiggleFreq: freq,
      size: s,
      bodyColor: color,
    );
  }

  /// Motion update (shrimp skim near bottom; fish free swim with soft bounds).
  void update(double dt, Size bounds) {
    final rand = Random();

    if (type == FishType.shrimp) {
      // Shrimp glides horizontally across a band near the sand tray.
      final bandTop = bounds.height - 100;
      final bandBottom = bounds.height - 60;

      final vy = sin(pos.dx * 0.02) * 6.0; // tiny vertical wobble
      final vx = cos(heading) * speed * 0.6;

      pos += Offset(vx * dt, vy * dt);

      // Wrap horizontally; clamp vertical in shrimp band
      if (pos.dx < 10) pos = Offset(bounds.width - 10, pos.dy);
      if (pos.dx > bounds.width - 10) pos = Offset(10, pos.dy);
      pos = Offset(pos.dx, pos.dy.clamp(bandTop, bandBottom));

      // Gentle heading jitter
      heading += (rand.nextDouble() - 0.5) * 0.015;
      return;
    }

    // Fish motion
    heading += (rand.nextDouble() - 0.5) * 0.02;

    final vx = cos(heading) * speed;
    final vy = sin(heading) * speed;
    pos += Offset(vx * dt, vy * dt);

    // Soft bounds for fish
    const margin = 20.0;
    if (pos.dx < margin) heading = 0;
    if (pos.dx > bounds.width - margin) heading = pi;
    if (pos.dy < margin) heading = pi / 2;
    if (pos.dy > bounds.height - 60) heading = -pi / 2;
  }

  /// Draw fish. Prefer sprite if available; otherwise use vector fallback.
  void draw(Canvas canvas, double time) {
    if (sprite != null) {
      _drawSprite(canvas, time);
    } else {
      _drawFallbackVector(canvas, time);
    }
  }

  // ---------------------------------------------------------------------------
  // SPRITE DRAW (image-based; best for matching emoji artwork exactly)
  // ---------------------------------------------------------------------------
  void _drawSprite(Canvas canvas, double time) {
    final img = sprite!;
    // Target visual size on canvas (tweak to match your asset proportions)
    final len = 56.0 * size; // width
    final height = 28.0 * size; // height

    final wiggle = sin(time * 2 * pi * wiggleFreq) * wiggleAmp;

    // Prepare transforms: translate to pos, rotate by heading+wiggle,
    // and flip horizontally so fish faces the swim direction.
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(heading + wiggle * 0.12);

    final facingLeft = cos(heading) < 0;
    if (facingLeft) {
      canvas.scale(-1, 1); // flip X so sprite faces left
    }

    final dst =
        Rect.fromCenter(center: const Offset(0, 0), width: len, height: height);
    final src =
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    // Draw the sprite into the target rect.
    canvas.drawImageRect(img, src, dst, paint);

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // VECTOR FALLBACK (pure Canvas)
  // ---------------------------------------------------------------------------
  void _drawFallbackVector(Canvas canvas, double time) {
    switch (type) {
      case FishType.clown:
        _drawClownFish(canvas, time);
        break;
      case FishType.gold:
        _drawGoldFish(canvas, time);
        break;
      case FishType.blue:
        _drawBlueFish(canvas, time);
        break;
      case FishType.shrimp:
        _drawShrimp(canvas, time);
        break;
    }
  }

  // ---------- Style implementations (vector) ----------

  void _drawClownFish(Canvas canvas, double time) {
    final len = 54.0 * size;
    final height = 24.0 * size;
    final tailLen = 18.0 * size;
    final wiggle = sin(time * 2 * pi * wiggleFreq) * wiggleAmp;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(heading + wiggle * 0.2);

    // Body
    final bodyRect =
        Rect.fromCenter(center: const Offset(0, 0), width: len, height: height);
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawOval(bodyRect, bodyPaint);

    // White stripes with thin black edges (three bands)
    final stripePaint = Paint()..color = Colors.white.withOpacity(0.95);
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.black.withOpacity(0.5);

    for (final xFrac in [0.05, 0.32, 0.62]) {
      final x = lerpDouble(-len * 0.45, len * 0.45, xFrac)!;
      final stripeRect = Rect.fromCenter(
          center: Offset(x, 0), width: len * 0.18, height: height * 0.95);
      final r =
          RRect.fromRectAndRadius(stripeRect, Radius.circular(height * 0.35));
      canvas.drawRRect(r, stripePaint);
      canvas.drawRRect(r, edgePaint);
    }

    // Tail
    final tailPaint = Paint()..color = bodyColor.withOpacity(0.95);
    final tailPath = Path()
      ..moveTo(-len * 0.5, 0)
      ..lineTo(-len * 0.5 - tailLen, height * 0.28 + wiggle * 6)
      ..lineTo(-len * 0.5 - tailLen, -height * 0.28 + wiggle * -6)
      ..close();
    canvas.drawPath(tailPath, tailPaint);

    // Fins
    final finPaint = Paint()..color = bodyColor.withOpacity(0.9);
    canvas.drawPath(
      Path()
        ..moveTo(-len * 0.05, -height * 0.45)
        ..lineTo(-len * 0.2, -height * 0.15)
        ..lineTo(len * 0.05, -height * 0.3)
        ..close(),
      finPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-len * 0.05, height * 0.45)
        ..lineTo(-len * 0.2, height * 0.15)
        ..lineTo(len * 0.05, height * 0.3)
        ..close(),
      finPaint,
    );

    // Eye
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black87;
    final eyeCenter = Offset(len * 0.25, -height * 0.15);
    canvas.drawCircle(eyeCenter, 3.0 * size, eyePaint);
    canvas.drawCircle(eyeCenter.translate(1.0, 0.5), 1.8 * size, pupilPaint);

    canvas.restore();
  }

  void _drawGoldFish(Canvas canvas, double time) {
    final len = 52.0 * size;
    final height = 22.0 * size;
    final tailLen = 24.0 * size;
    final wiggle = sin(time * 2 * pi * wiggleFreq) * wiggleAmp;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(heading + wiggle * 0.18);

    final bodyRect =
        Rect.fromCenter(center: const Offset(0, 0), width: len, height: height);
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawOval(bodyRect, bodyPaint);
    final highlight = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.22), Colors.transparent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, highlight);

    // Flowing forked tail
    final tailPaint = Paint()..color = bodyColor.withOpacity(0.92);
    final tail = Path()
      ..moveTo(-len * 0.5, 0)
      ..quadraticBezierTo(-len * 0.5 - tailLen * 0.3, height * 0.4 + wiggle * 7,
          -len * 0.5 - tailLen, height * 0.1)
      ..quadraticBezierTo(-len * 0.5 - tailLen * 0.4,
          -height * 0.5 + wiggle * -7, -len * 0.5, 0)
      ..close();
    canvas.drawPath(tail, tailPaint);

    // Dorsal fin
    final finPaint = Paint()..color = bodyColor.withOpacity(0.88);
    final dorsal = Path()
      ..moveTo(-len * 0.05, -height * 0.5)
      ..quadraticBezierTo(0, -height * 0.8, len * 0.18, -height * 0.4)
      ..quadraticBezierTo(len * 0.05, -height * 0.3, -len * 0.05, -height * 0.5)
      ..close();
    canvas.drawPath(dorsal, finPaint);

    // Eye
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black87;
    final eyeCenter = Offset(len * 0.25, -height * 0.1);
    canvas.drawCircle(eyeCenter, 2.8 * size, eyePaint);
    canvas.drawCircle(eyeCenter.translate(1.0, 0.5), 1.7 * size, pupilPaint);

    canvas.restore();
  }

  void _drawBlueFish(Canvas canvas, double time) {
    final len = 56.0 * size;
    final height = 24.0 * size;
    final tailLen = 20.0 * size;
    final wiggle = sin(time * 2 * pi * wiggleFreq) * wiggleAmp;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(heading + wiggle * 0.2);

    final bodyRect =
        Rect.fromCenter(center: const Offset(0, 0), width: len, height: height);
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawOval(bodyRect, bodyPaint);
    final gradient = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF74B9FF).withOpacity(0.35), Colors.transparent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, gradient);

    // Tail
    final tailPath = Path()
      ..moveTo(-len * 0.5, 0)
      ..lineTo(-len * 0.5 - tailLen, height * 0.25 + wiggle * 6)
      ..lineTo(-len * 0.5 - tailLen, -height * 0.25 + wiggle * -6)
      ..close();
    final tailPaint = Paint()..color = const Color(0xFF2C82C9);
    canvas.drawPath(tailPath, tailPaint);

    // Dorsal fin
    final finPaint = Paint()..color = const Color(0xFF2569B5);
    final dorsal = Path()
      ..moveTo(-len * 0.1, -height * 0.45)
      ..lineTo(0.0, -height * 0.7)
      ..lineTo(len * 0.15, -height * 0.4)
      ..close();
    canvas.drawPath(dorsal, finPaint);

    // Eye
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black87;
    final eyeCenter = Offset(len * 0.28, -height * 0.12);
    canvas.drawCircle(eyeCenter, 3.0 * size, eyePaint);
    canvas.drawCircle(eyeCenter.translate(1.0, 0.5), 1.8 * size, pupilPaint);

    canvas.restore();
  }

  void _drawShrimp(Canvas canvas, double time) {
    final len = 40.0 * size;
    final height = 18.0 * size;
    final wiggle = sin(time * 2 * pi * wiggleFreq) * wiggleAmp;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(heading + wiggle * 0.15);

    // Segmented body (3–4 rounded capsules)
    final segPaint = Paint()..color = bodyColor;
    for (int i = 0; i < 4; i++) {
      final t = i / 3.0;
      final x = lerpDouble(-len * 0.4, len * 0.2, t)!;
      final segRect = Rect.fromCenter(
        center: Offset(x, 0),
        width: len * 0.28,
        height: height * (0.85 - t * 0.2),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(segRect, Radius.circular(height * 0.5)),
        segPaint,
      );
    }

    // Antennae (white lines)
    final antenna = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.9);
    final antPath = Path()
      ..moveTo(len * 0.15, -height * 0.1)
      ..quadraticBezierTo(len * 0.35, -height * 0.5, len * 0.65, -height * 0.35)
      ..moveTo(len * 0.15, 0)
      ..quadraticBezierTo(
          len * 0.32, -height * 0.25, len * 0.55, -height * 0.1);
    canvas.drawPath(antPath, antenna);

    // Legs (dark lines)
    final legPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.black.withOpacity(0.7);
    for (int i = 0; i < 5; i++) {
      final x = -len * 0.2 + i * (len * 0.12);
      final leg = Path()
        ..moveTo(x, height * 0.2)
        ..lineTo(x + 6 + wiggle * 4, height * 0.35);
      canvas.drawPath(leg, legPaint);
    }

    canvas.restore();
  }
}
