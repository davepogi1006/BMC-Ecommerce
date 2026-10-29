import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Talks to Firebase Auth + the "users" collection in Firestore.
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn(scopes: ['email']);

  /// Emits the logged-in user, or null when logged out.
  Stream<User?> get authChanges => _auth.authStateChanges();

  Future<void> signUp(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Every user gets a profile document. New users are always "customer".
    // To make someone an admin, edit "role" by hand in the Firebase Console.
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email,
      'phone': '',
      'address': '',
      'photoUrl': '',
      'isDisabled': false,
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) await _createProfileIfMissing(user);
  }

  Future<void> signInWithGoogle() async {
    final UserCredential credential;
    if (kIsWeb) {
      credential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final oauthCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      credential = await _auth.signInWithCredential(oauthCredential);
    } else {
      throw UnsupportedError(
        'Google sign-in is currently available on Android and web.',
      );
    }

    final user = credential.user;
    if (user == null) {
      throw StateError('Google sign-in completed without a user account.');
    }
    await _createProfileIfMissing(user);
  }

  Future<void> _createProfileIfMissing(User user) async {
    final profile = _db.collection('users').doc(user.uid);
    final snapshot = await profile.get();
    if (snapshot.exists) return;

    await profile.set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'phone': '',
      'address': '',
      'photoUrl': user.photoURL ?? '',
      'isDisabled': false,
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  Future<String> getRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['role'] as String?) ?? 'customer';
  }
}
