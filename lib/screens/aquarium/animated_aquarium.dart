// lib/aquarium/animated_aquarium.dart
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'aquarium_painter.dart';
import 'bubble.dart';
import 'fish.dart';
import 'fish_types.dart';

/// Optional controller to trigger canvas-side actions from your UI.
/// Example:
///   final controller = AnimatedAquariumController();
///   AnimatedAquarium(controller: controller, ...);
///   // later
///   controller.burstBubbles();
class AnimatedAquariumController {
  VoidCallback? _burst;
  VoidCallback? _addFish;

  void burstBubbles() => _burst?.call();
  void addFish() => _addFish?.call();
}

/// Animated aquarium widget. Place it inside your tank container.
/// You can pass [fishEmojiTypes] to shape the school (e.g., ['🐠','🐟','🦐']).
class AnimatedAquarium extends StatefulWidget {
  const AnimatedAquarium({
    super.key,
    this.fishCount = 6,
    this.onTap,
    this.overlayChild,
    this.fishEmojiTypes,
    this.controller,
    this.useSprites = true, // if false, always use vector fish
  });

  /// Number of fish to render (will be clamped 1..12).
  final int fishCount;

  /// Tap handler for the whole aquarium area (optional).
  final VoidCallback? onTap;

  /// Any widgets you want over the water (labels, emojis, UI).
  final Widget? overlayChild;

  /// Emoji list that determines fish types. Example: ['🐠','🐟','🦐'].
  final List<String>? fishEmojiTypes;

  /// Optional controller to trigger actions (bubble burst, add fish).
  final AnimatedAquariumController? controller;

  /// If true, tries to load sprite PNGs for a closer emoji look.
  final bool useSprites;

  @override
  State<AnimatedAquarium> createState() => _AnimatedAquariumState();
}

class _AnimatedAquariumState extends State<AnimatedAquarium>
    with TickerProviderStateMixin {
  // ---- Animation timing ----
  late final Ticker _ticker;
  double _time = 0.0;
  double _last = 0.0;
  double _frameDt = 1 / 60.0;

  // ---- Entities ----
  final rng = Random();
  final List<Fish> _fishes = [];
  final List<Bubble> _bubbles = [];

  // ---- Optional sprite images ----
  ui.Image? _clownImg;
  ui.Image? _blueImg;
  ui.Image? _goldImg; // optional; if null we’ll reuse clown/blue
  ui.Image? _shrimpImg;

  bool _spritesRequested = false; // prevent double-loading

  // Asset paths (change to match your project if needed)
  static const String _pClown = 'assets/images/clownfish.png';
  static const String _pBlue = 'assets/images/blueFish.png';
  static const String _pGold = 'assets/images/goldFish.png';
  static const String _pShrimp = 'assets/images/shrimp.png';

  @override
  void initState() {
    super.initState();

    // Wire controller callbacks, if provided.
    widget.controller?._burst = _burstBubbles;
    widget.controller?._addFish = _addFish;

    // Build initial school & bubbles
    _rebuildSchool();
    for (int i = 0; i < 16; i++) {
      _bubbles.add(Bubble.random(rng));
    }

    // Start driving frames
    _ticker = createTicker((elapsed) {
      final t = elapsed.inMicroseconds / 1e6;
      final dt = (t - _last).clamp(0.0, 0.05);
      _last = t;
      _time = t;
      _frameDt = dt == 0 ? _frameDt : dt;
      setState(() {}); // triggers CustomPaint repaint
    })
      ..start();

    // Kick off sprite loading (non-blocking) if enabled
    if (widget.useSprites && !_spritesRequested) {
      _spritesRequested = true;
      _loadSprites().then((_) {
        // Attach images to existing fish if available
        for (final f in _fishes) {
          _attachSprite(f);
        }
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedAquarium oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Controller may be replaced by parent; rewire hooks
    if (oldWidget.controller != widget.controller) {
      widget.controller?._burst = _burstBubbles;
      widget.controller?._addFish = _addFish;
    }

    // If fishCount or emoji configuration changes, rebuild the school.
    final countChanged = oldWidget.fishCount != widget.fishCount;
    final emojisChanged = (oldWidget.fishEmojiTypes ?? const []) !=
        (widget.fishEmojiTypes ?? const []);

    if (countChanged || emojisChanged) {
      _rebuildSchool();
      // Re-attach sprites if available
      for (final f in _fishes) {
        _attachSprite(f);
      }
    }

    // If sprite setting toggled to ON and we never loaded, try to load now.
    if (widget.useSprites &&
        !_spritesRequested &&
        (_clownImg == null && _blueImg == null && _shrimpImg == null)) {
      _spritesRequested = true;
      _loadSprites().then((_) {
        for (final f in _fishes) {
          _attachSprite(f);
        }
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // Sprite loading
  // ------------------------------------------------------------
  Future<ui.Image?> _tryLoadImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      // Asset missing or not declared in pubspec; fall back to vector fish.
      return null;
    }
  }

  Future<void> _loadSprites() async {
    // Load all in parallel; any missing will remain null
    final results = await Future.wait<ui.Image?>([
      _tryLoadImage(_pClown),
      _tryLoadImage(_pBlue),
      _tryLoadImage(_pGold),
      _tryLoadImage(_pShrimp),
    ]);

    _clownImg = results[0];
    _blueImg = results[1];
    _goldImg = results[2];
    _shrimpImg = results[3];
  }

  void _attachSprite(Fish f) {
    // If images are null, Fish will draw vector fallback automatically.
    switch (f.type) {
      case FishType.clown:
        f.sprite = _clownImg ?? f.sprite;
        break;
      case FishType.blue:
        f.sprite = _blueImg ?? f.sprite;
        break;
      case FishType.gold:
        f.sprite = _goldImg ?? f.sprite;
        break;
      case FishType.shrimp:
        f.sprite = _shrimpImg ?? f.sprite;
        break;
    }
  }

  // ------------------------------------------------------------
  // School & actions
  // ------------------------------------------------------------
  void _rebuildSchool() {
    final total = widget.fishCount.clamp(1, 12);

    // Map emojis → FishType
    final requested = (widget.fishEmojiTypes ?? const ['🐠', '🐟', '🦐'])
        .map(typeFromEmoji)
        .toList();

    _fishes.clear();

    // One fish for each requested emoji (preserving order) up to 'total'.
    for (final t in requested.take(total)) {
      final f = Fish.randomOfType(rng, t);
      _attachSprite(f);
      _fishes.add(f);
    }

    // Fill the rest with a pleasant mix (avoid too many shrimps by default).
    final mix = <FishType>[FishType.clown, FishType.gold, FishType.blue];
    while (_fishes.length < total) {
      final f = Fish.randomOfType(rng, mix[rng.nextInt(mix.length)]);
      _attachSprite(f);
      _fishes.add(f);
    }
  }

  void _burstBubbles() {
    // Spawn a handful of bubbles from bottom across width.
    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size ?? const Size(360, 220);
    for (int i = 0; i < 14; i++) {
      _bubbles.add(Bubble.spawnFromBottom(rng, size));
    }
    setState(() {});
  }

  void _addFish() {
    if (_fishes.length >= 12) return;
    final mix = <FishType>[FishType.clown, FishType.gold, FishType.blue];
    final f = Fish.randomOfType(rng, mix[rng.nextInt(mix.length)]);
    _attachSprite(f);
    _fishes.add(f);
    setState(() {});
  }

  // ------------------------------------------------------------
  // Build & simulate
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);

        // Advance simulation with the latest dt and current bounds.
        for (final f in _fishes) {
          f.update(_frameDt, size);
        }

        _bubbles.removeWhere((b) => b.dead);
        for (final b in _bubbles) {
          b.update(_frameDt, size);
        }

        // Occasional ambient bubble
        if (rng.nextDouble() < 0.06) {
          _bubbles.add(Bubble.spawnFromBottom(rng, size));
        }

        return GestureDetector(
          onTap: widget.onTap,
          child: CustomPaint(
            painter: AquariumPainter(
              fishes: _fishes,
              bubbles: _bubbles,
              time: _time,
            ),
            isComplex: true,
            willChange: true,
            child: widget.overlayChild ?? const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
