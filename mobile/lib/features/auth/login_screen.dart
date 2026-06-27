import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.verified = false});

  final bool verified;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;

    return GlassScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: GlassCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/brand/logo.webp', width: 240, fit: BoxFit.contain),
                    const SizedBox(height: 24),
                    _field(_email, 'Email', Icons.alternate_email, keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _field(_password, 'Password', Icons.lock_outline,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        )),
                    if (widget.verified) ...[
                      const SizedBox(height: 14),
                      const Text('Email verified. You can now sign in.',
                          style: TextStyle(color: AppColors.booked, fontSize: 13)),
                    ],
                    if (auth.error != null) ...[
                      const SizedBox(height: 14),
                      Text(auth.error!, style: const TextStyle(color: AppColors.declined, fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'Sign in',
                      loading: auth.loading,
                      onPressed: () => ref
                          .read(authControllerProvider.notifier)
                          .login(_email.text.trim(), _password.text),
                    ),
                    const SizedBox(height: 12),
                    Text('Use your event organiser account',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: heading.withValues(alpha: 0.5))),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('New here? ',
                            style: TextStyle(fontSize: 12, color: heading.withValues(alpha: 0.6))),
                        TextButton(onPressed: () => context.go('/register'), child: const Text('Create account')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool obscure = false, Widget? suffix, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}
