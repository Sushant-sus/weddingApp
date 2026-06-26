import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../auth/auth_controller.dart';
import '../events/event_providers.dart';
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
          _tile(context, Icons.group_outlined, 'Members', 'People with access to this event',
              () => _push(context, const PlaceholderScreen(
                  title: 'Members', icon: Icons.group_outlined, note: 'Sharing & roles — coming next.'))),
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
          GradientButton(
            label: 'Sign out',
            icon: Icons.logout,
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
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
    return GlassScaffold(
      body: Stack(children: [
        child,
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.topLeft,
              child: GlassCard(
                padding: const EdgeInsets.all(8),
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
