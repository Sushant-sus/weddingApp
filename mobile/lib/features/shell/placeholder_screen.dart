import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, required this.icon, required this.note});
  final String title;
  final IconData icon;
  final String note;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: GlassCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: AppColors.accent),
                const SizedBox(height: 14),
                Text(title, style: AppTheme.serif(size: 26, color: heading)),
                const SizedBox(height: 8),
                Text(note, textAlign: TextAlign.center, style: TextStyle(color: heading.withValues(alpha: 0.65))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
