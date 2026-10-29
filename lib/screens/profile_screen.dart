import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../services/user_profile_service.dart';
import '../widgets/tech_ui.dart';
import 'admin/add_product_screen.dart';
import 'admin/manage_products_screen.dart';
import 'admin/manage_users_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Stream<UserProfile?> _profileStream;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user?.uid;
    _profileStream = uid == null
        ? Stream<UserProfile?>.value(null)
        : UserProfileService().streamProfile(uid);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('Please sign in again.'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: StreamBuilder<UserProfile?>(
                  stream: _profileStream,
                  builder: (context, snapshot) {
                    final profile = snapshot.data ??
                        UserProfile(
                          id: user.uid,
                          name: user.displayName ?? '',
                          email: user.email ?? '',
                          phone: '',
                          address: '',
                          photoUrl: user.photoURL ?? '',
                          pendingEmail: null,
                          role: auth.role,
                          isDisabled: false,
                        );
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 42,
                            backgroundImage: profile.photoUrl.isEmpty
                                ? null
                                : NetworkImage(profile.photoUrl),
                            child: profile.photoUrl.isEmpty
                                ? const Icon(Icons.person, size: 42)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            profile.name.isEmpty ? profile.email : profile.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Center(child: Text(profile.email)),
                        if (profile.pendingEmail != null)
                          Center(
                            child: Text(
                              'Email verification pending: '
                              '${profile.pendingEmail}',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        Center(
                          child: TechStatusLabel(
                            status:
                                profile.isDisabled ? 'disabled' : profile.role,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.manage_accounts_outlined),
                            title: const Text('Edit my profile'),
                            subtitle: const Text(
                              'Name, email, password and contact details',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProfileEditScreen(profile: profile),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (auth.isAdmin) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                            child: TechEyebrow(
                              'Administration',
                              icon: Icons.admin_panel_settings_outlined,
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.add_box_outlined),
                            title: const Text('Add product'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddProductScreen(),
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: const Text('Manage products'),
                            subtitle: const Text('Edit or delete products'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ManageProductsScreen(),
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.people_outline),
                            title: const Text('Manage users'),
                            subtitle: const Text('Edit profiles and roles'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ManageUsersScreen(),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Log out'),
                          onTap: () => context.read<AuthProvider>().signOut(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}
