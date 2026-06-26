import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../auth/auth_controller.dart';
import 'event_models.dart';
import 'event_providers.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;

    return GlassScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(eventsProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Row(
                children: [
                  Expanded(child: Text('Your events', style: AppTheme.serif(size: 30, color: heading))),
                  IconButton(
                    tooltip: 'Sign out',
                    icon: Icon(Icons.logout, color: heading.withValues(alpha: 0.7)),
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              eventsAsync.when(
                loading: () => const Padding(
                    padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => _error(context, '$e', () => ref.refresh(eventsProvider)),
                data: (events) => events.isEmpty
                    ? _empty(heading)
                    : Column(
                        children: [for (final e in events) _EventCard(event: e)],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(Color heading) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          Icon(Icons.celebration_outlined, size: 48, color: heading.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No events yet', style: AppTheme.serif(size: 22, color: heading)),
          const SizedBox(height: 6),
          Text('Create your first wedding to get started.',
              style: TextStyle(color: heading.withValues(alpha: 0.6))),
        ]),
      );

  Widget _error(BuildContext context, String msg, VoidCallback retry) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          const Icon(Icons.cloud_off, size: 40, color: AppColors.declined),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: retry, child: const Text('Retry')),
        ]),
      );
}

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.event});
  final WeddingEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    final days = event.daysToWedding;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        onTap: () {
          ref.read(selectedEventIdProvider.notifier).state = event.id;
          context.go('/app/dashboard');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(event.name, style: AppTheme.serif(size: 22, color: heading))),
                GlassChip(label: event.myRole, color: AppColors.accent),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.event, size: 15, color: heading.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(DateFormat('EEE, d MMM yyyy').format(event.weddingDate),
                  style: TextStyle(color: heading.withValues(alpha: 0.7), fontSize: 13)),
            ]),
            if (event.venue != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.place_outlined, size: 15, color: heading.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(event.venue!,
                        style: TextStyle(color: heading.withValues(alpha: 0.7), fontSize: 13))),
              ]),
            ],
            const SizedBox(height: 12),
            Row(children: [
              if (days >= 0)
                GlassChip(label: '$days days to go', color: AppColors.pending, icon: Icons.timer_outlined)
              else
                GlassChip(label: 'Completed', color: AppColors.booked, icon: Icons.check),
              const SizedBox(width: 8),
              GlassChip(label: '${event.memberCount} members', color: AppColors.accent, icon: Icons.group_outlined),
            ]),
          ],
        ),
      ),
    );
  }
}
