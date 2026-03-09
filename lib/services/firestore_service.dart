import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/focus_session.dart';
import '../models/activity_log.dart';
import '../models/aquarium_fish.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===== User Profile =====
  Future<UserProfile> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return UserProfile.fromMap(uid, doc.data()!);
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ===== Focus Session =====
  Future<void> addFocusSession(String uid, FocusSession session) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('focusSessions')
        .add(session.toMap());
  }

  // ===== Activity =====
  Future<void> addActivity(String uid, ActivityLog activity) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .add(activity.toMap());
  }

  // ===== Aquarium Fish =====
  Future<void> addFish(String uid, AquariumFish fish) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('aquarium')
        .add(fish.toMap());
  }

  // ===== Shop Items =====
  Future<List<Map<String, dynamic>>> getShopItems() async {
    final query = await _db.collection('shopItems').get();
    return query.docs.map((e) => e.data()).toList();
  }
}
