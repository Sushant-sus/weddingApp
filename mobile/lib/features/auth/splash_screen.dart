import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';

/// Shown while the session is being restored, before auth status is known.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    return GlassScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Utsav', style: AppTheme.serif(size: 48, color: heading)),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
