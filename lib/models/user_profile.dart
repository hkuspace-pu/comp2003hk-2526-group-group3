class UserProfile {
  final String uid;
  final String email;
  final String displayName;
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

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
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
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'User',
      totalPoints: data['totalPoints'] ?? 0,
      totalFocusMinutes: data['totalFocusMinutes'] ?? 0,
      sessionCount: data['sessionCount'] ?? 0,
      activityCount: data['activityCount'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      level: data['level'] ?? 1,
      ownedFish: List<String>.from(data['ownedFish'] ?? []),
      ownedDecorations: List<String>.from(data['ownedDecorations'] ?? []),
      foodStock: data['foodStock'] ?? 0,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'totalPoints': totalPoints,
      'totalFocusMinutes': totalFocusMinutes,
      'sessionCount': sessionCount,
      'activityCount': activityCount,
      'currentStreak': currentStreak,
      'level': level,
      'ownedFish': ownedFish,
      'ownedDecorations': ownedDecorations,
      'foodStock': foodStock,
      'createdAt': createdAt,
    };
  }

  UserProfile copyWith({
    int? totalPoints,
    int? totalFocusMinutes,
    int? sessionCount,
    int? activityCount,
    int? currentStreak,
    int? level,
    List<String>? ownedFish,
    List<String>? ownedDecorations,
    int? foodStock,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
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
    );
  }
}
