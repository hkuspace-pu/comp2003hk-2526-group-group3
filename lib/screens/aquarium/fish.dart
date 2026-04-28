import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'fish_types.dart';

class Fish {
  final FishBean fish;
  final int level;

  Offset pos;
  double speed;
  int dir;
  double wiggleAmp;
  double wiggleFreq;
  double size;
  Color bodyColor;
  ui.Image? sprite;

  final Random rng;
  double baseYTarget;
  double baseYVel;
  double retargetIn;
  double baseY;
  double bobAmp;
  double bobFreq;
  double bobPhase;
  double swimT;

  Fish({
    required this.fish,
    required this.pos,
    required this.speed,
    required this.dir,
    required this.wiggleAmp,
    required this.wiggleFreq,
    required this.size,
    required this.bodyColor,
    required this.level,
    required this.rng,
    required this.baseYTarget,
    required this.baseYVel,
    required this.retargetIn,
    required this.baseY,
    required this.bobAmp,
    required this.bobFreq,
    required this.bobPhase,
    required this.swimT,
    this.sprite,
  });

  factory Fish.random(
    Random rng,
    FishBean fish, {
    Size? bounds,
    int level = 1,
  }) {
    final myRng = Random(rng.nextInt(1 << 31));

    double speed;
    Color color;

    switch (fish.id) {
      case 'clownfish':
        speed = rng.nextDouble() * 70 + 50;
        color = const Color(0xFFF77F00);
        break;
      case 'goldfish':
        speed = rng.nextDouble() * 65 + 45;
        color = const Color(0xFFFFC300);
        break;
      case 'shrimp':
        speed = rng.nextDouble() * 35 + 20;
        color = const Color(0xFFE74C3C);
        break;
      default:
        speed = rng.nextDouble() * 75 + 50;
        color = const Color(0xFF2E86DE);
    }

    final baseSize = rng.nextDouble() * 1.1 + 0.7;
    final scale = 1.0;

    final w = bounds?.width ?? 360;
    final h = bounds?.height ?? 220;

    final initPos = Offset(
      rng.nextDouble() * (w - 80) + 40,
      rng.nextDouble() * (h - 120) + 60,
    );

    final dir = rng.nextBool() ? 1 : -1;

    return Fish(
      fish: fish,
      pos: initPos,
      speed: speed,
      dir: dir,
      wiggleAmp: rng.nextDouble() * 0.22 + 0.12,
      wiggleFreq: rng.nextDouble() * 1.3 + 0.6,
      size: baseSize * scale,
      bodyColor: color,
      level: level,
      rng: myRng,
      baseYTarget: initPos.dy,
      baseYVel: 0,
      retargetIn: myRng.nextDouble() * 3 + 2,
      baseY: initPos.dy,
      bobAmp: 5.0,
      bobFreq: 1.6,
      bobPhase: rng.nextDouble() * pi * 2,
      swimT: rng.nextDouble() * 10,
    );
  }

  void update(double dt, Size bounds) {
    final fishHalfWidth = (56.0 * size) / 2;
    final tiltExtra = fishHalfWidth * 0.15;
    final marginX = fishHalfWidth + tiltExtra + 6;

    final left = marginX;
    final right = bounds.width - marginX;

    var x = pos.dx + dir * speed * dt;
    if (x < left) {
      x = left;
      dir = 1;
    } else if (x > right) {
      x = right;
      dir = -1;
    }

    final topLimit = 26.0;
    final bottomLimit = bounds.height - 86.0;

    baseY = baseY.clamp(topLimit + 10, bottomLimit - 10);
    baseYTarget = baseYTarget.clamp(topLimit + 10, bottomLimit - 10);

    retargetIn -= dt;
    if (retargetIn <= 0) {
      final maxStep = (bottomLimit - topLimit) * 0.22;
      final delta = (rng.nextDouble() * 2 - 1) * maxStep;
      baseYTarget =
          (baseYTarget + delta).clamp(topLimit + 10, bottomLimit - 10);
      retargetIn = rng.nextDouble() * 3 + 2;
    }

    baseY = _smoothDamp(
      baseY,
      baseYTarget,
      1.2,
      dt,
      80.0,
      (v) => baseYVel = v,
      baseYVel,
    );

    swimT += dt;
    final y = (baseY + sin(swimT * bobFreq + bobPhase) * bobAmp)
        .clamp(topLimit, bottomLimit);

    pos = Offset(x, y);
  }

  double _smoothDamp(
    double current,
    double target,
    double smoothTime,
    double dt,
    double maxSpeed,
    void Function(double v) setVelocity,
    double currentVelocity,
  ) {
    final omega = 2.0 / smoothTime;
    final x = omega * dt;
    final exp = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x);

    var change = current - target;

    final maxChange = maxSpeed * smoothTime;
    change = change.clamp(-maxChange, maxChange);
    final temp = (currentVelocity + omega * change) * dt;
    setVelocity((currentVelocity - omega * temp) * exp);
    return target + (change + temp) * exp;
  }

  void draw(Canvas canvas, double time) {
    final double speedFactor = (speed / 120).clamp(0.0, 1.0);
    final double tilt = speedFactor * 0.10 * dir;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(tilt);
    canvas.translate(-pos.dx, -pos.dy);

    if (sprite != null) {
      _drawSprite(canvas, time);
    } else {
      _drawFallbackVector(canvas, time);
    }

    canvas.restore();

    if (level >= 2) {
      _drawLevelBadge(canvas);
    }
  }

  void _drawLevelBadge(Canvas canvas) {
    final bool facingLeft = dir < 0;
    final headX = facingLeft ? pos.dx - size * 28 : pos.dx + size * 28;
    final headY = pos.dy - size * 18;

    final pulse = (sin(swimT * 4) + 1) * 0.5;
    final glowScale = 0.8 + pulse * 0.4;
    final glowAlpha = 0.55 + pulse * 0.45;
    final rotation = swimT * 0.6 * (facingLeft ? -1 : 1);

    final baseSize = size * 6;

    if (level == 2) {
      _drawStarAnimated(
        canvas,
        Offset(headX, headY),
        baseSize,
        rotation,
        glowScale,
        Colors.amber.withOpacity(glowAlpha),
      );
    } else if (level == 3) {
      _drawStarAnimated(
        canvas,
        Offset(headX - baseSize * 0.7, headY),
        baseSize * 0.85,
        rotation,
        glowScale,
        const Color(0xFFFF9F1C).withOpacity(glowAlpha),
      );
      _drawStarAnimated(
        canvas,
        Offset(headX + baseSize * 0.7, headY),
        baseSize * 0.85,
        rotation,
        glowScale,
        const Color(0xFFFF9F1C).withOpacity(glowAlpha),
      );
    } else if (level >= 4) {
      _drawCrownAnimated(
        canvas,
        Offset(headX, headY),
        baseSize * (1.1 + pulse * 0.25),
        glowAlpha,
      );
    }
  }

  void _drawStarAnimated(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    double scale,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final a = pi / 4 * i;
      final r = i.isEven ? radius : radius * 0.45;
      final p = Offset(cos(a) * r, sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  void _drawCrownAnimated(Canvas canvas, Offset c, double s, double alpha) {
    canvas.save();
    canvas.translate(c.dx, c.dy);

    final w = s;
    final h = s * 0.7;

    final path = Path()
      ..moveTo(-w * 0.5, h * 0.25)
      ..lineTo(-w * 0.3, -h * 0.2)
      ..lineTo(0, -h * 0.5)
      ..lineTo(w * 0.3, -h * 0.2)
      ..lineTo(w * 0.5, h * 0.25)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFFF3C0).withOpacity(alpha),
            const Color(0xFFFFB300).withOpacity(alpha),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromCenter(
          center: Offset.zero,
          width: w,
          height: h,
        ))
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  void _drawSprite(Canvas canvas, double time) {
    final img = sprite!;
    final len = 56.0 * size;
    final height = 28.0 * size;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    if (dir > 0) canvas.scale(-1, 1);

    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromCenter(center: Offset.zero, width: len, height: height),
      Paint(),
    );
    canvas.restore();
  }

  void _drawFallbackVector(Canvas canvas, double time) {
    switch (fish.id) {
      case 'clownfish':
        _drawClownFish(canvas, time);
        break;
      case 'goldfish':
        _drawGoldFish(canvas, time);
        break;

      case 'shrimp':
        _drawShrimp(canvas, time);
        break;
      default:
        _drawBlueFish(canvas, time);
    }
  }

  void _prepTransform(Canvas canvas, double time, double rotFactor) {
    final wiggle = sin(time * 2 * pi * wiggleFreq) * wiggleAmp;
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(wiggle * rotFactor);
    if (dir < 0) {
      canvas.scale(-1, 1);
    }
  }

  void _drawClownFish(Canvas canvas, double time) {
    final len = 54.0 * size;
    final height = 24.0 * size;
    final tailLen = 18.0 * size;

    _prepTransform(canvas, time, 0.20);

    final wiggle = sin(time * 2 * pi * wiggleFreq) * wiggleAmp;

    final bodyRect = Rect.fromCenter(
      center: const Offset(0, 0),
      width: len,
      height: height,
    );
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawOval(bodyRect, bodyPaint);

    final stripePaint = Paint()..color = Colors.white.withOpacity(0.95);
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.black.withOpacity(0.5);

    for (final xFrac in [0.05, 0.32, 0.62]) {
      final x = lerpDouble(-len * 0.45, len * 0.45, xFrac)!;
      final stripeRect = Rect.fromCenter(
        center: Offset(x, 0),
        width: len * 0.18,
        height: height * 0.95,
      );
      final r = RRect.fromRectAndRadius(
        stripeRect,
        Radius.circular(height * 0.35),
      );
      canvas.drawRRect(r, stripePaint);
      canvas.drawRRect(r, edgePaint);
    }

    final tailPaint = Paint()..color = bodyColor.withOpacity(0.95);
    final tailPath = Path()
      ..moveTo(-len * 0.5, 0)
      ..lineTo(-len * 0.5 - tailLen, height * 0.28 + wiggle * 6)
      ..lineTo(-len * 0.5 - tailLen, -height * 0.28 + wiggle * -6)
      ..close();
    canvas.drawPath(tailPath, tailPaint);

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

    _prepTransform(canvas, time, 0.18);

    final wiggle = sin(time * 2 * pi * wiggleFreq) * wiggleAmp;

    final bodyRect = Rect.fromCenter(
      center: const Offset(0, 0),
      width: len,
      height: height,
    );
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawOval(bodyRect, bodyPaint);

    final highlight = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.22), Colors.transparent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, highlight);

    final tailPaint = Paint()..color = bodyColor.withOpacity(0.92);
    final tail = Path()
      ..moveTo(-len * 0.5, 0)
      ..quadraticBezierTo(
        -len * 0.5 - tailLen * 0.3,
        height * 0.4 + wiggle * 7,
        -len * 0.5 - tailLen,
        height * 0.1,
      )
      ..quadraticBezierTo(
        -len * 0.5 - tailLen * 0.4,
        -height * 0.5 + wiggle * -7,
        -len * 0.5,
        0,
      )
      ..close();
    canvas.drawPath(tail, tailPaint);

    final finPaint = Paint()..color = bodyColor.withOpacity(0.88);
    final dorsal = Path()
      ..moveTo(-len * 0.05, -height * 0.5)
      ..quadraticBezierTo(0, -height * 0.8, len * 0.18, -height * 0.4)
      ..quadraticBezierTo(len * 0.05, -height * 0.3, -len * 0.05, -height * 0.5)
      ..close();
    canvas.drawPath(dorsal, finPaint);

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

    _prepTransform(canvas, time, 0.20);

    final wiggle = sin(time * 2 * pi * wiggleFreq) * wiggleAmp;

    final bodyRect = Rect.fromCenter(
      center: const Offset(0, 0),
      width: len,
      height: height,
    );
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawOval(bodyRect, bodyPaint);

    final gradient = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF74B9FF).withOpacity(0.35), Colors.transparent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, gradient);

    final tailPath = Path()
      ..moveTo(-len * 0.5, 0)
      ..lineTo(-len * 0.5 - tailLen, height * 0.25 + wiggle * 6)
      ..lineTo(-len * 0.5 - tailLen, -height * 0.25 + wiggle * -6)
      ..close();
    final tailPaint = Paint()..color = const Color(0xFF2C82C9);
    canvas.drawPath(tailPath, tailPaint);

    final finPaint = Paint()..color = const Color(0xFF2569B5);
    final dorsal = Path()
      ..moveTo(-len * 0.1, -height * 0.45)
      ..lineTo(0.0, -height * 0.7)
      ..lineTo(len * 0.15, -height * 0.4)
      ..close();
    canvas.drawPath(dorsal, finPaint);

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
    canvas.rotate(wiggle * 0.15);
    if (dir < 0) canvas.scale(-1, 1);

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

    final antenna = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.9);
    final antPath = Path()
      ..moveTo(len * 0.15, -height * 0.1)
      ..quadraticBezierTo(len * 0.35, -height * 0.5, len * 0.65, -height * 0.35)
      ..moveTo(len * 0.15, 0)
      ..quadraticBezierTo(
        len * 0.32,
        -height * 0.25,
        len * 0.55,
        -height * 0.1,
      );
    canvas.drawPath(antPath, antenna);

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
