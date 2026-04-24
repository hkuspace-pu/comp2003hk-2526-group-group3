import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../models/user_profile.dart';
import '../screens/aquarium/animated_aquarium.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';
import 'aquarium/fish_types.dart';
import 'store_screen.dart';

class AquariumScreen extends StatefulWidget {
  const AquariumScreen({Key? key}) : super(key: key);

  @override
  State<AquariumScreen> createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> {
  late final AnimatedAquariumController _controller;
  late final FirestoreService _firestoreService;

  final GlobalKey _tankCaptureKey = GlobalKey();
  static const int _tankMax = 10;

  @override
  void initState() {
    super.initState();
    _controller = AnimatedAquariumController();
    _firestoreService = FirestoreService();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<Uint8List> _captureAquarium() async {
    FocusScope.of(context).unfocus();
    await WidgetsBinding.instance.endOfFrame;

    final boundary = _tankCaptureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('not found render object for tank capture');
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Can not get PNG byte data from image');
    }
    return byteData.buffer.asUint8List();
  }

  Future<void> _onFeedPressed(String uid, int foodStock) async {
    if (uid.isEmpty) return;

    if (foodStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No food left 🍖 Buy more in Store.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final ok = await _firestoreService.feedFish(uid);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feed failed. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _controller.burstBubbles();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }
    final uid = user.uid;

    return StreamBuilder<UserProfile?>(
      stream: _firestoreService.getUserProfileStream(uid),
      builder: (context, snapshot) {
        final profile = snapshot.data!;
        final points = profile.totalPoints;
        final foodStock = profile.foodStock;

        final aquariumFishIds = List<String>.from(profile.aquariumFish);
        final validFishIds = aquariumFishIds
            .where((id) => FishCatalog.byId(id) != null)
            .toList();

        final fishCount = validFishIds.length;

        final storedHunger = (profile?.hungerPercent ?? 70).toDouble();
        final hungerUpdatedAt = profile?.hungerUpdatedAt;
        final hungerPercent = _firestoreService
            .computeCurrentHungerPercent(
              storedPercent: storedHunger,
              updatedAt: hungerUpdatedAt,
            )
            .round()
            .toDouble();
        final renderFishCount =
            (validFishIds.isNotEmpty ? validFishIds.length : 1);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Focus Aquarium'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '💰 $points',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentOrange,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: GradientBackground(
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  HungerBatteryIndicator(
                                    percent: hungerPercent,
                                  ),
                                  _shareButton(
                                    onTap: () => _onSharePressed(
                                      points: points,
                                      fishCount: fishCount,
                                      foodStock: foodStock,
                                      hungerPercent: hungerPercent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            RepaintBoundary(
                              key: _tankCaptureKey,
                              child: Container(
                                margin: const EdgeInsets.all(20),
                                padding: const EdgeInsets.all(20),
                                height: 400,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0077BE,
                                  ).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.textWhite.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    if (validFishIds.isEmpty)
                                      Center(
                                        child: Text(
                                          'No fish in tank yet 🐟\nGo to Collection to add fish.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.90),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      )
                                    else
                                      AnimatedAquarium(
                                        controller: _controller,
                                        fishCount: fishCount,
                                        fishIds: validFishIds,
                                        overlayChild: const Stack(
                                          children: [
                                            Positioned.fill(
                                              child: IgnorePointer(
                                                  child: Center()),
                                            ),
                                            Positioned(
                                              left: 16,
                                              bottom: 26,
                                              child: Text('🌿',
                                                  style:
                                                      TextStyle(fontSize: 36)),
                                            ),
                                            Positioned(
                                              left: 72,
                                              bottom: 28,
                                              child: Text('🪨',
                                                  style:
                                                      TextStyle(fontSize: 28)),
                                            ),
                                            Positioned(
                                              right: 24,
                                              bottom: 32,
                                              child: Text('🪸',
                                                  style:
                                                      TextStyle(fontSize: 34)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Positioned(
                                      right: 10,
                                      top: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.28),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.22)),
                                        ),
                                        child: Text(
                                          '🐟 $fishCount/$_tankMax',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStat('💰', 'Points', '$points'),
                                    _buildStat('🐟', 'Fishes', '$fishCount/10'),
                                    _buildStat('🍖', 'Food', '$foodStock'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildButton(
                                context,
                                label: 'FEED',
                                icon: Icons.restaurant,
                                onPressed: () async =>
                                    _onFeedPressed(uid, foodStock),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildButton(
                                context,
                                label: 'STORE',
                                icon: Icons.shopping_cart,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const StoreScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(String icon, String label, String value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDarkGrey,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _onSharePressed({
    required int points,
    required int foodStock,
    required int fishCount,
    required double hungerPercent,
  }) async {
    try {
      final bytes = await _captureAquarium();

      final text = '''
🐠 Focus Aquarium
💰 Points: $points
🐟 Fishes: $fishCount/10
🍖 Food: $foodStock
🔋 Hunger: $hungerPercent%
''';

      await Share.shareXFiles([
        XFile.fromData(bytes, mimeType: 'image/png', name: 'aquarium.png'),
      ], text: text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share capture failed: $e')));
    }
  }
}

class HungerBatteryIndicator extends StatelessWidget {
  final double percent;
  const HungerBatteryIndicator({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    final p = percent.clamp(0, 100);
    final color = p >= 60
        ? Colors.lightGreenAccent
        : (p >= 30 ? Colors.amberAccent : Colors.redAccent);

    IconData icon;
    if (p >= 90) {
      icon = Icons.battery_full;
    } else if (p >= 75) {
      icon = Icons.battery_6_bar;
    } else if (p >= 60) {
      icon = Icons.battery_5_bar;
    } else if (p >= 45) {
      icon = Icons.battery_4_bar;
    } else if (p >= 30) {
      icon = Icons.battery_3_bar;
    } else if (p >= 15) {
      icon = Icons.battery_2_bar;
    } else if (p > 0) {
      icon = Icons.battery_1_bar;
    } else {
      icon = Icons.battery_0_bar;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            '$p%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _shareButton({required VoidCallback onTap}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: const Icon(Icons.share, color: Colors.white, size: 20),
      ),
    ),
  );
}
