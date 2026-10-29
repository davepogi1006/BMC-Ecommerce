import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserProfile profile;
  final bool adminEditing;

  const ProfileEditScreen({
    super.key,
    required this.profile,
    this.adminEditing = false,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _email = TextEditingController(text: widget.profile.email);
  late final _phone = TextEditingController(text: widget.profile.phone);
  late final _address = TextEditingController(text: widget.profile.address);
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  String _photoUrl = '';
  Uint8List? _imageBytes;
  XFile? _pickedImage;
  bool _saving = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool get _isOwnProfile =>
      FirebaseAuth.instance.currentUser?.uid == widget.profile.id;

  bool get _hasPasswordProvider =>
      FirebaseAuth.instance.currentUser?.providerData
          .any((provider) => provider.providerId == 'password') ??
      false;

  bool get _hasGoogleProvider =>
      FirebaseAuth.instance.currentUser?.providerData
          .any((provider) => provider.providerId == 'google.com') ??
      false;

  String get _accountEmail =>
      FirebaseAuth.instance.currentUser?.email ?? widget.profile.email;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.profile.photoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedImage = image;
        _imageBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select photo: $error')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final emailChanged = _isOwnProfile &&
        !widget.adminEditing &&
        _email.text.trim() != _accountEmail;
    try {
      var photoUrl = _photoUrl;
      if (_pickedImage != null && _imageBytes != null) {
        final ref = FirebaseStorage.instance.ref(
            'users/${widget.profile.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(_imageBytes!);
        photoUrl = await ref.getDownloadURL();
      }

      final service = UserProfileService();
      if (widget.adminEditing && !_isOwnProfile) {
        await service.updateManagedProfile(
          uid: widget.profile.id,
          name: _name.text,
          phone: _phone.text,
          address: _address.text,
        );
      } else {
        await service.updateProfile(
          uid: widget.profile.id,
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          address: _address.text,
          photoUrl: photoUrl,
          currentPassword: _currentPassword.text,
          newPassword: _newPassword.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailChanged
              ? 'Profile saved. Verify your new email to finish changing it.'
              : 'Profile updated.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not update profile: ${_errorMessage(error)}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'requires-recent-login' =>
          'Please verify your account again, then retry the change.',
        'email-already-in-use' => 'That email is already in use.',
        'invalid-credential' ||
        'wrong-password' =>
          'The current password was not accepted.',
        'weak-password' => 'Choose a stronger password.',
        _ => error.message ?? error.code,
      };
    }
    return error.toString().replaceFirst('Bad state: ', '');
  }

  Widget _sectionTitle(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final self = _isOwnProfile;
    final canEditAuth = self && !widget.adminEditing;
    final needsCurrentPassword = canEditAuth &&
        _hasPasswordProvider &&
        (_email.text.trim() != _accountEmail || _newPassword.text.isNotEmpty);
    final theme = Theme.of(context);
    final ImageProvider<Object>? currentPhoto = _imageBytes != null
        ? MemoryImage(_imageBytes!) as ImageProvider<Object>
        : _photoUrl.isNotEmpty
            ? NetworkImage(_photoUrl) as ImageProvider<Object>
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(self ? 'Edit profile' : 'Edit user'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Center(
                    child: InkWell(
                      onTap: _saving || (widget.adminEditing && !self)
                          ? null
                          : _pickPhoto,
                      borderRadius: BorderRadius.circular(64),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundImage: currentPhoto,
                                child: currentPhoto == null
                                    ? const Icon(Icons.person_outline, size: 42)
                                    : null,
                              ),
                              if (!widget.adminEditing || self)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: CircleAvatar(
                                    radius: 17,
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    child:
                                        const Icon(Icons.camera_alt, size: 17),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (!widget.adminEditing || self)
                            Text(
                              _imageBytes == null && _photoUrl.isEmpty
                                  ? 'Add a profile photo'
                                  : 'Change profile photo',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle(
                      context, Icons.person_outline, 'Personal details'),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Profile name',
                      hintText: 'Your name',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a profile name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: 'For delivery updates',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _address,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      alignLabelWithHint: true,
                      hintText: 'Your shipping address',
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle(context, Icons.lock_outline, 'Sign-in details'),
                  if (canEditAuth) ...[
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        hintText: 'you@example.com',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)
                            ? null
                            : 'Enter a valid email address';
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_hasPasswordProvider || _hasGoogleProvider) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _newPassword,
                        obscureText: !_showNewPassword,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'New password (optional)',
                          helperText: 'Use at least 8 characters.',
                          suffixIcon: IconButton(
                            tooltip: _showNewPassword
                                ? 'Hide password'
                                : 'Show password',
                            onPressed: () => setState(
                                () => _showNewPassword = !_showNewPassword),
                            icon: Icon(_showNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        validator: (value) => value != null &&
                                value.isNotEmpty &&
                                value.length < 8
                            ? 'Password must be at least 8 characters'
                            : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_hasGoogleProvider && !_hasPasswordProvider) ...[
                        const SizedBox(height: 8),
                        Text(
                          'This adds a password as another sign-in option. Google verification is required to secure the change.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (_newPassword.text.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPassword,
                          obscureText: !_showConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm new password',
                            suffixIcon: IconButton(
                              tooltip: _showConfirmPassword
                                  ? 'Hide password'
                                  : 'Show password',
                              onPressed: () => setState(() =>
                                  _showConfirmPassword = !_showConfirmPassword),
                              icon: Icon(_showConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                          ),
                          validator: (value) => value == _newPassword.text
                              ? null
                              : 'Passwords do not match',
                        ),
                      ],
                    ],
                    if (needsCurrentPassword) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _currentPassword,
                        obscureText: !_showCurrentPassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Current password',
                          suffixIcon: IconButton(
                            tooltip: _showCurrentPassword
                                ? 'Hide password'
                                : 'Show password',
                            onPressed: () => setState(() =>
                                _showCurrentPassword = !_showCurrentPassword),
                            icon: Icon(_showCurrentPassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your current password to continue'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Email changes take effect after you verify the link sent to the new address. ${_hasGoogleProvider ? 'Google sign-in verifies sensitive changes.' : 'Sensitive changes require recent sign-in.'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined),
                      title: Text(widget.profile.email),
                      subtitle: const Text(
                          'Email and password can only be changed by the account owner.'),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save changes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
