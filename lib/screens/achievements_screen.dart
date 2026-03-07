import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  // Define all achievements with their unlock conditions
  List<Map<String, dynamic>> _buildAchievements(UserProfile profile) {
    final focusHours = profile.totalFocusMinutes / 60;
    final sessionCount = profile.sessionCount;
    final activityCount = profile.activityCount;
    final streak = profile.currentStreak;
    final fishCount = profile.ownedFish.length;

    return [
      {
        'id': 'focus_master',
        'name': 'Focus Master',
        'description': 'Complete 10 hours of focus',
        'icon': '🏆',
        'progress': focusHours.clamp(0, 10),
        'target': 10,
        'unlocked': focusHours >= 10,
      },
      {
        'id': 'first_session',
        'name': 'First Step',
        'description': 'Complete your first focus session',
        'icon': '🎯',
        'progress': sessionCount.clamp(0, 1),
        'target': 1,
        'unlocked': sessionCount >= 1,
      },
      {
        'id': 'session_10',
        'name': 'Focused Mind',
        'description': 'Complete 10 focus sessions',
        'icon': '🧠',
        'progress': sessionCount.clamp(0, 10),
        'target': 10,
        'unlocked': sessionCount >= 10,
      },
      {
        'id': 'exercise_champion',
        'name': 'Active Life',
        'description': 'Log 10 off-screen activities',
        'icon': '🏃',
        'progress': activityCount.clamp(0, 10),
        'target': 10,
        'unlocked': activityCount >= 10,
      },
      {
        'id': 'streak_7',
        'name': 'Streak King',
        'description': 'Maintain a 7-day streak',
        'icon': '🔥',
        'progress': streak.clamp(0, 7),
        'target': 7,
        'unlocked': streak >= 7,
      },
      {
        'id': 'streak_30',
        'name': 'Early Bird',
        'description': 'Maintain a 30-day streak',
        'icon': '🌅',
        'progress': streak.clamp(0, 30),
        'target': 30,
        'unlocked': streak >= 30,
      },
      {
        'id': 'aquarium_starter',
        'name': 'Fish Keeper',
        'description': 'Own your first fish',
        'icon': '🐠',
        'progress': fishCount.clamp(0, 1),
        'target': 1,
        'unlocked': fishCount >= 1,
      },
      {
        'id': 'aquarium_master',
        'name': 'Aquarium Master',
        'description': 'Own 5 different fish',
        'icon': '🐟',
        'progress': fishCount.clamp(0, 5),
        'target': 5,
        'unlocked': fishCount >= 5,
      },
      {
        'id': 'points_100',
        'name': 'Point Collector',
        'description': 'Earn 100 total points',
        'icon': '💰',
        'progress': profile.totalPoints.clamp(0, 100),
        'target': 100,
        'unlocked': profile.totalPoints >= 100,
      },
      {
        'id': 'points_1000',
        'name': 'Point Master',
        'description': 'Earn 1,000 total points',
        'icon': '💎',
        'progress': profile.totalPoints.clamp(0, 1000),
        'target': 1000,
        'unlocked': profile.totalPoints >= 1000,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<UserProfile?>(
      stream: firestoreService.getUserProfileStream(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.accentOrange,
              ),
            ),
          );
        }

        final profile = snapshot.data!;
        final achievements = _buildAchievements(profile);
        final unlockedCount = achievements.where((a) => a['unlocked']).length;
        final totalCount = achievements.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Achievements'),
          ),
          body: GradientBackground(
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Progress: ',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '$unlockedCount / $totalCount unlocked',
                            style: const TextStyle(
                              color: AppColors.accentOrange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Achievements Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: achievements.length,
                      itemBuilder: (context, index) {
                        return _buildAchievementCard(
                            context, achievements[index]);
                      },
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

  Widget _buildAchievementCard(
      BuildContext context, Map<String, dynamic> achievement) {
    final isUnlocked = achievement['unlocked'] as bool;
    final progress = (achievement['progress'] as num).toDouble();
    final target = (achievement['target'] as num).toDouble();

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.primaryDarkGrey,
            title: Text(
              achievement['name'],
              style: const TextStyle(color: AppColors.textWhite),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  achievement['icon'],
                  style: const TextStyle(fontSize: 60),
                ),
                const SizedBox(height: 16),
                Text(
                  achievement['description'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textGrey),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (progress / target).clamp(0.0, 1.0),
                  backgroundColor: AppColors.textGrey.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUnlocked ? Colors.green : AppColors.accentOrange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isUnlocked
                      ? '✅ Unlocked!'
                      : '${progress.toStringAsFixed(progress % 1 == 0 ? 0 : 1)} / ${target.toInt()}',
                  style: TextStyle(
                    color: isUnlocked ? Colors.green : AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked ? AppColors.accentOrange : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with opacity if locked
            Opacity(
              opacity: isUnlocked ? 1.0 : 0.4,
              child: Text(
                achievement['icon'],
                style: const TextStyle(fontSize: 36),
              ),
            ),
            const SizedBox(height: 8),

            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                achievement['name'],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isUnlocked ? AppColors.textWhite : AppColors.textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Progress
            if (!isUnlocked)
              Text(
                '${progress.toStringAsFixed(progress % 1 == 0 ? 0 : 1)}/${target.toInt()}',
                style: const TextStyle(
                  color: AppColors.accentOrange,
                  fontSize: 10,
                ),
              )
            else
              const Text(
                '✅',
                style: TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
