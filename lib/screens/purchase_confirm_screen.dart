import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import '../services/firestore_service.dart';
import 'purchase_success_screen.dart';

class PurchaseConfirmScreen extends StatefulWidget {
  final String itemId;
  final int itemPrice;

  const PurchaseConfirmScreen({
    Key? key,
    required this.itemId,
    required this.itemPrice,
  }) : super(key: key);

  @override
  State<PurchaseConfirmScreen> createState() => _PurchaseConfirmScreenState();
}

class _PurchaseConfirmScreenState extends State<PurchaseConfirmScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  bool _isPurchasing = false;
  int _currentPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profile = await _firestoreService.getUserProfile(user.uid);
    if (mounted) {
      setState(() {
        _currentPoints = profile?.totalPoints ?? 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmPurchase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isPurchasing = true);

    final item = AppConstants.storeItems[widget.itemId]!;
    final isFish = ['clownfish', 'goldfish', 'shrimp', 'pufferfish']
        .contains(widget.itemId);
    final isDecoration = ['seaweed', 'coral'].contains(widget.itemId);
    final isFood = widget.itemId == 'food';

    final success = await _firestoreService.purchaseItem(
      uid: user.uid,
      itemKey: widget.itemId,
      price: widget.itemPrice,
      isFish: isFish,
      isDecoration: isDecoration,
      isFood: isFood,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PurchaseSuccessScreen(
            itemId: widget.itemId,
            remainingPoints: _currentPoints - widget.itemPrice,
          ),
        ),
      );
    } else {
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough points!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = AppConstants.storeItems[widget.itemId]!;
    final remaining = _currentPoints - widget.itemPrice;
    final canAfford = remaining >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Purchase'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentOrange,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Item Icon
                      Text(
                        item['icon'],
                        style: const TextStyle(fontSize: 80),
                      ),
                      const SizedBox(height: 16),

                      // Item Name
                      Text(
                        item['name'],
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Price Info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildRow('Price:', '${widget.itemPrice} 💰'),
                            const Divider(color: AppColors.textGrey),
                            _buildRow('Your Points:', '$_currentPoints 💰'),
                            const Divider(color: AppColors.textGrey),
                            _buildRow(
                              'After Purchase:',
                              '$remaining 💰',
                              valueColor:
                                  canAfford ? AppColors.textWhite : Colors.red,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Confirm Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (canAfford && !_isPurchasing)
                              ? _confirmPurchase
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isPurchasing
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'CONFIRM PURCHASE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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

                      // Not enough points warning
                      if (!canAfford) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Not enough points! Complete more focus sessions or activities to earn points.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
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

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 16)),
          Text(value,
              style: TextStyle(
                color: valueColor ?? AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}
