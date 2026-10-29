import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/tech_ui.dart';
import '../profile_edit_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _service = UserProfileService();
  final _search = TextEditingController();
  final Set<String> _updatingRoles = {};
  late Future<ManagedUserDirectory> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _service.loadUsers();
  }

  void _reloadUsers() {
    setState(() {
      _usersFuture = _service.loadUsers();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _editUser(UserProfile profile) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProfileEditScreen(
        profile: profile,
        adminEditing: profile.id != FirebaseAuth.instance.currentUser?.uid,
      ),
    ));
    if (mounted) _reloadUsers();
  }

  Future<void> _changeRole(UserProfile profile) async {
    final newRole = profile.role == 'admin' ? 'customer' : 'admin';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change user role?'),
        content: Text(
            'Change ${profile.email} from ${profile.role} to $newRole? Admins can manage products and user roles.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Change role'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updatingRoles.add(profile.id));
    try {
      await _service.updateRole(profile.id, newRole);
      if (!mounted) return;
      _reloadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${profile.email} is now $newRole.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not change role: $error')),
      );
    } finally {
      if (mounted) setState(() => _updatingRoles.remove(profile.id));
    }
  }

  Future<void> _changeAccountStatus(UserProfile profile) async {
    final disable = !profile.isDisabled;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(disable ? 'Disable account?' : 'Enable account?'),
        content: Text(disable
            ? 'Block ${profile.email} from using the app? They will be signed out and remain blocked until the account is enabled.'
            : 'Allow ${profile.email} to use the app again?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(disable ? 'Disable account' : 'Enable account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updatingRoles.add(profile.id));
    try {
      await _service.setDisabled(profile.id, disable);
      if (!mounted) return;
      _reloadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${profile.email} account ${disable ? 'disabled' : 'enabled'}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update account status: $error')),
      );
    } finally {
      if (mounted) setState(() => _updatingRoles.remove(profile.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage users'),
        actions: [
          IconButton(
            tooltip: 'Refresh users',
            onPressed: _reloadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: TechPageIntro(
              eyebrow: 'Administration / access',
              title: 'Manage users.',
              description: 'Review accounts, roles, and sign-in availability.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Clear search',
                  onPressed: _search.clear,
                  icon: const Icon(Icons.clear),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<ManagedUserDirectory>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Could not load users: ${snapshot.error}'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _reloadUsers,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final directory = snapshot.data!;
                final query = _search.text.trim().toLowerCase();
                final users = directory.users
                    .where((user) =>
                        user.name.toLowerCase().contains(query) ||
                        user.email.toLowerCase().contains(query) ||
                        user.phone.toLowerCase().contains(query) ||
                        user.id.toLowerCase().contains(query))
                    .toList();
                if (users.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }
                return Column(
                  children: [
                    if (!directory.authAccountsAvailable)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          'Showing saved user profiles. Firebase Authentication '
                          'account listing is not enabled for the server.',
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${users.length} ${users.length == 1 ? 'ACCOUNT' : 'ACCOUNTS'}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final profile = users[index];
                          final busy = _updatingRoles.contains(profile.id);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: profile.photoUrl.isEmpty
                                    ? null
                                    : NetworkImage(profile.photoUrl),
                                child: profile.photoUrl.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(profile.name.isEmpty
                                  ? (profile.email.isEmpty
                                      ? 'Unnamed user'
                                      : profile.email)
                                  : profile.name),
                              subtitle: Text(
                                  '${profile.email.isEmpty ? profile.id : profile.email}'
                                  '${profile.pendingEmail == null ? '' : '\nPending email: ${profile.pendingEmail}'}'
                                  '\n${profile.role.toUpperCase()}'
                                  '${profile.isDisabled ? ' · DISABLED' : ''}'),
                              isThreeLine: true,
                              trailing: busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : PopupMenuButton<String>(
                                      tooltip: 'User actions',
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          _editUser(profile);
                                        } else if (action == 'role') {
                                          _changeRole(profile);
                                        } else if (action == 'disable' ||
                                            action == 'enable') {
                                          _changeAccountStatus(profile);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(Icons.edit_outlined),
                                            title: Text('Edit profile'),
                                          ),
                                        ),
                                        if (profile.id != currentUid)
                                          PopupMenuItem(
                                            value: 'role',
                                            child: ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: const Icon(Icons
                                                  .admin_panel_settings_outlined),
                                              title: Text(
                                                  profile.role == 'admin'
                                                      ? 'Make customer'
                                                      : 'Make admin'),
                                            ),
                                          ),
                                        if (profile.id != currentUid)
                                          PopupMenuItem(
                                            value: profile.isDisabled
                                                ? 'enable'
                                                : 'disable',
                                            child: ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: Icon(profile.isDisabled
                                                  ? Icons.check_circle_outline
                                                  : Icons.block_outlined),
                                              title: Text(profile.isDisabled
                                                  ? 'Enable account'
                                                  : 'Disable account'),
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
