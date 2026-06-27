import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/forms.dart';
import '../../core/widgets/glass.dart';
import '../auth/auth_controller.dart';
import 'event_form.dart';
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset('assets/brand/icon.webp', width: 34, height: 34, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Your events', style: AppTheme.serif(size: 30, color: heading))),
                  IconButton(
                    tooltip: 'Create event',
                    icon: Icon(Icons.add_circle_outline, color: heading.withValues(alpha: 0.75)),
                    onPressed: () => _showCreateEvent(context),
                  ),
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
                    ? _empty(context, heading)
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

  void _showCreateEvent(BuildContext context) {
    showGlassSheet(context, (_) => const EventForm());
  }

  Widget _empty(BuildContext context, Color heading) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          Icon(Icons.celebration_outlined, size: 48, color: heading.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No events present', style: AppTheme.serif(size: 22, color: heading)),
          const SizedBox(height: 6),
          Text(
            'Create your first wedding event or accept an invite to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: heading.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: GradientButton(label: 'Create event', icon: Icons.add, onPressed: () => _showCreateEvent(context)),
          ),
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

class _EventCard extends ConsumerStatefulWidget {
  const _EventCard({required this.event});
  final WeddingEvent event;

  @override
  ConsumerState<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<_EventCard> {
  bool _busy = false;

  WeddingEvent get event => widget.event;

  Future<void> _accept() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(eventRepoProvider).acceptInvite(event.id);
      if (!mounted) return;
      ref.read(selectedEventIdProvider.notifier).state = event.id;
      router.go('/app/dashboard');
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not accept invite.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    final ok = await confirmDelete(
        context, 'Decline invite', 'Decline the invite to "${event.name}"? It will be removed from your list.');
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(eventRepoProvider).declineInvite(event.id);
      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Invite declined')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not decline invite.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    final days = event.daysToWedding;
    final pending = event.isPending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        onTap: pending
            ? null
            : () {
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
            if (pending)
              _invitePrompt(heading)
            else
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

  Widget _invitePrompt(Color heading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const GlassChip(label: 'Invite pending', color: AppColors.pending, icon: Icons.mail_outline),
          const SizedBox(width: 8),
          Flexible(
            child: Text('You were invited as ${event.myRole.toLowerCase()}.',
                style: TextStyle(fontSize: 12, color: heading.withValues(alpha: 0.6))),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: GradientButton(
              label: 'Accept',
              icon: Icons.check,
              loading: _busy,
              onPressed: _busy ? null : _accept,
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _busy ? null : _decline,
            child: const Text('Decline', style: TextStyle(color: AppColors.declined)),
          ),
        ]),
      ],
    );
  }
}
