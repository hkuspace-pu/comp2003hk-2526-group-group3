import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';
import 'aquarium_screen.dart';
import 'store_screen.dart';

class PurchaseSuccessScreen extends StatelessWidget {
  final String itemName;
  final String itemIcon;
  final int itemPrice;

  const PurchaseSuccessScreen({
    Key? key,
    required this.itemName,
    required this.itemIcon,
    required this.itemPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remaining = 24000 - itemPrice;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icons
                const Text(
                  '✨ 🎉 ✨',
                  style: TextStyle(fontSize: 60),
                ),
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
                Text(
                  itemIcon,
                  style: const TextStyle(fontSize: 100),
                ),
                const SizedBox(height: 24),

                // Item Name
                Text(
                  '$itemName added to aquarium!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 24),

                // Remaining Points
                Text(
                  'Remaining Points: $remaining 💰',
                  style: const TextStyle(
                    color: AppColors.accentOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 60),

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
                        (route) => route.isFirst,
                      );
                    },
                    icon: const Icon(Icons.water),
                    label: const Text(
                      'GO TO AQUARIUM',
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

                // Continue Shopping Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StoreScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text(
                      'CONTINUE SHOPPING',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textWhite,
                      side: const BorderSide(
                          color: AppColors.textWhite, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
