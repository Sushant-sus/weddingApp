import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../auth/auth_controller.dart';
import '../events/event_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final event = ref.watch(selectedEventProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Text('Profile', style: AppTheme.serif(size: 30, color: heading)),
          const SizedBox(height: 16),
          GlassCard(
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.accent.withValues(alpha: 0.3),
                child: Text(
                  (user?.fullName ?? user?.email ?? '?').characters.first.toUpperCase(),
                  style: AppTheme.serif(size: 24, color: AppColors.accentDeep),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.fullName ?? 'Account',
                      style: AppTheme.serif(size: 20, color: heading)),
                  Text(user?.email ?? '', style: TextStyle(color: heading.withValues(alpha: 0.65), fontSize: 13)),
                  const SizedBox(height: 6),
                  GlassChip(label: user?.role ?? 'VIEWER', color: AppColors.accent),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          GlassCard(
            onTap: () => context.go('/events'),
            child: Row(children: [
              const Icon(Icons.swap_horiz, color: AppColors.accentDeep),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Switch event', style: TextStyle(fontWeight: FontWeight.w600, color: heading)),
                  if (event != null)
                    Text('Current: ${event.name}',
                        style: TextStyle(fontSize: 12, color: heading.withValues(alpha: 0.6))),
                ]),
              ),
              Icon(Icons.chevron_right, color: heading.withValues(alpha: 0.5)),
            ]),
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Sign out',
            icon: Icons.logout,
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
