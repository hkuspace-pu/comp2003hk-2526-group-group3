import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import 'aquarium_screen.dart';
import 'dashboard_screen.dart';

class FocusCompleteScreen extends StatelessWidget {
  final int duration;

  const FocusCompleteScreen({
    Key? key,
    required this.duration,
  }) : super(key: key);

  int _calculatePoints() {
    // 1 min = 2 points + bonus
    int basePoints = duration * 2;
    int bonus = 10; // completion bonus
    if (duration >= 25) bonus += 10;
    if (duration >= 60) bonus += 10;
    return basePoints + bonus;
  }

  @override
  Widget build(BuildContext context) {
    final points = _calculatePoints();
    final newTotal = AppConstants.defaultPoints + points;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stars
                const Text(
                  '⭐ ✨ ⭐',
                  style: TextStyle(fontSize: 60),
                ),
                const SizedBox(height: 24),

                // Congratulations
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Duration
                Text(
                  'You focused for $duration min',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 40),

                // Points Earned
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '+$points 💰',
                        style: const TextStyle(
                          color: AppColors.accentOrange,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Points!',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Total Points
                Text(
                  'Total Points: $newTotal',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 60),

                // View Aquarium Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AquariumScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.water),
                    label: const Text(
                      'VIEW AQUARIUM',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textWhite,
                      side: const BorderSide(
                          color: AppColors.textWhite, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontSize: 16,
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
    );
  }
}
