class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final int totalPoints;
  final int totalFocusMinutes;
  final int sessionCount;
  final int activityCount;
  final int currentStreak;
  final int level;
  final List<String> ownedFish;
  final List<String> ownedDecorations;
  final int foodStock;
  final DateTime createdAt;
  final double hungerPercent;
  final DateTime hungerUpdatedAt;
  final Map<String, int> fishInventory;
  final List<String> aquariumFish;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.totalPoints,
    required this.totalFocusMinutes,
    required this.sessionCount,
    required this.activityCount,
    required this.currentStreak,
    required this.level,
    required this.ownedFish,
    required this.ownedDecorations,
    required this.foodStock,
    required this.createdAt,
    required this.hungerPercent,
    required this.hungerUpdatedAt,
    required this.fishInventory,
    required this.aquariumFish,
  });

  bool get isAdmin => role == 'admin';

  int get totalFishCount =>
      fishInventory.values.fold(0, (s, v) => s + v);

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    final createdAt = data['createdAt']?.toDate() ?? DateTime.now();
    final hungerPercent = (data['hungerPercent'] ?? 100).toDouble();
    final hungerUpdatedAt = data['hungerUpdatedAt']?.toDate() ?? createdAt;
    final ownedFish = List<String>.from(data['ownedFish'] ?? const <String>[]);
    final invRaw = (data['fishInventory'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    final fishInventory = <String, int>{};
    invRaw.forEach((k, v) {
      if (v is int) {
        fishInventory[k] = v;
      } else if (v is num) {
        fishInventory[k] = v.toInt();
      } else {
        fishInventory[k] = 0;
      }
    });

    if (fishInventory.isEmpty && ownedFish.isNotEmpty) {
      for (final id in ownedFish) {
        fishInventory[id] = (fishInventory[id] ?? 0) + 1;
      }
    }

    // fishInventory is the source of truth; rebuild ownedFish from it when the
    // legacy list has drifted (store/lucky paths only touch the inventory).
    final invTotal = fishInventory.values.fold<int>(0, (s, v) => s + v);
    var owned = ownedFish;
    if (fishInventory.isNotEmpty && invTotal != owned.length) {
      owned = [
        for (final e in fishInventory.entries)
          for (var i = 0; i < e.value; i++) e.key.split('@').first,
      ];
    }

    final aquariumFish =
        List<String>.from(data['aquariumFish'] ?? const <String>[]);

    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'User',
      role: data['role'] ?? 'user',
      totalPoints: data['totalPoints'] ?? 0,
      totalFocusMinutes: data['totalFocusMinutes'] ?? 0,
      sessionCount: data['sessionCount'] ?? 0,
      activityCount: data['activityCount'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      level: data['level'] ?? 1,
      ownedFish: owned,
      ownedDecorations: List<String>.from(data['ownedDecorations'] ?? []),
      foodStock: data['foodStock'] ?? 0,
      createdAt: createdAt,
      hungerPercent: hungerPercent.clamp(0, 100).toDouble(),
      hungerUpdatedAt: hungerUpdatedAt,
      fishInventory: fishInventory,
      aquariumFish: aquariumFish,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'totalPoints': totalPoints,
      'totalFocusMinutes': totalFocusMinutes,
      'sessionCount': sessionCount,
      'activityCount': activityCount,
      'currentStreak': currentStreak,
      'level': level,
      'ownedFish': ownedFish,
      'fishInventory': fishInventory,
      'aquariumFish': aquariumFish,
      'ownedDecorations': ownedDecorations,
      'foodStock': foodStock,
      'createdAt': createdAt,
      'hungerPercent': hungerPercent,
      'hungerUpdatedAt': hungerUpdatedAt,
    };
  }

  UserProfile copyWith({
    String? role,
    int? totalPoints,
    int? totalFocusMinutes,
    int? sessionCount,
    int? activityCount,
    int? currentStreak,
    int? level,
    List<String>? ownedFish,
    List<String>? ownedDecorations,
    int? foodStock,
    double? hungerPercent,
    DateTime? hungerUpdatedAt,
    Map<String, int>? fishInventory,
    List<String>? aquariumFish,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role ?? this.role,
      totalPoints: totalPoints ?? this.totalPoints,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      sessionCount: sessionCount ?? this.sessionCount,
      activityCount: activityCount ?? this.activityCount,
      currentStreak: currentStreak ?? this.currentStreak,
      level: level ?? this.level,
      ownedFish: ownedFish ?? this.ownedFish,
      ownedDecorations: ownedDecorations ?? this.ownedDecorations,
      foodStock: foodStock ?? this.foodStock,
      createdAt: createdAt,
      hungerPercent: hungerPercent ?? this.hungerPercent,
      hungerUpdatedAt: hungerUpdatedAt ?? this.hungerUpdatedAt,
      fishInventory: fishInventory ?? this.fishInventory,
      aquariumFish: aquariumFish ?? this.aquariumFish,
    );
  }
}
