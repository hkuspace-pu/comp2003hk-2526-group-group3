import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import 'achievements_screen.dart';
import 'data_management_screen.dart';
import 'help_screen.dart';
import 'privacy_policy_screen.dart';
import 'settings_screen.dart';
import 'terms_of_use_screen.dart';

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
        final totalPoints = profile?.totalPoints ?? 0;
        // level off live points so store/lucky spend updates it immediately
        final level = firestoreService.calculateLevel(totalPoints);
        final totalFocusHours =
            ((profile?.totalFocusMinutes ?? 0) / 60).toStringAsFixed(1);
        final activityCount = profile?.activityCount ?? 0;
        final currentStreak = profile?.currentStreak ?? 0;
        final inv = profile?.fishInventory ?? const <String, int>{};
        final fishCount = profile?.totalFishCount ?? 0;
        final decorationCount = profile?.ownedDecorations.length ?? 0;
        final foodStock = profile?.foodStock ?? 0;

        // collapse "goldfish@1" / "goldfish@2" / ... into one row per species
        final counts = <String, int>{};
        for (final e in inv.entries) {
          final id = e.key.split('@').first;
          counts[id] = (counts[id] ?? 0) + e.value;
        }

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
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level $level',
                      style: const TextStyle(
                        color: AppColors.accentOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    _buildCard(
                      title: '🐠 Aquarium',
                      children: [
                        _buildStatRow('Total Owned:', '$fishCount / 10 🐠'),
                        _buildStatRow('Decorations:', '$decorationCount 🪸'),
                        _buildStatRow('Food Stock:', '$foodStock 🍖'),
                        if (counts.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.textGrey, height: 1),
                          const SizedBox(height: 12),
                          const Text(
                            'Fish Breakdown',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._buildSpeciesRows(counts),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.privacy_tip,
                      label: 'Privacy Policy',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.description,
                      label: 'Terms of Use',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsOfUseScreen(),
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

  List<Widget> _buildSpeciesRows(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries)
        _buildStatRow(
          '${(AppConstants.storeItems[e.key]?['icon'] as String?) ?? '🐟'}  '
              '${(AppConstants.storeItems[e.key]?['name'] as String?) ?? _cap(e.key)}',
          '× ${e.value}',
        ),
    ];
  }

  String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

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
