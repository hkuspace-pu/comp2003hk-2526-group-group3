class ActivityLog {
  final String? id;
  final String uid;
  final String activityType;
  final int durationMinutes;
  final String mood;
  final String notes;
  final int pointsEarned;
  final DateTime loggedAt;
  final String? photoUrl;

  ActivityLog({
    this.id,
    required this.uid,
    required this.activityType,
    required this.durationMinutes,
    required this.mood,
    required this.notes,
    required this.pointsEarned,
    required this.loggedAt,
    this.photoUrl,
  });

  factory ActivityLog.fromFirestore(Map<String, dynamic> data, String id) {
    return ActivityLog(
      id: id,
      uid: data['uid'] ?? '',
      activityType: data['activityType'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 0,
      mood: data['mood'] ?? '',
      notes: data['notes'] ?? '',
      pointsEarned: data['pointsEarned'] ?? 0,
      loggedAt: data['loggedAt']?.toDate() ?? DateTime.now(),
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'activityType': activityType,
      'durationMinutes': durationMinutes,
      'mood': mood,
      'notes': notes,
      'pointsEarned': pointsEarned,
      'loggedAt': loggedAt,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}
