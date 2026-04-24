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
        final profile = snapshot.data!;
        final inv = profile.fishInventory;
        final tank = profile.aquariumFish;
        const allFish = FishCatalog.all;
        final totalTypes = allFish.length;

        int collectedTypes = 0;
        for (final f in allFish) {
          if ((inv[f.id] ?? 0) > 0) collectedTypes++;
        }

        final sortedFish = [...allFish]..sort((a, b) {
            final ao = (inv[a.id] ?? 0) > 0;
            final bo = (inv[b.id] ?? 0) > 0;
            if (ao == bo) return a.name.compareTo(b.name);
            return ao ? -1 : 1;
          });

        final tankCount = tank.length;
        const tankMax = FirestoreService.maxAquariumFish;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Collection'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '📚 $collectedTypes/$totalTypes',
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
                    collectedTypes: collectedTypes,
                    totalTypes: totalTypes,
                    tankCount: tankCount,
                    tankMax: tankMax,
                  ),
                  const SizedBox(height: 18),
                  _buildSectionTitle('🐠 Fish Collection'),
                  const SizedBox(height: 12),
                  ...sortedFish.map(
                    (fish) => _buildCollectionItemCard(
                      context,
                      firestoreService: firestoreService,
                      uid: user.uid,
                      fish: fish,
                      invCount: inv[fish.id] ?? 0,
                      tankCountForThis: tank.where((x) => x == fish.id).length,
                      tankMax: tankMax,
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

  Widget _buildHeaderSummary({
    required int collectedTypes,
    required int totalTypes,
    required int tankCount,
    required int tankMax,
  }) {
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
                  'Collected $collectedTypes of $totalTypes types',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tank: $tankCount/$tankMax',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _buildProgressChip(collectedTypes, totalTypes),
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
    required FirestoreService firestoreService,
    required String uid,
    required FishBean fish,
    required int invCount,
    required int tankCountForThis,
    required int tankMax,
  }) {
    final unlocked = invCount > 0;
    final displayIcon = unlocked ? fish.icon : _lockedIcon;
    final displayName = unlocked ? fish.name : _lockedPlaceholder;
    final displayDesc = unlocked ? fish.description : _lockedPlaceholder;

    final availableToAdd = invCount - tankCountForThis;
    final canAdd = unlocked && availableToAdd > 0;
    final canRemove = tankCountForThis > 0;

    return InkWell(
      onTap: () => _showDetailDialog(
        context,
        firestoreService: firestoreService,
        uid: uid,
        fish: fish,
        unlocked: unlocked,
        invCount: invCount,
        tankCountForThis: tankCountForThis,
        tankMax: tankMax,
      ),
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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('INV', invCount.toString(),
                          bg: Colors.white.withValues(alpha: 0.08)),
                      _chip('TANK', tankCountForThis.toString(),
                          bg: Colors.white.withValues(alpha: 0.08)),
                      _chip('FREE',
                          (availableToAdd < 0 ? 0 : availableToAdd).toString(),
                          bg: Colors.white.withValues(alpha: 0.08)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                _iconActionButton(
                  icon: Icons.add,
                  enabled: canAdd,
                  onPressed: () async {
                    final ok = await firestoreService.addFishToAquarium(
                      uid: uid,
                      fishId: fish.id,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Added ${fish.name} to tank ✅'
                            : 'Cannot add (tank full or no available fish)'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _iconActionButton(
                  icon: Icons.remove,
                  enabled: canRemove,
                  onPressed: () async {
                    final ok = await firestoreService.removeFishFromAquarium(
                      uid: uid,
                      fishId: fish.id,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Removed ${fish.name} from tank ✅'
                            : 'Cannot remove (not in tank)'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, {required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: AppColors.textWhite,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _iconActionButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context, {
    required FirestoreService firestoreService,
    required String uid,
    required FishBean fish,
    required bool unlocked,
    required int invCount,
    required int tankCountForThis,
    required int tankMax,
  }) {
    final rootContext = context;

    final titleIcon = unlocked ? fish.icon : _lockedIcon;
    final titleName = unlocked ? fish.name : _lockedPlaceholder;
    final availableToAddRaw = invCount - tankCountForThis;
    final availableToAdd = availableToAddRaw < 0 ? 0 : availableToAddRaw;

    final canAdd = unlocked && availableToAdd > 0;
    final canRemove = tankCountForThis > 0;

    showDialog(
      context: rootContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Text(titleIcon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(child: Text(titleName)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(unlocked ? fish.description : _lockedPlaceholder),
              const SizedBox(height: 14),
              Text('Inventory: $invCount'),
              Text('In tank: $tankCountForThis'),
              Text('Available: $availableToAdd'),
              const SizedBox(height: 8),
              Text('Tank capacity: $tankMax'),
              if (!unlocked) ...[
                const SizedBox(height: 12),
                const Text(
                  'This fish is locked. Buy it in the Store to add to your inventory.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: canRemove
                  ? () async {
                      final ok = await firestoreService.removeFishFromAquarium(
                        uid: uid,
                        fishId: fish.id,
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Removed ${fish.name} from tank ✅'
                                : 'Cannot remove (not in tank)',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              child: const Text('Remove from Tank'),
            ),
            TextButton(
              onPressed: canAdd
                  ? () async {
                      final ok = await firestoreService.addFishToAquarium(
                        uid: uid,
                        fishId: fish.id,
                      );

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Added ${fish.name} to tank ✅'
                                : 'Cannot add (tank full or no available fish)',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              child: const Text('Add to Tank'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
