class FocusSession {
  final DateTime startTime;
  final DateTime endTime;
  final int duration;
  final int pointsEarned;

  FocusSession({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.pointsEarned,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'pointsEarned': pointsEarned,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> data) {
    return FocusSession(
      startTime: (data['startTime'] as DateTime),
      endTime: (data['endTime'] as DateTime),
      duration: data['duration'],
      pointsEarned: data['pointsEarned'],
    );
  }
}
