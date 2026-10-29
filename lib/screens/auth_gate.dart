import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/tech_ui.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// Decides what to show: spinner -> login -> main app.
/// It rebuilds automatically whenever the user logs in or out.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TechBrandLockup(showDescriptor: true),
              const SizedBox(height: 28),
              const SizedBox(
                width: 140,
                child: LinearProgressIndicator(),
              ),
              const SizedBox(height: 12),
              Text(
                'CONNECTING TO SHOP',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      );
    }
    return auth.user == null
        ? const LoginScreen()
        : MainShell(key: mainShellKey);
  }
}
