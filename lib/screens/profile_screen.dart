import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';
import 'data_management_screen.dart';
import 'help_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<UserProfile?>(
      stream: firestoreService.getUserProfileStream(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = profile?.displayName ?? 'User';
        final level = profile?.level ?? 1;
        final totalPoints = profile?.totalPoints ?? 0;
        final totalFocusHours =
            ((profile?.totalFocusMinutes ?? 0) / 60).toStringAsFixed(1);
        final activityCount = profile?.activityCount ?? 0;
        final currentStreak = profile?.currentStreak ?? 0;
        final fishCount = profile?.ownedFish.length ?? 0;
        final decorationCount = profile?.ownedDecorations.length ?? 0;
        final foodStock = profile?.foodStock ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
          body: GradientBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.accentOrange, width: 3),
                      ),
                      child: const Center(
                        child: Text('🐠', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Username
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Level
                    Text(
                      'Level $level',
                      style: const TextStyle(
                        color: AppColors.accentOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistics Card
                    _buildCard(
                      title: '📊 Statistics',
                      children: [
                        _buildStatRow('Total Points:', '$totalPoints 💰'),
                        _buildStatRow('Focus Hours:', '${totalFocusHours}h ⏱️'),
                        _buildStatRow('Activities:', '$activityCount 🏃'),
                        _buildStatRow('Streak:', '$currentStreak days 🔥'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Aquarium Status Card
                    _buildCard(
                      title: '🐠 Aquarium',
                      children: [
                        _buildStatRow('Fishes Owned:', '$fishCount / 10 🐠'),
                        _buildStatRow('Decorations:', '$decorationCount 🪸'),
                        _buildStatRow('Food Stock:', '$foodStock 🍖'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Menu Items
                    _buildMenuItem(
                      context,
                      icon: Icons.emoji_events,
                      label: 'Achievements',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AchievementsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.storage,
                      label: 'Data Management',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataManagementScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.help,
                      label: 'Help & FAQ',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryDarkGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.accentOrange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.textGrey, size: 16),
          ],
        ),
      ),
    );
  }
}
