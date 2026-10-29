import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String photoUrl;
  final String? pendingEmail;
  final String role;
  final bool isDisabled;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.photoUrl,
    required this.pendingEmail,
    required this.role,
    required this.isDisabled,
  });

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> document) {
    return UserProfile.fromMap(document.id, document.data() ?? {});
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      pendingEmail: data['pendingEmail'] as String?,
      role: data['role'] as String? ?? 'customer',
      isDisabled: data['isDisabled'] as bool? ?? false,
    );
  }
}
