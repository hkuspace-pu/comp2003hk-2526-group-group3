import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';
import 'aquarium/fish_types.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({Key? key}) : super(key: key);
  static const String _lockedIcon = '❓';
  static const String _lockedPlaceholder = '???';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return StreamBuilder<UserProfile?>(
      stream: firestoreService.getUserProfileStream(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        final ownedFish = List<String>.from(profile?.ownedFish ?? const []);
        final allFish = FishCatalog.all;

        final totalCollectibles = allFish.length;
        final collectedCount = _countOwned(allFish, ownedFish);

        final sortedFish = [...allFish]..sort((a, b) {
            final ao = ownedFish.contains(a.id);
            final bo = ownedFish.contains(b.id);
            if (ao == bo) return a.name.compareTo(b.name);
            return ao ? -1 : 1;
          });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Collection'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '📚 $collectedCount/$totalCollectibles',
                    style: const TextStyle(
                      fontSize: 16,
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
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeaderSummary(
                    collectedCount: collectedCount,
                    total: totalCollectibles,
                  ),
                  const SizedBox(height: 18),
                  _buildSectionTitle('🐠 Fish Collection'),
                  const SizedBox(height: 12),
                  ...sortedFish.map(
                    (fish) => _buildCollectionItemCard(
                      context,
                      fish: fish,
                      owned: ownedFish.contains(fish.id),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _countOwned(List<FishBean> items, List<String> ownedIds) {
    int count = 0;
    for (final i in items) {
      if (ownedIds.contains(i.id)) count++;
    }
    return count;
  }

  Widget _buildHeaderSummary(
      {required int collectedCount, required int total}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('📖', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Collection',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Collected $collectedCount of $total items',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _buildProgressChip(collectedCount, total),
        ],
      ),
    );
  }

  Widget _buildProgressChip(int collected, int total) {
    final progress = total == 0 ? 0 : (collected / total);
    final pct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGrey.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$pct%',
        style: const TextStyle(
          color: AppColors.textWhite,
          fontWeight: FontWeight.bold,
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

  Widget _buildCollectionItemCard(
    BuildContext context, {
    required FishBean fish,
    required bool owned,
  }) {
    final displayIcon = owned ? fish.icon : _lockedIcon;
    final displayName = owned ? fish.name : _lockedPlaceholder;
    final displayDesc = owned ? fish.description : _lockedPlaceholder;

    return InkWell(
      onTap: () => _showDetailDialog(context, fish: fish, owned: owned),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(displayIcon, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayDesc,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildOwnedBadge(owned),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnedBadge(bool owned) {
    final bg = owned
        ? Colors.green.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.10);
    final fg = owned ? Colors.greenAccent : AppColors.textGrey;
    final text = owned ? 'OWNED' : 'LOCKED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: fg.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context, {
    required FishBean fish,
    required bool owned,
  }) {
    final titleIcon = owned ? fish.icon : _lockedIcon;
    final titleName = owned ? fish.name : _lockedPlaceholder;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Text(titleIcon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(child: Text(titleName)),
          ],
        ),
        content: Text(
          owned ? fish.description : _lockedPlaceholder,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
