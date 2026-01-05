import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unlockedCount =
        AppConstants.achievements.where((a) => a['unlocked']).length;
    final totalCount = AppConstants.achievements.length;

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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: AppConstants.achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = AppConstants.achievements[index];
                    return _buildAchievementCard(context, achievement);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(
      BuildContext context, Map<String, dynamic> achievement) {
    final isUnlocked = achievement['unlocked'];

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
                if (!isUnlocked)
                  LinearProgressIndicator(
                    value: achievement['progress'] / achievement['target'],
                    backgroundColor: AppColors.textGrey.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentOrange),
                  ),
                if (!isUnlocked) const SizedBox(height: 8),
                if (!isUnlocked)
                  Text(
                    '${achievement['progress']} / ${achievement['target']}',
                    style: const TextStyle(color: AppColors.textGrey),
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
            // Icon
            Text(
              achievement['icon'],
              style: TextStyle(
                fontSize: 50,
                color: isUnlocked ? null : Colors.grey,
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Progress
            if (!isUnlocked)
              Text(
                '${achievement['progress']}/${achievement['target']}',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
