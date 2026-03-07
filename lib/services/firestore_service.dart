import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/focus_session.dart';

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
}
