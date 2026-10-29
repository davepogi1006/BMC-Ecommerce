import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import '../models/user_profile.dart';

class ManagedUserDirectory {
  final List<UserProfile> users;
  final bool authAccountsAvailable;

  const ManagedUserDirectory({
    required this.users,
    required this.authAccountsAvailable,
  });
}

class UserProfileService {
  final _auth = FirebaseAuth.instance;
  final _users = FirebaseFirestore.instance.collection('users');

  Stream<UserProfile?> streamProfile(String uid) {
    return _users.doc(uid).snapshots().map(
          (document) => document.exists ? UserProfile.fromDoc(document) : null,
        );
  }

  Future<ManagedUserDirectory> loadUsers() async {
    final body = await _requestAdminAction({'action': 'listUsers'});
    final users = body['users'];
    final authAccountsAvailable = body['authAccountsAvailable'];
    if (users is! List || authAccountsAvailable is! bool) {
      throw const FormatException(
          'User management service returned an invalid user directory.');
    }
    final profiles = users.map((entry) {
      if (entry is! Map<String, dynamic> || entry['id'] is! String) {
        throw const FormatException(
            'User management service returned an invalid user record.');
      }
      return UserProfile.fromMap(entry['id'] as String, entry);
    }).toList()
      ..sort((a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()));
    return ManagedUserDirectory(
      users: profiles,
      authAccountsAvailable: authAccountsAvailable,
    );
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String photoUrl,
    String? newPassword,
    String? currentPassword,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != uid) {
      throw StateError('You can only update your own authentication details.');
    }
    final emailChanged = email.trim() != (currentUser.email ?? '');
    final hasPasswordProvider = currentUser.providerData
        .any((provider) => provider.providerId == 'password');
    final hasGoogleProvider = currentUser.providerData
        .any((provider) => provider.providerId == 'google.com');
    if (emailChanged || (newPassword?.isNotEmpty ?? false)) {
      if (hasPasswordProvider &&
          currentPassword != null &&
          currentPassword.isNotEmpty) {
        final currentEmail = currentUser.email;
        if (currentEmail == null || currentEmail.isEmpty) {
          throw StateError('This account does not have an email address.');
        }
        final credential = EmailAuthProvider.credential(
          email: currentEmail,
          password: currentPassword,
        );
        await currentUser.reauthenticateWithCredential(credential);
      } else if (hasGoogleProvider) {
        final provider = GoogleAuthProvider();
        if (kIsWeb) {
          await currentUser.reauthenticateWithPopup(provider);
        } else {
          await currentUser.reauthenticateWithProvider(provider);
        }
      } else {
        throw StateError(
          'Sign in again with your account provider before changing email or password.',
        );
      }
    }

    if (emailChanged) await currentUser.verifyBeforeUpdateEmail(email.trim());
    if (newPassword != null && newPassword.isNotEmpty) {
      if (hasPasswordProvider) {
        await currentUser.updatePassword(newPassword);
      } else if (hasGoogleProvider) {
        final currentEmail = currentUser.email;
        if (currentEmail == null || currentEmail.isEmpty) {
          throw StateError(
              'Add an email address to your Google account before setting a password.');
        }
        final credential = EmailAuthProvider.credential(
          email: currentEmail,
          password: newPassword,
        );
        await currentUser.linkWithCredential(credential);
      } else {
        throw StateError(
          'This account provider does not support setting a password here.',
        );
      }
    }
    if (name.trim() != (currentUser.displayName ?? '')) {
      await currentUser.updateDisplayName(name.trim());
    }
    if (photoUrl != (currentUser.photoURL ?? '')) {
      await currentUser.updatePhotoURL(photoUrl.isEmpty ? null : photoUrl);
    }

    await _users.doc(uid).set({
      'name': name.trim(),
      'email': currentUser.email ?? email.trim(),
      'pendingEmail': emailChanged ? email.trim() : FieldValue.delete(),
      'phone': phone.trim(),
      'address': address.trim(),
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> completePendingEmail(String uid, String verifiedEmail) async {
    final ref = _users.doc(uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.data()?['pendingEmail'] == verifiedEmail) {
        transaction.update(ref, {
          'email': verifiedEmail,
          'pendingEmail': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> updateManagedProfile({
    required String uid,
    required String name,
    required String phone,
    required String address,
  }) {
    return _adminAction({
      'action': 'setProfile',
      'userId': uid,
      'profile': {
        'name': name.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
      },
    });
  }

  Future<void> updateRole(String uid, String role) {
    if (role != 'customer' && role != 'admin') {
      throw ArgumentError.value(role, 'role', 'Unsupported role');
    }
    return _adminAction({
      'action': 'setRole',
      'userId': uid,
      'role': role,
    });
  }

  Future<void> setDisabled(String uid, bool disabled) {
    return _adminAction({
      'action': 'setDisabled',
      'userId': uid,
      'disabled': disabled,
    });
  }

  Future<void> _adminAction(Map<String, Object> action) async {
    await _requestAdminAction(action);
  }

  Future<Map<String, dynamic>> _requestAdminAction(
    Map<String, Object> action,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in again.');
    final token = await user.getIdToken();
    if (token == null) throw StateError('Could not get your login token.');
    final response = await http.post(
      Uri.parse(AppConfig.manageUsersUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(action),
    );
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('User management service returned an invalid response.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          body['error'] ?? 'User update failed (${response.statusCode}).');
    }
    return body;
  }
}
