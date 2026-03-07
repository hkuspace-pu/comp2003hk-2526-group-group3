import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/focus_session.dart';
import '../models/activity_log.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User Profile ───────────────────────────────────────────

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'totalPoints': 0,
      'totalFocusMinutes': 0,
      'sessionCount': 0,
      'activityCount': 0,
      'currentStreak': 0,
      'level': 1,
      'ownedFish': [],
      'ownedDecorations': [],
      'foodStock': 0,
      'lastActiveDate': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc.data()!, uid);
  }

  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc.data()!, uid);
    });
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ─── Focus Sessions ─────────────────────────────────────────

  Future<void> saveFocusSession({
    required String uid,
    required int durationMinutes,
    required int pointsEarned,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // Save session record
    await _db.collection('users').doc(uid).collection('sessions').add({
      'uid': uid,
      'durationMinutes': durationMinutes,
      'pointsEarned': pointsEarned,
      'startTime': startTime,
      'endTime': endTime,
      'completed': true,
    });

    // Update user profile stats
    final userDoc = await _db.collection('users').doc(uid).get();
    final data = userDoc.data()!;

    final lastActiveDate = data['lastActiveDate'] != null
        ? (data['lastActiveDate'] as Timestamp).toDate()
        : null;
    final today = DateTime.now();
    int newStreak = data['currentStreak'] ?? 0;

    if (lastActiveDate != null) {
      final difference = today.difference(lastActiveDate).inDays;
      if (difference == 1) {
        newStreak += 1; // Consecutive day
      } else if (difference > 1) {
        newStreak = 1; // Streak broken
      }
      // Same day: streak unchanged
    } else {
      newStreak = 1; // First session
    }

    final currentPoints = data['totalPoints'] ?? 0;
    final currentMinutes = data['totalFocusMinutes'] ?? 0;
    final currentSessions = data['sessionCount'] ?? 0;
    final newPoints = currentPoints + pointsEarned;
    final newLevel = _calculateLevel(newPoints);

    await _db.collection('users').doc(uid).update({
      'totalPoints': newPoints,
      'totalFocusMinutes': currentMinutes + durationMinutes,
      'sessionCount': currentSessions + 1,
      'currentStreak': newStreak,
      'level': newLevel,
      'lastActiveDate': today,
    });
  }

  Future<List<FocusSession>> getFocusSessions(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('startTime', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FocusSession.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<List<FocusSession>> getSessionsForDateRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .where('startTime', isGreaterThanOrEqualTo: start)
        .where('startTime', isLessThanOrEqualTo: end)
        .orderBy('startTime', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FocusSession.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // ─── Store / Points ──────────────────────────────────────────

  Future<bool> purchaseItem({
    required String uid,
    required String itemKey,
    required int price,
    required bool isFish,
    required bool isDecoration,
    required bool isFood,
  }) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final data = userDoc.data()!;
    final currentPoints = data['totalPoints'] ?? 0;

    if (currentPoints < price) return false; // Not enough points

    final Map<String, dynamic> updates = {
      'totalPoints': currentPoints - price,
    };

    if (isFish) {
      final ownedFish = List<String>.from(data['ownedFish'] ?? []);
      ownedFish.add(itemKey);
      updates['ownedFish'] = ownedFish;
    } else if (isDecoration) {
      final ownedDecorations =
          List<String>.from(data['ownedDecorations'] ?? []);
      ownedDecorations.add(itemKey);
      updates['ownedDecorations'] = ownedDecorations;
    } else if (isFood) {
      updates['foodStock'] = (data['foodStock'] ?? 0) + 1;
    }

    await _db.collection('users').doc(uid).update(updates);
    return true;
  }

  // ─── Helpers ─────────────────────────────────────────────────

  int _calculateLevel(int points) {
    if (points < 500) return 1;
    if (points < 1500) return 2;
    if (points < 3000) return 3;
    if (points < 5000) return 4;
    if (points < 8000) return 5;
    if (points < 12000) return 6;
    if (points < 17000) return 7;
    if (points < 23000) return 8;
    if (points < 30000) return 9;
    return 10;
  }
  // ─── Activity Logs ───────────────────────────────────────────

  Future<void> saveActivityLog({
    required String uid,
    required String activityType,
    required int durationMinutes,
    required String mood,
    required String notes,
  }) async {
    final points = (durationMinutes * 1.5).round();

    await _db.collection('users').doc(uid).collection('activities').add({
      'uid': uid,
      'activityType': activityType,
      'durationMinutes': durationMinutes,
      'mood': mood,
      'notes': notes,
      'pointsEarned': points,
      'loggedAt': DateTime.now(),
    });

    final userDoc = await _db.collection('users').doc(uid).get();
    final data = userDoc.data()!;
    final currentPoints = data['totalPoints'] ?? 0;
    final currentActivities = data['activityCount'] ?? 0;
    final newPoints = currentPoints + points;
    final newLevel = _calculateLevel(newPoints);

    await _db.collection('users').doc(uid).update({
      'totalPoints': newPoints,
      'activityCount': currentActivities + 1,
      'level': newLevel,
    });
  }

  Future<List<ActivityLog>> getActivityLogs(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .orderBy('loggedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ActivityLog.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // ─── Data Export ─────────────────────────────────────────────

  Future<Map<String, dynamic>> exportUserData(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final sessions = await getFocusSessions(uid);
    final activities = await getActivityLogs(uid);

    // Convert profile data, handling Timestamp fields
    final profileData = userDoc.data()!;
    final cleanProfile = profileData.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      return MapEntry(key, value);
    });

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
      'profile': cleanProfile,
      'sessions': sessions
          .map((s) => {
                'durationMinutes': s.durationMinutes,
                'pointsEarned': s.pointsEarned,
                'startTime': s.startTime.toIso8601String(),
                'endTime': s.endTime.toIso8601String(),
                'completed': s.completed,
              })
          .toList(),
      'activities': activities
          .map((a) => {
                'activityType': a.activityType,
                'durationMinutes': a.durationMinutes,
                'mood': a.mood,
                'notes': a.notes,
                'pointsEarned': a.pointsEarned,
                'loggedAt': a.loggedAt.toIso8601String(),
              })
          .toList(),
    };
  }

  Future<void> importUserData(String uid, Map<String, dynamic> data) async {
    final profile = data['profile'] as Map<String, dynamic>?;
    final sessions = data['sessions'] as List<dynamic>?;
    final activities = data['activities'] as List<dynamic>?;

    // Restore profile stats
    if (profile != null) {
      await _db.collection('users').doc(uid).update({
        'totalPoints': profile['totalPoints'] ?? 0,
        'totalFocusMinutes': profile['totalFocusMinutes'] ?? 0,
        'sessionCount': profile['sessionCount'] ?? 0,
        'activityCount': profile['activityCount'] ?? 0,
        'currentStreak': profile['currentStreak'] ?? 0,
        'level': profile['level'] ?? 1,
        'ownedFish': profile['ownedFish'] ?? [],
        'ownedDecorations': profile['ownedDecorations'] ?? [],
        'foodStock': profile['foodStock'] ?? 0,
      });
    }

    // Restore sessions
    if (sessions != null) {
      for (final s in sessions) {
        await _db.collection('users').doc(uid).collection('sessions').add({
          'uid': uid,
          'durationMinutes': s['durationMinutes'],
          'pointsEarned': s['pointsEarned'],
          'startTime': DateTime.parse(s['startTime']),
          'endTime': DateTime.parse(s['endTime']),
          'completed': s['completed'],
        });
      }
    }

    // Restore activities
    if (activities != null) {
      for (final a in activities) {
        await _db.collection('users').doc(uid).collection('activities').add({
          'uid': uid,
          'activityType': a['activityType'],
          'durationMinutes': a['durationMinutes'],
          'mood': a['mood'],
          'notes': a['notes'],
          'pointsEarned': a['pointsEarned'],
          'loggedAt': DateTime.parse(a['loggedAt']),
        });
      }
    }
  }

  Future<void> deleteAllUserData(String uid) async {
    // Delete sessions
    final sessions =
        await _db.collection('users').doc(uid).collection('sessions').get();
    for (final doc in sessions.docs) {
      await doc.reference.delete();
    }

    // Delete activities
    final activities =
        await _db.collection('users').doc(uid).collection('activities').get();
    for (final doc in activities.docs) {
      await doc.reference.delete();
    }

    // Reset profile stats
    await _db.collection('users').doc(uid).update({
      'totalPoints': 0,
      'totalFocusMinutes': 0,
      'sessionCount': 0,
      'activityCount': 0,
      'currentStreak': 0,
      'level': 1,
      'ownedFish': [],
      'ownedDecorations': [],
      'foodStock': 0,
      'lastActiveDate': null,
    });
  }
}
