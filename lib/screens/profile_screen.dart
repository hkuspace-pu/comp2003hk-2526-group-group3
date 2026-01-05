import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';
import 'data_management_screen.dart';
import 'help_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentOrange, width: 3),
                  ),
                  child: const Center(
                    child: Text(
                      '👤',
                      style: TextStyle(fontSize: 50),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Username
                const Text(
                  'Guest User',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Level
                Text(
                  'Level ${AppConstants.defaultLevel}',
                  style: const TextStyle(
                    color: AppColors.accentOrange,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Statistics Card
                _buildCard(
                  title: '📊 Statistics',
                  child: Column(
                    children: [
                      _buildStatRow(
                          'Total Points:', '${AppConstants.defaultPoints}'),
                      const SizedBox(height: 12),
                      _buildStatRow(
                          'Focus Hours:', '${AppConstants.totalFocusHours}h'),
                      const SizedBox(height: 12),
                      _buildStatRow(
                          'Activities:', '${AppConstants.totalActivities}'),
                      const SizedBox(height: 12),
                      _buildStatRow('Current Streak:',
                          '${AppConstants.currentStreak} days'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Aquarium Status Card
                _buildCard(
                  title: '🐠 Aquarium Status',
                  child: Column(
                    children: [
                      _buildStatRow(
                          'Fishes Owned:', '${AppConstants.fishCount} / 10'),
                      const SizedBox(height: 12),
                      _buildStatRow(
                          'Decorations:', '${AppConstants.decorationCount}'),
                      const SizedBox(height: 12),
                      _buildStatRow('Food Stock:', '${AppConstants.foodStock}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Menu Items
                _buildMenuItem(
                  context,
                  icon: Icons.emoji_events,
                  label: 'Achievements',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AchievementsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  icon: Icons.storage,
                  label: 'Data Management',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DataManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  icon: Icons.help,
                  label: 'Help & FAQ',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 16,
          ),
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
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textGrey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
