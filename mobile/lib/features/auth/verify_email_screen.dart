import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import 'auth_controller.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _otp = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final otp = _otp.text.trim();
    String? error;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      error = 'Enter a valid email address.';
    } else if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      error = 'Enter the 6-digit verification code.';
    }
    setState(() => _localError = error);
    if (error != null) return;

    final ok = await ref.read(authControllerProvider.notifier).verifyEmail(email, otp);
    if (!mounted || !ok) return;
    context.go('/login?verified=1');
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
                    Text('Verify your email', style: AppTheme.serif(size: 26, color: heading)),
                    const SizedBox(height: 4),
                    Text('Enter the 6-digit code we sent you',
                        style: TextStyle(fontSize: 13, color: heading.withValues(alpha: 0.6))),
                    const SizedBox(height: 20),
                    _field(_email, 'Email', Icons.alternate_email,
                        keyboard: TextInputType.emailAddress, textInputAction: TextInputAction.next),
                    const SizedBox(height: 14),
                    _field(
                      _otp,
                      'Verification code',
                      Icons.pin_outlined,
                      keyboard: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                      onSubmitted: (_) => _submit(),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 14),
                      Text(error, style: const TextStyle(color: AppColors.declined, fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    GradientButton(label: 'Verify email', loading: auth.loading, onPressed: _submit),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => context.go('/login'), child: const Text('Back to sign in')),
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
    TextInputType? keyboard,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}
