import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _localError;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _validate() {
    final name = _fullName.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (name.length < 2) return 'Enter your full name.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Enter a valid email address.';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Password must contain an uppercase letter.';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Password must contain a number.';
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) return 'Password must contain a special character.';
    if (password != _confirmPassword.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    setState(() => _localError = error);
    if (error != null) return;

    final ok = await ref.read(authControllerProvider.notifier).register(
          fullName: _fullName.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          confirmPassword: _confirmPassword.text,
        );
    if (!mounted || !ok) return;
    context.go('/verify-email?email=${Uri.encodeComponent(_email.text.trim())}');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    final error = _localError ?? auth.error;

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
                    Image.asset('assets/brand/logo.webp', width: 220, fit: BoxFit.contain),
                    const SizedBox(height: 22),
                    Text('Create your account', style: AppTheme.serif(size: 26, color: heading)),
                    const SizedBox(height: 4),
                    Text('Start planning your wedding',
                        style: TextStyle(fontSize: 13, color: heading.withValues(alpha: 0.6))),
                    const SizedBox(height: 20),
                    _field(_fullName, 'Full name', Icons.person_outline, textInputAction: TextInputAction.next),
                    const SizedBox(height: 14),
                    _field(_email, 'Email', Icons.alternate_email,
                        keyboard: TextInputType.emailAddress, textInputAction: TextInputAction.next),
                    const SizedBox(height: 14),
                    _field(
                      _password,
                      'Password',
                      Icons.lock_outline,
                      obscure: _obscure,
                      textInputAction: TextInputAction.next,
                      suffix: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      _confirmPassword,
                      'Confirm password',
                      Icons.lock_outline,
                      obscure: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 14),
                      Text(error, style: const TextStyle(color: AppColors.declined, fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    GradientButton(label: 'Create account', loading: auth.loading, onPressed: _submit),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: TextStyle(fontSize: 12, color: heading.withValues(alpha: 0.6))),
                        TextButton(onPressed: () => context.go('/login'), child: const Text('Sign in')),
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

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
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
