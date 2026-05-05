import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';
import 'aquarium/fish_types.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  static const String _lockedIcon = '❓';
  static const String _lockedPlaceholder = '???';

  int _selectedLevel = 1;

  String _k(String fishId, int level) => '$fishId@$level';

  int _inv(Map<String, int> inv, String fishId, int level) {
    return inv[_k(fishId, level)] ?? 0;
  }

  int _aquariumCount(List<String> aquarium, String fishId, int level) {
    final key = _k(fishId, level);
    return aquarium.where((x) => x == key).length;
  }

  int _collectedVariantsCount(Map<String, int> inv, List<FishBean> allFish) {
    int collected = 0;
    for (final f in allFish) {
      for (final lv in const [1, 2, 3]) {
        if (_inv(inv, f.id, lv) > 0) collected++;
      }
    }
    return collected;
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
        final aquarium = profile.aquariumFish;

        const allFish = FishCatalog.all;

        final totalVariants = allFish.length * 3;
        final collectedVariants = _collectedVariantsCount(inv, allFish);

        final pct = totalVariants == 0
            ? 0
            : ((collectedVariants / totalVariants) * 100).round();

        final sortedFish = [...allFish]..sort((a, b) {
            final aUnlocked =
                (_inv(inv, a.id, 1) + _inv(inv, a.id, 2) + _inv(inv, a.id, 3)) >
                    0;
            final bUnlocked =
                (_inv(inv, b.id, 1) + _inv(inv, b.id, 2) + _inv(inv, b.id, 3)) >
                    0;
            if (aUnlocked != bUnlocked) return aUnlocked ? -1 : 1;
            return a.name.compareTo(b.name);
          });

        final aquariumCountAll = aquarium.length;
        const aquariumMax = FirestoreService.maxAquariumFish;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Collection'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _percentChip(pct),
                  ],
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
                    collectedVariants: collectedVariants,
                    totalVariants: totalVariants,
                    aquariumCount: aquariumCountAll,
                    aquariumMax: aquariumMax,
                    onSelect: () => _showSelectDialog(
                      context,
                      firestoreService: firestoreService,
                      uid: user.uid,
                      allFish: allFish,
                      inv: inv,
                      aquarium: aquarium,
                      aquariumMax: aquariumMax,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _LevelToggle(
                    value: _selectedLevel,
                    onChanged: (v) => setState(() => _selectedLevel = v),
                  ),
                  const SizedBox(height: 14),
                  ...sortedFish.map((fish) {
                    final l1Inv = _inv(inv, fish.id, 1);
                    final l2Inv = _inv(inv, fish.id, 2);
                    final l3Inv = _inv(inv, fish.id, 3);

                    final aquariumL1 = _aquariumCount(aquarium, fish.id, 1);
                    final aquariumL2 = _aquariumCount(aquarium, fish.id, 2);
                    final aquariumL3 = _aquariumCount(aquarium, fish.id, 3);

                    return _buildFishCard(
                      context,
                      firestoreService: firestoreService,
                      uid: user.uid,
                      fish: fish,
                      selectedLevel: _selectedLevel,
                      l1Inv: l1Inv,
                      l2Inv: l2Inv,
                      l3Inv: l3Inv,
                      aquariumL1: aquariumL1,
                      aquariumL2: aquariumL2,
                      aquariumL3: aquariumL3,
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
    required int collectedVariants,
    required int totalVariants,
    required int aquariumCount,
    required int aquariumMax,
    required VoidCallback onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const Text('📖', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collected $collectedVariants of $totalVariants types',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aquarium Displaying: $aquariumCount/$aquariumMax',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'SELECT',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _percentChip(int pct) {
    return Container(
      padding: const EdgeInsets.all(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '📚 $pct%',
          style: const TextStyle(
            color: AppColors.accentOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFishCard(
    BuildContext context, {
    required FirestoreService firestoreService,
    required String uid,
    required FishBean fish,
    required int selectedLevel,
    required int l1Inv,
    required int l2Inv,
    required int l3Inv,
    required int aquariumL1,
    required int aquariumL2,
    required int aquariumL3,
  }) {
    final totalInvAllLevels = l1Inv + l2Inv + l3Inv;
    final unlocked = totalInvAllLevels > 0;

    final displayIcon = unlocked ? fish.icon : _lockedIcon;
    final displayName = unlocked ? fish.name : _lockedPlaceholder;
    final displayDesc = unlocked ? fish.description : _lockedPlaceholder;

    int invSel;
    int aquariumSel;
    if (selectedLevel == 1) {
      invSel = l1Inv;
      aquariumSel = aquariumL1;
    } else if (selectedLevel == 2) {
      invSel = l2Inv;
      aquariumSel = aquariumL2;
    } else {
      invSel = l3Inv;
      aquariumSel = aquariumL3;
    }

    final freeSel = invSel - aquariumSel;
    final safeFreeSel = freeSel < 0 ? 0 : freeSel;

    const evolveCost = 3;
    final canEvolve =
        unlocked && selectedLevel < 3 && safeFreeSel >= evolveCost;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(displayIcon, style: const TextStyle(fontSize: 46)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayDesc,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Owned : $invSel',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedLevel < 3) ...[
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: canEvolve
                      ? () async {
                          await _confirmAndEvolve(
                            context,
                            firestoreService: firestoreService,
                            uid: uid,
                            fish: fish,
                            fromLevel: selectedLevel,
                            toLevel: selectedLevel + 1,
                            freeCount: safeFreeSel,
                            cost: evolveCost,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size.fromHeight(48),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.center,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      height: 1.0,
                      fontSize: 14,
                    ),
                  ),
                  child: const Text('EVOLVE'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndEvolve(
    BuildContext context, {
    required FirestoreService firestoreService,
    required String uid,
    required FishBean fish,
    required int fromLevel,
    required int toLevel,
    required int freeCount,
    required int cost,
  }) async {
    final canEvolve = fromLevel < 3 && freeCount >= cost;
    if (!canEvolve) return;

    final times = freeCount ~/ cost;

    final doIt = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Evolution'),
        content: Text(
          'Use $cost× LV$fromLevel ${fish.name} to craft 1× LV$toLevel.\n\n'
          'You can evolve up to $times time(s) now.\n'
          'Proceed with 1 evolution?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('EVOLVE'),
          ),
        ],
      ),
    );

    if (doIt != true) return;

    final ok = await firestoreService.synthesizeFish(
      uid: uid,
      fishId: fish.id,
      fromLevel: fromLevel,
      toLevel: toLevel,
      cost: cost,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Evolution success: ${fish.name} ($cost×LV$fromLevel → 1×LV$toLevel) ✨'
              : 'Evolution failed (need $cost× FREE LV$fromLevel)',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showSelectDialog(
    BuildContext context, {
    required FirestoreService firestoreService,
    required String uid,
    required List<FishBean> allFish,
    required Map<String, int> inv,
    required List<String> aquarium,
    required int aquariumMax,
  }) async {
    final invLocal = Map<String, int>.from(inv);
    final aquariumLocal = List<String>.from(aquarium);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setLocalState) {
            int aquariumCountAll = aquariumLocal.length;

            List<_VariantRow> rows = [];
            for (final f in allFish) {
              for (final lv in const [1, 2, 3]) {
                final key = _k(f.id, lv);
                final invCount = invLocal[key] ?? 0;
                final inAq = aquariumLocal.where((x) => x == key).length;
                if (invCount == 0 && inAq == 0) continue;
                final free = invCount - inAq;
                rows.add(_VariantRow(
                  fish: f,
                  level: lv,
                  key: key,
                  invCount: invCount,
                  inAquarium: inAq,
                  free: free < 0 ? 0 : free,
                ));
              }
            }

            rows.sort((a, b) {
              final aSel = a.free > 0;
              final bSel = b.free > 0;
              if (aSel != bSel) return aSel ? -1 : 1;
              final c = a.fish.name.compareTo(b.fish.name);
              if (c != 0) return c;
              return a.level.compareTo(b.level);
            });

            return AlertDialog(
              title: const Text('Select Fish to Display'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Aquarium: $aquariumCountAll/$aquariumMax',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (aquariumCountAll >= aquariumMax)
                          const Text(
                            'FULL',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 420,
                      child: rows.isEmpty
                          ? const Center(child: Text('No owned fish yet.'))
                          : ListView.separated(
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (c, i) {
                                final r = rows[i];
                                final canAdd = r.free > 0 &&
                                    aquariumCountAll < aquariumMax;
                                final canRemove = r.inAquarium > 0;

                                return ListTile(
                                  leading: Text(r.fish.icon,
                                      style: const TextStyle(fontSize: 28)),
                                  title:
                                      Text('${r.fish.name}  •  LV${r.level}'),
                                  subtitle: Text(
                                    'Owned: ${r.invCount}   In Aquarium: ${r.inAquarium}   Free: ${r.free}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        onPressed: canRemove
                                            ? () async {
                                                final ok = await firestoreService
                                                    .removeFishFromAquariumKey(
                                                  uid: uid,
                                                  fishKey: r.key,
                                                );
                                                if (!dialogContext.mounted) {
                                                  return;
                                                }
                                                if (ok) {
                                                  final idx = aquariumLocal
                                                      .lastIndexOf(r.key);
                                                  if (idx != -1) {
                                                    aquariumLocal.removeAt(idx);
                                                  }
                                                  setLocalState(() {});
                                                }
                                              }
                                            : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                        onPressed: canAdd
                                            ? () async {
                                                final ok =
                                                    await firestoreService
                                                        .addFishToAquariumKey(
                                                  uid: uid,
                                                  fishKey: r.key,
                                                );
                                                if (!dialogContext.mounted) {
                                                  return;
                                                }
                                                if (ok) {
                                                  aquariumLocal.add(r.key);
                                                  setLocalState(() {});
                                                }
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _VariantRow {
  _VariantRow({
    required this.fish,
    required this.level,
    required this.key,
    required this.invCount,
    required this.inAquarium,
    required this.free,
  });

  final FishBean fish;
  final int level;
  final String key;
  final int invCount;
  final int inAquarium;
  final int free;
}

class _LevelToggle extends StatelessWidget {
  const _LevelToggle({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGrey.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.textWhite.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TogglePill(
              label: 'LV1',
              selected: value == 1,
              selectedColor: AppColors.accentOrange,
              onTap: () => onChanged(1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TogglePill(
              label: '⭐  LV2',
              selected: value == 2,
              selectedColor: AppColors.accentOrange,
              onTap: () => onChanged(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TogglePill(
              label: '👑  LV3',
              selected: value == 3,
              selectedColor: AppColors.accentOrange,
              onTap: () => onChanged(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor
              : AppColors.primaryDarkGrey.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
