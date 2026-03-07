import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import 'purchase_confirm_screen.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aquarium Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '💰 ${AppConstants.defaultPoints}',
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
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Fishes Section
                    _buildSectionTitle('🐠 Fish'),
                    const SizedBox(height: 12),
                    _buildStoreItem(context, 'clownfish'),
                    _buildStoreItem(context, 'goldfish'),
                    _buildStoreItem(context, 'shrimp'),
                    _buildStoreItem(context, 'pufferfish'),
                    const SizedBox(height: 24),

                    // Food Section
                    _buildSectionTitle('🍖 Food'),
                    const SizedBox(height: 12),
                    _buildStoreItem(context, 'food'),
                    const SizedBox(height: 24),

                    // Decorations Section
                    _buildSectionTitle('🌿 Decorations'),
                    const SizedBox(height: 12),
                    _buildStoreItem(context, 'seaweed'),
                    _buildStoreItem(context, 'coral'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textWhite,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStoreItem(BuildContext context, String itemId) {
    final item = AppConstants.storeItems[itemId]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Text(
            item['icon'],
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(width: 16),

          // Name
          Expanded(
            child: Text(
              item['name'],
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Price
          Text(
            '${item['price']} 💰',
            style: const TextStyle(
              color: AppColors.accentOrange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),

          // Buy Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PurchaseConfirmScreen(
                    itemId: itemId,
                    itemPrice: item['price'],
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'BUY',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
