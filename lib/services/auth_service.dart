
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _firestoreService.createUserProfile(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
        );
        await credential.user!.sendEmailVerification();
      }
      return credential;
    } catch (e) {
      print('REGISTER ERROR: $e');
      rethrow;
    }
  }

  Future<void> createUserByAdmin({
    required String email,
    required String password,
    required String displayName,
    required String role,
    bool sendVerificationEmail = true,
    bool requirePasswordReset = false,
    String adminNotes = '',
  }) async {
    FirebaseApp? tempApp;
    try {
      final adminUser = _auth.currentUser;
      if (adminUser == null) {
        throw FirebaseAuthException(
          code: 'admin-not-authenticated',
          message: 'Current admin session is not valid.',
        );
      }

      final appName = 'admin-create-${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final createdUser = credential.user;
      if (createdUser == null) {
        throw FirebaseAuthException(
          code: 'user-create-failed',
          message: 'Unable to create the new account.',
        );
      }

      await _firestoreService.createUserProfile(
        uid: createdUser.uid,
        email: email,
        displayName: displayName,
        role: role,
        requirePasswordResetOnFirstLogin: requirePasswordReset,
        adminNotes: adminNotes.trim().isEmpty ? null : adminNotes.trim(),
        createdByUid: adminUser.uid,
      );

      if (sendVerificationEmail) {
        await createdUser.sendEmailVerification();
      }

      await tempAuth.signOut();
    } catch (e) {
      print('ADMIN CREATE USER ERROR: $e');
      rethrow;
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null && !credential.user!.emailVerified) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before logging in.',
        );
      }
      return credential;
    } catch (e) {
      print('LOGIN ERROR: $e');
      rethrow;
    }
  }

  Future<UserCredential?> loginAsAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'admin-login-failed',
          message: 'Unable to sign in as admin.',
        );
      }
      if (!user.emailVerified) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before logging in.',
        );
      }
      final role = await _firestoreService.getUserRole(user.uid);
      if (role != 'admin') {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'not-admin',
          message: 'This account does not have admin access.',
        );
      }
      return credential;
    } catch (e) {
      print('ADMIN LOGIN ERROR: $e');
      rethrow;
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final role = await _firestoreService.getUserRole(user.uid);
    return role == 'admin';
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
