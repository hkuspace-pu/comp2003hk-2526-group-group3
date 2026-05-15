import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

import '../models/activity_log.dart';
import '../models/focus_session.dart';
import '../models/user_profile.dart';

class LuckyResult {
  final String fishId;
  final int remainingPoints;

  LuckyResult({
    required this.fishId,
    required this.remainingPoints,
  });
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const int maxAquariumFish = 10;

  static String fishKey(String fishId, int level) => '$fishId@$level';
  static bool _isLeveledKey(String key) => key.contains('@');

  static (String id, int level) parseFishKey(String key) {
    final parts = key.split('@');
    final id = parts.first;
    final level = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
    return (id, level);
  }

  static Map<String, int> normalizeFishInventory(Map<String, dynamic> raw) {
    final out = <String, int>{};
    raw.forEach((k, v) {
      final n = (v is int) ? v : (v is num ? v.toInt() : 0);
      if (n <= 0) return;
      if (_isLeveledKey(k)) {
        out[k] = (out[k] ?? 0) + n;
      } else {
        final lk = fishKey(k, 1);
        out[lk] = (out[lk] ?? 0) + n;
      }
    });
    return out;
  }

  static List<String> normalizeAquariumFish(List<dynamic> raw) {
    final out = <String>[];
    for (final x in raw) {
      if (x is! String) continue;
      if (_isLeveledKey(x)) {
        out.add(x);
      } else {
        out.add(fishKey(x, 1));
      }
    }
    return out;
  }

  Future<Map<String, String>> uploadActivityEvidence({
    required String uid,
    required Uint8List bytes,
    required String evidenceType,
    required String originalFileName,
  }) async {
    final safeFileName = _sanitizeStorageFileName(originalFileName);
    final extension = _extractFileExtension(safeFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        'activity_evidence/$uid/${timestamp}_${evidenceType.toLowerCase()}.$extension';

    final ref = _storage.ref().child(storagePath);
    final metadata = SettableMetadata(
      contentType: _guessEvidenceContentType(
        fileName: safeFileName,
        evidenceType: evidenceType,
      ),
      customMetadata: {
        'uid': uid,
        'evidenceType': evidenceType,
        'originalFileName': originalFileName,
      },
    );

    await ref.putData(bytes, metadata);
    final downloadUrl = await ref.getDownloadURL();

    return {
      'url': downloadUrl,
      'path': storagePath,
      'fileName': originalFileName,
      'contentType': metadata.contentType ?? '',
    };
  }

  String _sanitizeStorageFileName(String fileName) {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) return 'evidence_file';
    return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String _extractFileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return 'bin';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String _guessEvidenceContentType({
    required String fileName,
    required String evidenceType,
  }) {
    final ext = _extractFileExtension(fileName);

    const imageMap = <String, String>{
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'heic': 'image/heic',
      'heif': 'image/heif',
    };

    const videoMap = <String, String>{
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'webm': 'video/webm',
      '3gp': 'video/3gpp',
      'm4v': 'video/x-m4v',
    };

    if (imageMap.containsKey(ext)) return imageMap[ext]!;
    if (videoMap.containsKey(ext)) return videoMap[ext]!;
    return evidenceType.toLowerCase() == 'video' ? 'video/mp4' : 'image/jpeg';
  }

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String role = 'user',
    bool requirePasswordResetOnFirstLogin = false,
    String? adminNotes,
    String? createdByUid,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'role': role,
      'requirePasswordResetOnFirstLogin': requirePasswordResetOnFirstLogin,
      'adminNotes': adminNotes,
      'createdByUid': createdByUid,
      'isDisabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'totalPoints': 0,
      'totalFocusMinutes': 0,
      'sessionCount': 0,
      'activityCount': 0,
      'currentStreak': 0,
      'level': 1,
      'ownedFish': <String>[],
      'fishInventory': <String, int>{},
      'aquariumFish': <String>[],
      'ownedDecorations': <String>[],
      'foodStock': 0,
      'lastActiveDate': null,
      'hungerPercent': 70.0,
      'hungerUpdatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsersStream() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> setUserDisabled({
    required String uid,
    required bool disabled,
  }) async {
    await _db.collection('users').doc(uid).update({
      'isDisabled': disabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateManagedUser({
    required String uid,
    required String displayName,
    required String email,
    required String role,
    required bool requirePasswordResetOnFirstLogin,
    String? adminNotes,
  }) async {
    await _db.collection('users').doc(uid).update({
      'displayName': displayName,
      'email': email,
      'role': role,
      'requirePasswordResetOnFirstLogin': requirePasswordResetOnFirstLogin,
      'adminNotes': adminNotes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteManagedUser(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    final sessions = await userRef.collection('sessions').get();
    for (final doc in sessions.docs) {
      await doc.reference.delete();
    }
    final activities = await userRef.collection('activities').get();
    for (final doc in activities.docs) {
      await doc.reference.delete();
    }
    final timeChecks = await userRef.collection('timeChecks').get();
    for (final doc in timeChecks.docs) {
      await doc.reference.delete();
    }
    await userRef.delete();
  }

  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['role'] as String?;
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
      bool needWriteBack = false;
      if (!data.containsKey('fishInventory')) {
        final owned = List<String>.from(data['ownedFish'] ?? const <String>[]);
        final inv = <String, int>{};
        for (final id in owned) {
          final k1 = fishKey(id, 1);
          inv[k1] = (inv[k1] ?? 0) + 1;
        }
        data['fishInventory'] = inv;
        needWriteBack = true;
      } else {
        final rawInv = Map<String, dynamic>.from(data['fishInventory'] ?? {});
        final normalizedInv = normalizeFishInventory(rawInv);
        final hasLegacyKey = rawInv.keys.any((k) => !_isLeveledKey(k));
        if (hasLegacyKey || rawInv.length != normalizedInv.length) {
          data['fishInventory'] = normalizedInv;
          needWriteBack = true;
        }
      }
      if (!data.containsKey('aquariumFish')) {
        data['aquariumFish'] = <String>[];
        needWriteBack = true;
      } else {
        final rawTank = List<dynamic>.from(data['aquariumFish'] ?? const []);
        final normalizedTank = normalizeAquariumFish(rawTank);
        if (rawTank.whereType<String>().join(',') != normalizedTank.join(',')) {
          data['aquariumFish'] = normalizedTank;
          needWriteBack = true;
        }
      }
      if (needWriteBack) {
        await ref.set({
          'fishInventory': data['fishInventory'],
          'aquariumFish': data['aquariumFish'],
        }, SetOptions(merge: true));
      }
      return UserProfile.fromFirestore(data, uid);
    });
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<bool> addFishToAquariumKey({
    required String uid,
    required String fishKey,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return false;
      final data = snap.data() ?? {};
      final inv = normalizeFishInventory(
        Map<String, dynamic>.from(data['fishInventory'] ?? {}),
      );
      final tank = normalizeAquariumFish(
        List<dynamic>.from(data['aquariumFish'] ?? const []),
      );
      final invCount = inv[fishKey] ?? 0;
      final inTank = tank.where((x) => x == fishKey).length;
      final available = invCount - inTank;
      if (tank.length >= maxAquariumFish) return false;
      if (available <= 0) return false;
      tank.add(fishKey);
      tx.update(userRef, {
        'aquariumFish': tank,
        'fishInventory': inv,
      });
      return true;
    });
  }

  Future<bool> removeFishFromAquariumKey({
    required String uid,
    required String fishKey,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return false;
      final data = snap.data() ?? {};
      final tank = normalizeAquariumFish(
        List<dynamic>.from(data['aquariumFish'] ?? const []),
      );
      final idx = tank.lastIndexOf(fishKey);
      if (idx < 0) return false;
      tank.removeAt(idx);
      tx.update(userRef, {'aquariumFish': tank});
      return true;
    });
  }

  Future<bool> addFishToAquarium({
    required String uid,
    required String fishId,
  }) {
    return addFishToAquariumKey(uid: uid, fishKey: fishKey(fishId, 1));
  }

  Future<bool> removeFishFromAquarium({
    required String uid,
    required String fishId,
  }) {
    return removeFishFromAquariumKey(uid: uid, fishKey: fishKey(fishId, 1));
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
      final inv = normalizeFishInventory(
        Map<String, dynamic>.from(data['fishInventory'] ?? {}),
      );
      final tank = normalizeAquariumFish(List<dynamic>.from(fishIds));
      if (tank.length > maxAquariumFish) return false;
      final want = <String, int>{};
      for (final k in tank) {
        want[k] = (want[k] ?? 0) + 1;
      }
      for (final e in want.entries) {
        final invCount = inv[e.key] ?? 0;
        if (e.value > invCount) return false;
      }
      tx.update(userRef, {
        'aquariumFish': tank,
        'fishInventory': inv,
      });
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
        'role': 'user',
        'requirePasswordResetOnFirstLogin': false,
        'adminNotes': null,
        'createdByUid': null,
        'totalPoints': 0,
        'totalFocusMinutes': 0,
        'sessionCount': 0,
        'activityCount': 0,
        'currentStreak': 0,
        'level': 1,
        'ownedFish': <String>[],
        'fishInventory': <String, int>{},
        'aquariumFish': <String>[],
        'ownedDecorations': <String>[],
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
      final updates = <String, dynamic>{
        'totalPoints': currentPoints - price,
      };
      if (isFish) {
        final inv = normalizeFishInventory(
          Map<String, dynamic>.from(data['fishInventory'] ?? {}),
        );
        final k1 = fishKey(itemKey, 1);
        inv[k1] = (inv[k1] ?? 0) + 1;
        updates['fishInventory'] = inv;
      } else if (isDecoration) {
        final ownedDecorations =
            List<String>.from(data['ownedDecorations'] ?? const <String>[]);
        ownedDecorations.add(itemKey);
        updates['ownedDecorations'] = ownedDecorations;
      } else if (isFood) {
        updates['foodStock'] = ((data['foodStock'] ?? 0) as int) + 1;
      }
      tx.update(userRef, updates);
      return true;
    });
  }

  Future<LuckyResult?> purchaseLucky({
    required String uid,
    required int price,
    required Map<String, double> weights,
  }) async {
    final fishId = _pickWeighted(weights, Random());
    final userRef = _db.collection('users').doc(uid);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return null;
      final data = snap.data()!;
      final points = data['totalPoints'] ?? 0;
      if (points < price) return null;
      final inv = normalizeFishInventory(
        Map<String, dynamic>.from(data['fishInventory'] ?? {}),
      );
      final k = fishKey(fishId, 1);
      inv[k] = (inv[k] ?? 0) + 1;
      final remaining = points - price;
      tx.update(userRef, {
        'totalPoints': remaining,
        'fishInventory': inv,
      });
      return LuckyResult(
        fishId: fishId,
        remainingPoints: remaining,
      );
    });
  }

  static String _pickWeighted(Map<String, double> weights, Random rng) {
    final entries = weights.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      throw StateError('No valid lucky weights');
    }
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    final r = rng.nextDouble() * total;
    double acc = 0;
    for (final e in entries) {
      acc += e.value;
      if (r <= acc) return e.key;
    }
    return entries.last.key;
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
    String? evidenceUrl,
    String? evidenceType,
    String? evidenceStoragePath,
    String? evidenceFileName,
    String? evidenceContentType,
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
      'evidenceUrl': evidenceUrl,
      'evidenceType': evidenceType,
      'evidenceStoragePath': evidenceStoragePath,
      'evidenceFileName': evidenceFileName,
      'evidenceContentType': evidenceContentType,
      'hasEvidence': evidenceUrl != null,
      'evidenceStatus': evidenceUrl != null ? 'pending' : null,
      'evidenceReviewedAt': null,
      'evidenceReviewedByUid': null,
      'evidenceReviewNote': null,
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
      final invRaw = Map<String, dynamic>.from(profile['fishInventory'] ?? {});
      final inv = normalizeFishInventory(invRaw);
      await _db.collection('users').doc(uid).update({
        'totalPoints': profile['totalPoints'] ?? 0,
        'totalFocusMinutes': profile['totalFocusMinutes'] ?? 0,
        'sessionCount': profile['sessionCount'] ?? 0,
        'activityCount': profile['activityCount'] ?? 0,
        'currentStreak': profile['currentStreak'] ?? 0,
        'level': profile['level'] ?? 1,
        'ownedFish': profile['ownedFish'] ?? [],
        'fishInventory': inv,
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
      'fishInventory': <String, int>{},
      'aquariumFish': <String>[],
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

  Future<bool> synthesizeFish({
    required String uid,
    required String fishId,
    int fromLevel = 1,
    int toLevel = 2,
    int cost = 3,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return false;
      final data = snap.data() ?? {};
      final inv = normalizeFishInventory(
        Map<String, dynamic>.from(data['fishInventory'] ?? {}),
      );
      final tank = normalizeAquariumFish(
        List<dynamic>.from(data['aquariumFish'] ?? const []),
      );
      final fromKey = fishKey(fishId, fromLevel);
      final toKey = fishKey(fishId, toLevel);
      final invCount = inv[fromKey] ?? 0;
      final inTank = tank.where((x) => x == fromKey).length;
      final available = invCount - inTank;
      if (available < cost) return false;
      inv[fromKey] = invCount - cost;
      inv[toKey] = (inv[toKey] ?? 0) + 1;
      tx.update(userRef, {'fishInventory': inv});
      return true;
    });
  }
}
