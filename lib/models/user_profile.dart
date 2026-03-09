class UserProfile {
  final String uid;
  final String displayName;
  final int points;
  final int level;
  final String? currentAquariumTheme;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.points,
    required this.level,
    this.currentAquariumTheme,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      displayName: data['displayName'] ?? '',
      points: data['points'] ?? 0,
      level: data['level'] ?? 1,
      currentAquariumTheme: data['currentAquariumTheme'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'points': points,
      'level': level,
      'currentAquariumTheme': currentAquariumTheme,
    };
  }
}
