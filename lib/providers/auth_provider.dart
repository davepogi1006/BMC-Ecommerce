import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

/// Holds the current user + role so any screen can read it with Provider.
class AuthProvider extends ChangeNotifier {
  final _service = AuthService();
  StreamSubscription<User?>? _sub;
  StreamSubscription<UserProfile?>? _profileSub;
  bool _handlingDisabledUser = false;

  User? user;
  String role = 'customer';
  bool loading = true; // true until Firebase tells us who is logged in

  bool get isAdmin => role == 'admin';
  bool get isSeller => role == 'seller';
  bool get canAddProducts => isAdmin || isSeller;

  AuthProvider() {
    _sub = _service.authChanges.listen((u) {
      _profileSub?.cancel();
      _handlingDisabledUser = false;
      user = u;
      role = 'customer';
      loading = u != null;
      if (u == null) {
        loading = false;
        notifyListeners();
        return;
      }

      _profileSub = UserProfileService().streamProfile(u.uid).listen(
        (profile) {
          role = profile?.role ?? 'customer';
          loading = false;
          notifyListeners();
          if (profile?.isDisabled == true && !_handlingDisabledUser) {
            _handlingDisabledUser = true;
            unawaited(_service.signOut().catchError(
              (Object error, StackTrace stackTrace) {
                debugPrint('Could not sign out disabled account: $error');
              },
            ));
            return;
          }
          if (profile?.pendingEmail != null &&
              profile!.pendingEmail == u.email) {
            UserProfileService()
                .completePendingEmail(u.uid, u.email!)
                .catchError((Object error, StackTrace stackTrace) {
              debugPrint('Could not sync verified email: $error');
            });
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Could not load user profile role: $error');
          role = 'customer';
          loading = false;
          notifyListeners();
        },
      );
    });
  }

  /// Each method returns null on success, or an error message to show.
  Future<String?> signIn(String email, String password) async {
    try {
      await _service.signIn(email, password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e);
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      await _service.signInWithGoogle();
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e);
    } on FirebaseException catch (e) {
      debugPrint('Google sign-in Firebase error: ${e.message ?? e.code}');
      return 'Could not finish setting up your account. Please try again.';
    } on PlatformException catch (e) {
      debugPrint('Google sign-in failed: ${e.message ?? e.code}');
      return 'Google sign-in could not start. Check your connection and try again.';
    } on UnsupportedError catch (e) {
      return e.message;
    }
  }

  Future<String?> signUp(String name, String email, String password) async {
    try {
      await _service.signUp(name, email, password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e);
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _service.sendPasswordResetEmail(email);
      return null;
    } on FirebaseAuthException catch (e) {
      // Avoid exposing whether an email address is registered.
      if (e.code == 'user-not-found') return null;
      return _friendly(e);
    } on PlatformException catch (e) {
      debugPrint('Password reset request failed: ${e.message ?? e.code}');
      return 'Could not contact Firebase. Check your connection and try again.';
    }
  }

  Future<void> signOut() => _service.signOut();

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Wrong email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a while and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact the shop administrator.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'requires-recent-login':
        return 'For your security, sign in again before making this change.';
      case 'account-exists-with-different-credential':
        return 'An account already uses this email. Sign in with its original method.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled for this Firebase project.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
