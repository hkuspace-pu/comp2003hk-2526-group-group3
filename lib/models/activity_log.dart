class ActivityLog {
  final String type;
  final String note;
  final List<String> mediaUrls;
  final DateTime timestamp;
  final int pointsEarned;

  ActivityLog({
    required this.type,
    required this.note,
    required this.mediaUrls,
    required this.timestamp,
    required this.pointsEarned,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'note': note,
      'mediaUrls': mediaUrls,
      'timestamp': timestamp,
      'pointsEarned': pointsEarned,
    };
  }
}
