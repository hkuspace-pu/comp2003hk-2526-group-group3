import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<UserCredential?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user profile in Firestore
    if (credential.user != null) {
      await _firestoreService.createUserProfile(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
      );
    }

    return credential;
  }

  // Login with email and password
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential;
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
