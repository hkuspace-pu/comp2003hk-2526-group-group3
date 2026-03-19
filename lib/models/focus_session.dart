class FocusSession {
  final String? id;
  final String uid;
  final int durationMinutes;
  final int pointsEarned;
  final DateTime startTime;
  final DateTime endTime;
  final bool completed;

  FocusSession({
    this.id,
    required this.uid,
    required this.durationMinutes,
    required this.pointsEarned,
    required this.startTime,
    required this.endTime,
    required this.completed,
  });

  factory FocusSession.fromFirestore(Map<String, dynamic> data, String id) {
    return FocusSession(
      id: id,
      uid: data['uid'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 0,
      pointsEarned: data['pointsEarned'] ?? 0,
      startTime: data['startTime']?.toDate() ?? DateTime.now(),
      endTime: data['endTime']?.toDate() ?? DateTime.now(),
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'durationMinutes': durationMinutes,
      'pointsEarned': pointsEarned,
      'startTime': startTime,
      'endTime': endTime,
      'completed': completed,
    };
  }
}
