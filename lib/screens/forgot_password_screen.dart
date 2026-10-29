import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/tech_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    String? error;
    try {
      error = await context
          .read<AuthProvider>()
          .sendPasswordResetEmail(_email.text.trim());
    } on PlatformException catch (e) {
      error =
          'Could not contact Firebase. Check your connection and try again.';
      debugPrint('Password reset request failed: ${e.message ?? e.code}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    setState(() {
      _error = error;
      _sent = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TechBrandLockup(showDescriptor: true),
                    const SizedBox(height: 16),
                    const TechEyebrow('Account recovery'),
                    const SizedBox(height: 10),
                    Text(
                      _sent ? 'Check your email' : 'Forgot your password?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sent
                          ? 'If ${_email.text.trim()} has an email-and-password account, Firebase will send a reset link. Check your inbox and spam folder. Google accounts should sign in with Google instead.'
                          : 'Enter the email address for your email-and-password account. Firebase will send a reset link to that address.',
                      textAlign: TextAlign.center,
                    ),
                    if (!_sent) ...[
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) => value != null &&
                                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(value.trim())
                            ? null
                            : 'Enter a valid email',
                        onFieldSubmitted: (_) {
                          if (!_busy) _submit();
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Send reset link'),
                      ),
                    ] else ...[
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to sign in'),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _sent = false;
                                  _error = null;
                                }),
                        child: const Text('Try another email'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
