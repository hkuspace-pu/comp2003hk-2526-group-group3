import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';
import 'store_screen.dart';
import 'aquarium/animated_aquarium.dart';

class AquariumScreen extends StatefulWidget {
  const AquariumScreen({Key? key}) : super(key: key);

  @override
  State<AquariumScreen> createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AnimatedAquariumController _controller = AnimatedAquariumController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<UserProfile?>(
      stream: _firestoreService.getUserProfileStream(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final points = profile?.totalPoints ?? 0;
        final fishCount = profile?.ownedFish.length ?? 0;
        final foodStock = profile?.foodStock ?? 0;

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
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          height: 400,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0077BE).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.textWhite.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: AnimatedAquarium(
                            controller: _controller,
                            fishCount: fishCount,
                            fishEmojiTypes: const ['🐠', '🐟', '🦐'],
                            overlayChild: Stack(
                              children: const [
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Center(
                                      child: Text(
                                        '~~~~ Water Surface ~~~~',
                                        style: TextStyle(
                                          color: AppColors.textGrey,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                    left: 16,
                                    bottom: 26,
                                    child: Text('🌿',
                                        style: TextStyle(fontSize: 36))),
                                Positioned(
                                    left: 72,
                                    bottom: 28,
                                    child: Text('🪨',
                                        style: TextStyle(fontSize: 28))),
                                Positioned(
                                    right: 24,
                                    bottom: 32,
                                    child: Text('🪸',
                                        style: TextStyle(fontSize: 34))),
                              ],
                            ),
                          ),
                        ),

                        // Stats
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
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

                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildButton(
                            context,
                            label: 'FEED',
                            icon: Icons.restaurant,
                            onPressed: foodStock > 0
                                ? () {
                                    _controller.burstBubbles();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Fed fish! 🐟'),
                                          duration: Duration(seconds: 2)),
                                    );
                                  }
                                : null,
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
                                    builder: (context) => const StoreScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
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
        Text(label,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null
            ? AppColors.primaryDarkGrey
            : AppColors.primaryDarkGrey.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
