import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import 'aquarium_screen.dart';
import 'store_screen.dart';

class PurchaseSuccessScreen extends StatelessWidget {
  final String itemId;
  final int remainingPoints;

  const PurchaseSuccessScreen({
    Key? key,
    required this.itemId,
    required this.remainingPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final item = AppConstants.storeItems[itemId]!;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icons
                const Text('🎉 ✨ 🎉', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Purchase Successful!',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // Item Icon
                Text(item['icon'], style: const TextStyle(fontSize: 80)),
                const SizedBox(height: 16),

                // Item Name
                Text(
                  item['name'],
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'has been added to your aquarium!',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // Remaining Points
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Remaining Points:',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$remainingPoints 💰',
                        style: const TextStyle(
                          color: AppColors.accentOrange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Go to Aquarium Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AquariumScreen(),
                        ),
                        (route) => false,
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
                      backgroundColor: AppColors.accentOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Continue Shopping Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StoreScreen(),
                        ),
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
                      'CONTINUE SHOPPING',
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
