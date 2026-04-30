import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import 'store_screen.dart';
import 'dashboard_screen.dart';

class LuckyScreen extends StatefulWidget {
  final int price;
  final Map<String, double>? weights;

  const LuckyScreen({
    super.key,
    required this.price,
    this.weights,
  });

  @override
  State<LuckyScreen> createState() => _LuckyScreenState();
}

class _LuckyScreenState extends State<LuckyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  late final Animation<double> _spin;
  late final Animation<double> _shake;
  late final Animation<double> _split;
  late final Animation<double> _flash;
  late final Animation<double> _confetti;

  final _firestore = FirestoreService();

  LuckyResult? _result;
  String? _error;
  bool _revealed = false;
  bool _busy = true;

  @override
  void initState() {
    super.initState();

    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _spin = CurvedAnimation(
      parent: _ctl,
      curve: const Interval(0.0, 0.72, curve: Curves.easeInOutCubic),
    );

    _shake = CurvedAnimation(
      parent: _ctl,
      curve: const Interval(0.0, 0.72, curve: Curves.elasticIn),
    );

    _split = CurvedAnimation(
      parent: _ctl,
      curve: const Interval(0.74, 0.88, curve: Curves.easeOutBack),
    );

    _flash = CurvedAnimation(
      parent: _ctl,
      curve: const Interval(0.78, 0.92, curve: Curves.easeOut),
    );

    _confetti = CurvedAnimation(
      parent: _ctl,
      curve: const Interval(0.82, 1.0, curve: Curves.linear),
    );

    _start();
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
      _revealed = false;
    });

    _ctl.forward(from: 0);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Not logged in';
      });
      return;
    }

    try {
      final weights = widget.weights ?? AppConstants.luckyWeights;
      final res = await _firestore.purchaseLucky(
        uid: user.uid,
        price: widget.price,
        weights: weights,
      );

      if (!mounted) return;

      if (res == null) {
        setState(() {
          _busy = false;
          _error = 'Not enough points!';
        });
        return;
      }

      setState(() {
        _result = res;
      });

      final totalMs = _ctl.duration!.inMilliseconds;
      await Future.delayed(Duration(milliseconds: (totalMs * 0.76).round()));
      if (!mounted) return;
      setState(() {
        _busy = false;
        _revealed = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Lucky failed: $e';
      });
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fishId = _result?.fishId;
    final fishItem = fishId != null ? AppConstants.storeItems[fishId] : null;
    final fishIcon = fishItem?['icon'] ?? '🐠';
    final fishName = fishItem?['name'] ?? (fishId ?? '');

    if (_error != null) {
      return Scaffold(
        body: GradientBackground(
          child: SizedBox.expand(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Lucky Draw',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildBackButtons(context),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _start,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDarkGrey
                                  .withValues(alpha: 0.55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'TRY AGAIN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: GradientBackground(
        child: SizedBox.expand(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;

                final base = min(w, h);
                final cardSize = (base * 0.62).clamp(260.0, 520.0);
                final ballSize = (cardSize * 0.52).clamp(140.0, 260.0);

                return Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _ctl,
                      builder: (_, __) {
                        return IgnorePointer(
                          child: Opacity(
                            opacity: _confetti.value.clamp(0.0, 1.0),
                            child: _ConfettiLayer(progress: _confetti.value),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _ctl,
                      builder: (_, __) {
                        return IgnorePointer(
                          child: Opacity(
                            opacity: (_flash.value * 0.95).clamp(0.0, 0.95),
                            child: _FlashBurst(progress: _flash.value),
                          ),
                        );
                      },
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Lucky Draw',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 18),
                              AnimatedBuilder(
                                animation: _ctl,
                                builder: (_, __) {
                                  final t = _spin.value;
                                  final shakeX = sin(t * 22 * pi) *
                                      10.0 *
                                      (1 - t) *
                                      _shake.value;
                                  final shakeY = cos(t * 18 * pi) *
                                      7.0 *
                                      (1 - t) *
                                      _shake.value;
                                  final rot = t * 10 * pi;

                                  return Transform.translate(
                                    offset: Offset(shakeX, shakeY),
                                    child: Container(
                                      width: cardSize,
                                      height: cardSize,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.18),
                                        ),
                                      ),
                                      child: Center(
                                        child: Transform.rotate(
                                          angle: rot,
                                          child: _CapsuleSplitBall(
                                            size: ballSize,
                                            glow: 0.35 +
                                                0.55 * (sin(t * 2 * pi).abs()),
                                            split:
                                                _revealed ? _split.value : 0.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              Text(
                                (_revealed && _result != null)
                                    ? '✨ Revealed!'
                                    : 'Spinning...',
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (_busy) ...[
                                const CircularProgressIndicator(
                                  color: AppColors.accentOrange,
                                ),
                              ],
                              const SizedBox(height: 18),
                              if (_result != null && _revealed) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'You got:',
                                        style: TextStyle(
                                          color: AppColors.textGrey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        fishIcon,
                                        style: const TextStyle(fontSize: 72),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        fishName,
                                        style: const TextStyle(
                                          color: AppColors.textWhite,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Remaining: ${_result!.remainingPoints} 💰',
                                        style: const TextStyle(
                                          color: AppColors.accentOrange,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildBackButtons(context),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const DashboardScreen(initialIndex: 2)),
                (r) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'VIEW AQUARIUM',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StoreScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.primaryDarkGrey.withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'CONTINUE SHOPPING',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _CapsuleSplitBall extends StatelessWidget {
  final double size;
  final double glow;
  final double split;
  const _CapsuleSplitBall({
    required this.size,
    required this.glow,
    required this.split,
  });

  @override
  Widget build(BuildContext context) {
    final d = size;

    if (split < 0.02) {
      return SizedBox(
        width: d,
        height: d,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _GlowBehind(size: d, glow: glow),
            _CapsuleBallFace(size: d),
          ],
        ),
      );
    }

    final sep = (d * 0.35) * split;
    final fadeOut = (split * 0.65).clamp(0.0, 0.75);

    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _GlowBehind(size: d, glow: glow),
          Opacity(
            opacity: (1.0 - fadeOut),
            child: _CapsuleBallFace(size: d),
          ),
          Transform.translate(
            offset: Offset(0, -sep),
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 0.5,
                child: _CapsuleBallFace(size: d),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, sep),
            child: ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 0.5,
                child: _CapsuleBallFace(size: d),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBehind extends StatelessWidget {
  final double size;
  final double glow;
  const _GlowBehind({required this.size, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(glow),
            blurRadius: 28,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}

class _CapsuleBallFace extends StatelessWidget {
  final double size;
  const _CapsuleBallFace({required this.size});

  @override
  Widget build(BuildContext context) {
    final d = size;

    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.90),
            Colors.amber.withValues(alpha: 0.95),
            Colors.orange.withValues(alpha: 0.98),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: d * 0.72,
          height: d * 0.72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: const Center(
            child: Text(
              '?',
              style: TextStyle(fontSize: 36, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlashBurst extends StatelessWidget {
  final double progress;
  const _FlashBurst({required this.progress});

  @override
  Widget build(BuildContext context) {
    final scale = (0.6 + progress * 1.8);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    return Center(
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.75 * alpha),
                Colors.yellow.withValues(alpha: 0.45 * alpha),
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiLayer extends StatelessWidget {
  final double progress;
  const _ConfettiLayer({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _ConfettiPainter(progress: progress),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final colors = [
      Colors.redAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.amberAccent,
      Colors.purpleAccent,
      Colors.cyanAccent,
      Colors.orangeAccent,
    ];
    const n = 80;

    for (int i = 0; i < n; i++) {
      final rx = _hash01(i * 17 + 3);
      final ry = _hash01(i * 29 + 7);
      final sp = 0.65 + _hash01(i * 43 + 11) * 1.15;
      final rot = _hash01(i * 53 + 19) * 2 * pi;
      final w = 6.0 + _hash01(i * 61 + 23) * 10.0;
      final h = 8.0 + _hash01(i * 71 + 31) * 16.0;

      final x = rx * size.width;
      final y0 = -0.25 * size.height - (ry * 0.55 * size.height);
      final y = y0 + progress * sp * (size.height * 1.55);

      final a =
          (1.0 - (progress - 0.75).clamp(0.0, 0.25) / 0.25).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.90 * a)
        ..isAntiAlias = true;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot + progress * 8.0);

      final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  double _hash01(int seed) {
    final x = sin(seed * 999.123) * 10000;
    return (x - x.floor()).abs().clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
