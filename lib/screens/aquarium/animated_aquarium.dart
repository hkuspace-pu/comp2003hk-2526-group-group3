import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'aquarium_painter.dart';
import 'bubble.dart';
import 'fish.dart';
import 'fish_types.dart';

class AnimatedAquariumController {
  VoidCallback? _burst;
  VoidCallback? _addFish;

  void burstBubbles() => _burst?.call();
  void addFish() => _addFish?.call();
}

class AnimatedAquarium extends StatefulWidget {
  const AnimatedAquarium({
    super.key,
    this.fishCount = 6,
    this.fishIds,
    this.onTap,
    this.overlayChild,
    this.controller,
    this.useSprites = true,
  });

  final int fishCount;
  final List<String>? fishIds;
  final VoidCallback? onTap;
  final Widget? overlayChild;
  final AnimatedAquariumController? controller;
  final bool useSprites;

  @override
  State<AnimatedAquarium> createState() => _AnimatedAquariumState();
}

class _AnimatedAquariumState extends State<AnimatedAquarium>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  final rng = Random();

  double _time = 0;
  double _last = 0;
  double _frameDt = 1 / 60;

  final List<Fish> _fishes = [];
  final List<Bubble> _bubbles = [];

  ui.Image? _clownImg;
  ui.Image? _goldImg;
  ui.Image? _blueImg;
  ui.Image? _shrimpImg;

  bool _spritesRequested = false;

  static const _pClown = 'assets/images/clownfish.png';
  static const _pGold = 'assets/images/goldFish.png';
  static const _pBlue = 'assets/images/blueFish.png';
  static const _pShrimp = 'assets/images/shrimp.png';

  @override
  void initState() {
    super.initState();

    widget.controller?._burst = _burstBubbles;
    widget.controller?._addFish = _addFish;

    _rebuildSchool();

    for (int i = 0; i < 16; i++) {
      _bubbles.add(Bubble.random(rng));
    }

    _ticker = createTicker((elapsed) {
      final t = elapsed.inMicroseconds / 1e6;
      _frameDt = (t - _last).clamp(0.0, 0.05);
      _last = t;
      _time = t;
      setState(() {});
    })
      ..start();

    if (widget.useSprites && !_spritesRequested) {
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
  void didUpdateWidget(covariant AnimatedAquarium oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldIds = oldWidget.fishIds?.join(',') ?? '';
    final newIds = widget.fishIds?.join(',') ?? '';

    if (oldWidget.fishCount != widget.fishCount || oldIds != newIds) {
      _rebuildSchool();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<ui.Image?> _tryLoad(String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadSprites() async {
    final imgs = await Future.wait<ui.Image?>([
      _tryLoad(_pClown),
      _tryLoad(_pGold),
      _tryLoad(_pBlue),
      _tryLoad(_pShrimp),
    ]);
    _clownImg = imgs[0];
    _goldImg = imgs[1];
    _blueImg = imgs[2];
    _shrimpImg = imgs[3];
  }

  void _attachSprite(Fish f) {
    switch (f.fish.id) {
      case 'clownfish':
        f.sprite = _clownImg;
        break;
      case 'goldfish':
        f.sprite = _goldImg;
        break;
      case 'shrimp':
        f.sprite = _shrimpImg;
        break;
      default:
        f.sprite = _blueImg;
    }
  }

  void _rebuildSchool() {
    _fishes.clear();
    final total = widget.fishCount.clamp(1, 12);

    final ids = widget.fishIds ?? [];

    for (final id in ids.take(total)) {
      final bean = FishCatalog.byId(id);
      if (bean == null) continue;

      final fish = Fish.random(rng, bean);
      _attachSprite(fish);
      _fishes.add(fish);
    }

    const all = FishCatalog.all;
    while (_fishes.length < total && all.isNotEmpty) {
      final bean = all[rng.nextInt(all.length)];
      final fish = Fish.random(rng, bean);
      _attachSprite(fish);
      _fishes.add(fish);
    }
  }

  void _addFish() {
    if (_fishes.length >= 12) return;

    final all = FishCatalog.all;
    if (all.isEmpty) return;

    final bean = all[rng.nextInt(all.length)];
    final fish = Fish.random(rng, bean);

    _attachSprite(fish);
    _fishes.add(fish);
    setState(() {});
  }

  void _burstBubbles() {
    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size ?? const Size(360, 220);

    for (int i = 0; i < 14; i++) {
      _bubbles.add(Bubble.spawnFromBottom(rng, size));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);

        for (final f in _fishes) {
          f.update(_frameDt, size);
        }

        _bubbles.removeWhere((b) => b.dead);
        for (final b in _bubbles) {
          b.update(_frameDt, size);
        }

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
            child: widget.overlayChild ?? const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
