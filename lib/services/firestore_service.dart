import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_log.dart';
import '../models/focus_session.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int maxAquariumFish = 10;

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
      'fishInventory': <String, int>{},
      'aquariumFish': <String>[],
      'ownedDecorations': [],
      'foodStock': 0,
      'lastActiveDate': null,
      'hungerPercent': 70.0,
      'hungerUpdatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc.data()!, uid);
  }

  Stream<UserProfile?> getUserProfileStream(String uid) {
    final ref = _db.collection('users').doc(uid);

    return ref.snapshots().asyncMap((doc) async {
      if (!doc.exists) return null;

      final data = doc.data()!;
      final hasInventory = data.containsKey('fishInventory');
      final hasAquariumFish = data.containsKey('aquariumFish');

      if (!hasInventory) {
        final owned = List<String>.from(data['ownedFish'] ?? const <String>[]);
        final inv = <String, int>{};
        for (final id in owned) {
          inv[id] = (inv[id] ?? 0) + 1;
        }
        await ref.set({'fishInventory': inv}, SetOptions(merge: true));
        data['fishInventory'] = inv;
      }

      if (!hasAquariumFish) {
        await ref.set({'aquariumFish': <String>[]}, SetOptions(merge: true));
        data['aquariumFish'] = <String>[];
      }

      return UserProfile.fromFirestore(data, uid);
    });
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<bool> addFishToAquarium({
    required String uid,
    required String fishId,
  }) async {
    final userRef = _db.collection('users').doc(uid);

    return _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return false;

      final data = snap.data() as Map<String, dynamic>? ?? {};
      final inv = Map<String, dynamic>.from(data['fishInventory'] ?? {});
      final tank = List<String>.from(data['aquariumFish'] ?? const <String>[]);

      final invCount = (inv[fishId] ?? 0) as int;
      final inTank = tank.where((x) => x == fishId).length;
      final available = invCount - inTank;

      if (tank.length >= maxAquariumFish) return false;
      if (available <= 0) return false;

      tank.add(fishId);
      tx.update(userRef, {'aquariumFish': tank});
      return true;
    });
  }

  Future<bool> removeFishFromAquarium({
    required String uid,
    required String fishId,
  }) async {
    final userRef = _db.collection('users').doc(uid);

    return _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return false;

      final data = snap.data() ?? {};
      final tank = List<String>.from(data['aquariumFish'] ?? const <String>[]);

      final idx = tank.lastIndexOf(fishId);
      if (idx < 0) return false;

      tank.removeAt(idx);
      tx.update(userRef, {'aquariumFish': tank});
      return true;
    });
  }

  Future<bool> setAquariumFish({
    required String uid,
    required List<String> fishIds,
  }) async {
    final userRef = _db.collection('users').doc(uid);

    return _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return false;

      final data = snap.data() ?? {};
      final inv = Map<String, dynamic>.from(data['fishInventory'] ?? {});
      if (fishIds.length > maxAquariumFish) return false;

      final want = <String, int>{};
      for (final id in fishIds) {
        want[id] = (want[id] ?? 0) + 1;
      }

      for (final e in want.entries) {
        final invCount = (inv[e.key] ?? 0) as int;
        if (e.value > invCount) return false;
      }

      tx.update(userRef, {'aquariumFish': fishIds});
      return true;
    });
  }

  Future<int> getDeviceServerTimeSkewSeconds({required String uid}) async {
    final ref = _db.collection('users').doc(uid).collection('timeChecks').doc();

    final deviceNow = DateTime.now();
    await ref.set({
      'deviceNow': Timestamp.fromDate(deviceNow),
      'serverNow': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    DocumentSnapshot<Map<String, dynamic>> snap;
    Timestamp? serverTs;
    for (int i = 0; i < 5; i++) {
      snap = await ref.get(const GetOptions(source: Source.server));
      final data = snap.data();
      if (data != null && data['serverNow'] is Timestamp) {
        serverTs = data['serverNow'] as Timestamp;
        final deviceTs = data['deviceNow'] as Timestamp;
        return deviceTs.toDate().difference(serverTs.toDate()).inSeconds;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return 999999;
  }

  Future<void> saveFocusSession({
    required String uid,
    required int durationMinutes,
    required int pointsEarned,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    await _db.collection('users').doc(uid).collection('sessions').add({
      'uid': uid,
      'durationMinutes': durationMinutes,
      'pointsEarned': pointsEarned,
      'startTime': startTime,
      'endTime': endTime,
      'completed': true,
    });

    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists || userDoc.data() == null) {
      await userRef.set({
        'email': '',
        'displayName': '',
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
        'hungerPercent': 70.0,
        'hungerUpdatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final freshDoc = await userRef.get();
    final data = freshDoc.data() ?? <String, dynamic>{};

    final lastActiveDate = data['lastActiveDate'] != null
        ? (data['lastActiveDate'] as Timestamp).toDate()
        : null;
    final today = DateTime.now();
    int newStreak = data['currentStreak'] ?? 0;

    if (lastActiveDate != null) {
      final difference = today.difference(lastActiveDate).inDays;
      if (difference == 1) {
        newStreak += 1;
      } else if (difference > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
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

  Future<bool> purchaseItem({
    required String uid,
    required String itemKey,
    required int price,
    required bool isFish,
    required bool isDecoration,
    required bool isFood,
  }) async {
    final userRef = _db.collection('users').doc(uid);

    return _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return false;

      final data = snap.data() ?? {};
      final currentPoints = (data['totalPoints'] ?? 0) as int;
      if (currentPoints < price) return false;

      final Map<String, dynamic> updates = {
        'totalPoints': currentPoints - price,
      };

      if (isFish) {
        final inv = Map<String, dynamic>.from(data['fishInventory'] ?? {});
        final current = (inv[itemKey] ?? 0) as int;
        inv[itemKey] = current + 1;
        updates['fishInventory'] = inv;
      } else if (isDecoration) {
        final ownedDecorations =
            List<String>.from(data['ownedDecorations'] ?? const []);
        ownedDecorations.add(itemKey);
        updates['ownedDecorations'] = ownedDecorations;
      } else if (isFood) {
        updates['foodStock'] = ((data['foodStock'] ?? 0) as int) + 1;
      }

      tx.update(userRef, updates);
      return true;
    });
  }

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

  static const double _decayPerHour = 2.0;
  double computeCurrentHungerPercent({
    required double storedPercent,
    required DateTime? updatedAt,
    DateTime? now,
  }) {
    final safeStored = storedPercent.clamp(0.0, 100.0);
    if (updatedAt == null) return safeStored;

    final currentNow = now ?? DateTime.now();
    final diffMinutes = currentNow.difference(updatedAt).inMinutes;
    if (diffMinutes <= 0) return safeStored;

    final decay = (diffMinutes / 60.0) * _decayPerHour;
    final current = (safeStored - decay).clamp(0.0, 100.0);
    return current;
  }

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

  Future<Map<String, dynamic>> exportUserData(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final sessions = await getFocusSessions(uid);
    final activities = await getActivityLogs(uid);
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

    if (profile != null) {
      await _db.collection('users').doc(uid).update({
        'totalPoints': profile['totalPoints'] ?? 0,
        'totalFocusMinutes': profile['totalFocusMinutes'] ?? 0,
        'sessionCount': profile['sessionCount'] ?? 0,
        'activityCount': profile['activityCount'] ?? 0,
        'currentStreak': profile['currentStreak'] ?? 0,
        'level': profile['level'] ?? 1,
        'ownedFish': profile['ownedFish'] ?? [],
        'fishInventory': profile['fishInventory'] ?? <String, int>{},
        'aquariumFish': profile['aquariumFish'] ?? <String>[],
        'ownedDecorations': profile['ownedDecorations'] ?? [],
        'foodStock': profile['foodStock'] ?? 0,
      });
    }

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
    final sessions =
        await _db.collection('users').doc(uid).collection('sessions').get();
    for (final doc in sessions.docs) {
      await doc.reference.delete();
    }

    final activities =
        await _db.collection('users').doc(uid).collection('activities').get();
    for (final doc in activities.docs) {
      await doc.reference.delete();
    }

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

  Future<bool> feedFish(String uid) async {
    final userRef = _db.collection('users').doc(uid);

    return _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return false;

      final data = snap.data() ?? {};
      final currentFood = (data['foodStock'] ?? 0) as int;
      if (currentFood <= 0) return false;

      final stored = (data['hungerPercent'] ?? 100).toDouble();
      final ts = data['hungerUpdatedAt'];
      final updatedAt = ts is Timestamp ? ts.toDate() : null;

      final currentHunger = computeCurrentHungerPercent(
        storedPercent: stored,
        updatedAt: updatedAt,
      );

      final newHunger = (currentHunger + 10.0).clamp(0.0, 100.0);

      tx.update(userRef, {
        'foodStock': currentFood - 1,
        'hungerPercent': newHunger,
        'hungerUpdatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }
}
