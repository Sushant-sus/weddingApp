import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/glass.dart';
import '../auth/auth_controller.dart';
import '../events/event_providers.dart';
import '../members/members_screen.dart';
import '../costs/costs_screen.dart';
import '../shell/placeholder_screen.dart';

/// "More" hub — secondary navigation to costs, marketplace, members, profile.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

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
          Text('More', style: AppTheme.serif(size: 30, color: heading)),
          const SizedBox(height: 16),
          _tile(context, Icons.account_balance_wallet_outlined, 'Cost Tracker',
              event?.canViewCosts == true ? 'Budget & payments' : 'Organisers only',
              () => _push(context, const CostsScreen())),
          _tile(context, Icons.storefront_outlined, 'Marketplace', 'Find providers & compare pitches',
              () => _push(context, const PlaceholderScreen(
                  title: 'Marketplace', icon: Icons.storefront_outlined, note: 'Provider browse & pitches — coming next.'))),
          _tile(
              context,
              Icons.group_outlined,
              'Members',
              event?.canManage == true ? 'Invite people & manage roles' : 'People with access to this event',
              () => _push(context, const MembersScreen())),
          const SizedBox(height: 8),
          GlassCard(
            child: Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.accent.withValues(alpha: 0.3),
                child: Text((user?.fullName ?? user?.email ?? '?').characters.first.toUpperCase(),
                    style: AppTheme.serif(size: 20, color: AppColors.accentDeep)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.fullName ?? 'Account', style: AppTheme.serif(size: 17, color: heading)),
                  Text(user?.email ?? '', style: TextStyle(fontSize: 12, color: heading.withValues(alpha: 0.6))),
                ]),
              ),
              GlassChip(label: user?.role ?? 'VIEWER', color: AppColors.accent),
            ]),
          ),
          const SizedBox(height: 14),
          GlassCard(
            onTap: () => context.go('/events'),
            child: Row(children: [
              const Icon(Icons.swap_horiz, color: AppColors.accentDeep),
              const SizedBox(width: 12),
              Expanded(child: Text('Switch event', style: TextStyle(fontWeight: FontWeight.w600, color: heading))),
              Icon(Icons.chevron_right, color: heading.withValues(alpha: 0.5)),
            ]),
          ),
          const SizedBox(height: 14),
          // Appearance — Light / Dark / System.
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.brightness_6_outlined, color: AppColors.accentDeep),
                const SizedBox(width: 12),
                Text('Appearance', style: TextStyle(fontWeight: FontWeight.w600, color: heading)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _themeOption(ref, heading, ThemeMode.system, 'System', Icons.brightness_auto),
                const SizedBox(width: 8),
                _themeOption(ref, heading, ThemeMode.light, 'Light', Icons.light_mode_outlined),
                const SizedBox(width: 8),
                _themeOption(ref, heading, ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
              ]),
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

  Widget _themeOption(WidgetRef ref, Color heading, ThemeMode mode, String label, IconData icon) {
    final active = ref.watch(themeModeProvider) == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeModeProvider.notifier).set(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.accent.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active ? AppColors.accentDeep.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.25)),
          ),
          child: Column(children: [
            Icon(icon, size: 20, color: active ? AppColors.accentDeep : heading.withValues(alpha: 0.6)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.accentDeep : heading.withValues(alpha: 0.7))),
          ]),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _Sub(child: screen)));
  }

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        child: Row(children: [
          Icon(icon, color: AppColors.accentDeep),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: heading, fontSize: 15)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: heading.withValues(alpha: 0.6))),
            ]),
          ),
          Icon(Icons.chevron_right, color: heading.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }
}

/// Wraps a pushed sub-screen in the gradient background with a back button.
class _Sub extends StatelessWidget {
  const _Sub({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    // Back button sits in its own row above the content so it never overlaps
    // the pushed screen's title.
    return GlassScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: GlassCard(
                padding: const EdgeInsets.all(8),
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
