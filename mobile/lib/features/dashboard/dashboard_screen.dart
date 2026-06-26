import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../events/event_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(selectedEventProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    if (event == null) return const SizedBox.shrink();

    final days = event.daysToWedding;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Row(
            children: [
              Expanded(child: Text('YOUR CELEBRATION', style: AppTheme.eyebrow(AppColors.accentDeep))),
              IconButton(
                tooltip: 'Switch event',
                icon: Icon(Icons.swap_horiz, color: heading.withValues(alpha: 0.7)),
                onPressed: () => context.go('/events'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Hero card.
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name, style: AppTheme.serif(size: 30, color: heading, height: 1.1)),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.event, size: 16, color: heading.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(DateFormat('EEEE, d MMMM yyyy').format(event.weddingDate),
                      style: TextStyle(color: heading.withValues(alpha: 0.7))),
                ]),
                if (event.venue != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.place_outlined, size: 16, color: heading.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(event.venue!, style: TextStyle(color: heading.withValues(alpha: 0.7)))),
                  ]),
                ],
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(days >= 0 ? '$days' : '—',
                        style: AppTheme.serif(size: 56, color: AppColors.accentDeep, height: 1)),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(days >= 0 ? 'days to go' : 'celebrated',
                          style: TextStyle(color: heading.withValues(alpha: 0.7), fontSize: 15)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _stat(heading, Icons.group_outlined, '${event.memberCount}', 'Members')),
            const SizedBox(width: 12),
            Expanded(child: _stat(heading, Icons.diversity_3_outlined, '${event.guestCount ?? '—'}', 'Guests')),
            const SizedBox(width: 12),
            Expanded(child: _stat(heading, Icons.workspace_premium_outlined, event.myRole, 'Your role')),
          ]),
          const SizedBox(height: 14),
          GlassCard(
            child: Row(children: [
              const Icon(Icons.auto_awesome, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Open the Itinerary tab to build your ceremony timeline and request services.',
                    style: TextStyle(color: heading.withValues(alpha: 0.75), fontSize: 13)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _stat(Color heading, IconData icon, String value, String label) => GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: AppColors.accentDeep),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.serif(size: 20, color: heading), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(fontSize: 11, color: heading.withValues(alpha: 0.6))),
        ]),
      );
}
