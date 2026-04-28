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

  String _k(String fishId, int level) => '$fishId@$level';
  int _inv(Map<String, int> inv, String fishId, int level) {
    return inv[_k(fishId, level)] ?? 0;
  }

  int _tankCount(List<String> tank, String fishId, int level) {
    final key = _k(fishId, level);
    return tank.where((x) => x == key).length;
  }

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
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('No profile data')),
          );
        }

        final profile = snapshot.data!;
        final inv = profile.fishInventory;
        final tank = profile.aquariumFish;
        const allFish = FishCatalog.all;
        final totalTypes = allFish.length;

        int collectedTypes = 0;
        for (final f in allFish) {
          final l1 = _inv(inv, f.id, 1);
          final l2 = _inv(inv, f.id, 2);
          if ((l1 + l2) > 0) collectedTypes++;
        }

        final sortedFish = [...allFish]..sort((a, b) {
            final aOwned = (_inv(inv, a.id, 1) + _inv(inv, a.id, 2)) > 0;
            final bOwned = (_inv(inv, b.id, 1) + _inv(inv, b.id, 2)) > 0;
            if (aOwned == bOwned) return a.name.compareTo(b.name);
            return aOwned ? -1 : 1;
          });

        final tankCountAll = tank.length;
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
                    tankCount: tankCountAll,
                    tankMax: tankMax,
                  ),
                  const SizedBox(height: 18),
                  _buildSectionTitle('🐠 Fish Collection'),
                  const SizedBox(height: 12),
                  ...sortedFish.map((fish) {
                    final l1Inv = _inv(inv, fish.id, 1);
                    final l2Inv = _inv(inv, fish.id, 2);
                    final tankL1 = _tankCount(tank, fish.id, 1);
                    final tankL2 = _tankCount(tank, fish.id, 2);

                    return _buildCollectionItemCard(
                      context,
                      firestoreService: firestoreService,
                      uid: user.uid,
                      fish: fish,
                      l1Inv: l1Inv,
                      l2Inv: l2Inv,
                      tankL1: tankL1,
                      tankL2: tankL2,
                      tankCountAll: tankCountAll,
                      tankMax: tankMax,
                    );
                  }),
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
    required int l1Inv,
    required int l2Inv,
    required int tankL1,
    required int tankL2,
    required int tankCountAll,
    required int tankMax,
  }) {
    final unlocked = (l1Inv + l2Inv) > 0;
    final displayIcon = unlocked ? fish.icon : _lockedIcon;
    final displayName = unlocked ? fish.name : _lockedPlaceholder;
    final displayDesc = unlocked ? fish.description : _lockedPlaceholder;

    final freeL1 = (l1Inv - tankL1);
    final freeL2 = (l2Inv - tankL2);

    final safeFreeL1 = freeL1 < 0 ? 0 : freeL1;
    final safeFreeL2 = freeL2 < 0 ? 0 : freeL2;
    final tankNotFull = tankCountAll < tankMax;

    final canAddL1 = unlocked && tankNotFull && safeFreeL1 > 0;
    final canRemoveL1 = tankL1 > 0;

    final canAddL2 = unlocked && tankNotFull && safeFreeL2 > 0;
    final canRemoveL2 = tankL2 > 0;

    final canSynth = safeFreeL1 >= 3;
    final synthTimes = safeFreeL1 ~/ 3;

    return InkWell(
      onTap: () => _showDetailDialog(
        context,
        firestoreService: firestoreService,
        uid: uid,
        fish: fish,
        unlocked: unlocked,
        l1Inv: l1Inv,
        l2Inv: l2Inv,
        tankL1: tankL1,
        tankL2: tankL2,
        tankCountAll: tankCountAll,
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
                      _chip('L1', l1Inv.toString(),
                          bg: Colors.white.withValues(alpha: 0.08)),
                      _chip('L2', l2Inv.toString(),
                          bg: Colors.white.withValues(alpha: 0.08)),
                      _chip('T1', tankL1.toString(),
                          bg: Colors.white.withValues(alpha: 0.08)),
                      _chip('T2', tankL2.toString(),
                          bg: Colors.white.withValues(alpha: 0.08)),
                      _chip('F1', safeFreeL1.toString(),
                          bg: Colors.white.withValues(alpha: 0.08)),
                      _chip('F2', safeFreeL2.toString(),
                          bg: Colors.white.withValues(alpha: 0.08)),
                      if (canSynth)
                        _chip('SYN', '$synthTimes×',
                            bg: Colors.amber.withValues(alpha: 0.16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                _lvlRow(
                  label: 'L1',
                  addEnabled: canAddL1,
                  removeEnabled: canRemoveL1,
                  onAdd: () async {
                    final ok = await firestoreService.addFishToAquariumKey(
                      uid: uid,
                      fishKey: _k(fish.id, 1),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Added ${fish.name} L1 to tank ✅'
                            : 'Cannot add (tank full or no available L1)'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onRemove: () async {
                    final ok = await firestoreService.removeFishFromAquariumKey(
                      uid: uid,
                      fishKey: _k(fish.id, 1),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Removed ${fish.name} L1 from tank ✅'
                            : 'Cannot remove (no L1 in tank)'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _lvlRow(
                  label: 'L2',
                  addEnabled: canAddL2,
                  removeEnabled: canRemoveL2,
                  onAdd: () async {
                    final ok = await firestoreService.addFishToAquariumKey(
                      uid: uid,
                      fishKey: _k(fish.id, 2),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Added ${fish.name} L2 to tank ✅'
                            : 'Cannot add (tank full or no available L2)'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onRemove: () async {
                    final ok = await firestoreService.removeFishFromAquariumKey(
                      uid: uid,
                      fishKey: _k(fish.id, 2),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Removed ${fish.name} L2 from tank ✅'
                            : 'Cannot remove (no L2 in tank)'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _iconActionButton(
                  icon: Icons.auto_fix_high,
                  enabled: canSynth,
                  onPressed: () async {
                    await _confirmAndSynthesize(
                      context,
                      firestoreService: firestoreService,
                      uid: uid,
                      fish: fish,
                      freeL1: safeFreeL1,
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

  Widget _lvlRow({
    required String label,
    required bool addEnabled,
    required bool removeEnabled,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 6),
        _iconActionButton(
          icon: Icons.add,
          enabled: addEnabled,
          onPressed: onAdd,
        ),
        const SizedBox(width: 6),
        _iconActionButton(
          icon: Icons.remove,
          enabled: removeEnabled,
          onPressed: onRemove,
        ),
      ],
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

  Future<void> _confirmAndSynthesize(
    BuildContext context, {
    required FirestoreService firestoreService,
    required String uid,
    required FishBean fish,
    required int freeL1,
  }) async {
    final canSynth = freeL1 >= 3;
    if (!canSynth) return;

    final times = freeL1 ~/ 3;
    final doIt = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Synthesize Fish'),
        content: Text(
          'Use 3× Level 1 ${fish.name} to craft 1× Level 2.\n\n'
          'You can synthesize up to $times time(s) now.\n'
          'Proceed with 1 synthesis?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('SYNTHESIZE'),
          ),
        ],
      ),
    );

    if (doIt != true) return;

    final ok = await firestoreService.synthesizeFish(
      uid: uid,
      fishId: fish.id,
      fromLevel: 1,
      toLevel: 2,
      cost: 3,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Synthesized ${fish.name}: 3×L1 → 1×L2 ✨'
              : 'Synthesis failed (not enough FREE L1)',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context, {
    required FirestoreService firestoreService,
    required String uid,
    required FishBean fish,
    required bool unlocked,
    required int l1Inv,
    required int l2Inv,
    required int tankL1,
    required int tankL2,
    required int tankCountAll,
    required int tankMax,
  }) {
    final rootContext = context;

    final titleIcon = unlocked ? fish.icon : _lockedIcon;
    final titleName = unlocked ? fish.name : _lockedPlaceholder;

    final freeL1 = l1Inv - tankL1;
    final freeL2 = l2Inv - tankL2;

    final safeFreeL1 = freeL1 < 0 ? 0 : freeL1;
    final safeFreeL2 = freeL2 < 0 ? 0 : freeL2;
    final tankNotFull = tankCountAll < tankMax;

    final canAddL1 = unlocked && tankNotFull && safeFreeL1 > 0;
    final canRemoveL1 = tankL1 > 0;

    final canAddL2 = unlocked && tankNotFull && safeFreeL2 > 0;
    final canRemoveL2 = tankL2 > 0;

    final canSynth = safeFreeL1 >= 3;
    final synthTimes = safeFreeL1 ~/ 3;

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
              Text('Inventory L1: $l1Inv'),
              const SizedBox(height: 6),
              Text('In tank L1: $tankL1'),
              Text('In tank L2: $tankL2'),
              const SizedBox(height: 6),
              Text('FREE L1: $safeFreeL1'),
              Text('FREE L2: $safeFreeL2'),
              const SizedBox(height: 10),
              Text('Tank: $tankCountAll/$tankMax'),
              const SizedBox(height: 10),
              Text(
                canSynth
                    ? 'Synthesize available: $synthTimes time(s) (3×L1 → 1×L2)'
                    : 'Need 3× FREE L1 to synthesize 1× L2.',
                style: const TextStyle(fontSize: 12),
              ),
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
              onPressed: canRemoveL1
                  ? () async {
                      final ok =
                          await firestoreService.removeFishFromAquariumKey(
                        uid: uid,
                        fishKey: _k(fish.id, 1),
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Removed ${fish.name} L1 from tank ✅'
                                : 'Cannot remove L1 (not in tank)',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              child: const Text('Remove L1 from Tank'),
            ),
            TextButton(
              onPressed: canAddL1
                  ? () async {
                      final ok = await firestoreService.addFishToAquariumKey(
                        uid: uid,
                        fishKey: _k(fish.id, 1),
                      );

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Added ${fish.name} L1 to tank ✅'
                                : 'Cannot add L1 (tank full or no available fish)',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              child: const Text('Add to L1 Tank'),
            ),
            TextButton(
              onPressed: canRemoveL2
                  ? () async {
                      final ok =
                          await firestoreService.removeFishFromAquariumKey(
                        uid: uid,
                        fishKey: _k(fish.id, 2),
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Removed ${fish.name} L2 from tank ✅'
                              : 'Cannot remove L2'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              child: const Text('Remove L2 from Tank'),
            ),
            TextButton(
              onPressed: canAddL2
                  ? () async {
                      final ok = await firestoreService.addFishToAquariumKey(
                        uid: uid,
                        fishKey: _k(fish.id, 2),
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Added ${fish.name} L2 to tank ✅'
                              : 'Cannot add L2'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              child: const Text('Add L2 to Tank'),
            ),
            TextButton(
              onPressed: canSynth
                  ? () async {
                      Navigator.pop(dialogContext);
                      await _confirmAndSynthesize(
                        rootContext,
                        firestoreService: firestoreService,
                        uid: uid,
                        fish: fish,
                        freeL1: safeFreeL1,
                      );
                    }
                  : null,
              child: const Text('Synthesize (3→1)'),
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
