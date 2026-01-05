import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import 'purchase_success_screen.dart';

class PurchaseConfirmScreen extends StatelessWidget {
  final String itemId;
  final String itemName;
  final String itemIcon;
  final int itemPrice;

  const PurchaseConfirmScreen({
    Key? key,
    required this.itemId,
    required this.itemName,
    required this.itemIcon,
    required this.itemPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remaining = AppConstants.defaultPoints - itemPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Confirmation'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Item Icon
                Text(
                  itemIcon,
                  style: const TextStyle(fontSize: 100),
                ),
                const SizedBox(height: 24),

                // Item Name
                Text(
                  itemName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // Price Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow('Price:', '$itemPrice 💰'),
                      const SizedBox(height: 12),
                      _buildPriceRow(
                          'Your Points:', '${AppConstants.defaultPoints} 💰'),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.textGrey),
                      const SizedBox(height: 12),
                      _buildPriceRow(
                        'After Purchase:',
                        '$remaining 💰',
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: remaining >= 0
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PurchaseSuccessScreen(
                                  itemName: itemName,
                                  itemIcon: itemIcon,
                                  itemPrice: itemPrice,
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      'CONFIRM PURCHASE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGrey,
                      disabledBackgroundColor: AppColors.textGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textWhite,
                      side: const BorderSide(
                          color: AppColors.textWhite, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Warning if not enough points
                if (remaining < 0) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Not enough points!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight ? AppColors.textWhite : AppColors.textGrey,
            fontSize: isHighlight ? 18 : 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? AppColors.accentOrange : AppColors.textWhite,
            fontSize: isHighlight ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
