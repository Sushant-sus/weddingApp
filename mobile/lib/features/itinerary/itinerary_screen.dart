import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/forms.dart';
import '../events/event_providers.dart';
import 'itinerary_models.dart';
import 'itinerary_providers.dart';
import 'itinerary_form.dart';

// Category colours for the existing wedding itinerary enum.
const _categoryColors = {
  'CEREMONY': Color(0xFFE0A458),
  'RECEPTION': Color(0xFFD98A94),
  'RITUAL': Color(0xFFE08A58),
  'MEAL': Color(0xFF6FBF8E),
  'ENTERTAINMENT': Color(0xFFA88BD9),
  'OTHER': Color(0xFF94A0B0),
};
Color _catColor(String c) => _categoryColors[c] ?? _categoryColors['OTHER']!;
String _catLabel(String c) => c.isEmpty ? 'Other' : c[0] + c.substring(1).toLowerCase();

class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(selectedEventIdProvider);
    if (eventId == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    final async = ref.watch(itineraryProvider(eventId));
    final event = ref.watch(selectedEventProvider);
    final canEdit = event?.canEdit ?? false;
    final canManage = event?.canManage ?? false;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(itineraryProvider(eventId)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Itinerary', style: AppTheme.serif(size: 30, color: heading)),
                  Text('Your ceremony timeline', style: TextStyle(color: heading.withValues(alpha: 0.6))),
                ]),
              ),
              if (canEdit)
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onTap: () => showGlassSheet(context, (_) => ItineraryForm(eventId: eventId)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 18, color: AppColors.accentDeep),
                    SizedBox(width: 4),
                    Text('Add', style: TextStyle(color: AppColors.accentDeep, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ]),
            const SizedBox(height: 16),
            async.when(
              loading: () => AsyncStates.loading(),
              error: (e, _) => AsyncStates.error('$e', () => ref.invalidate(itineraryProvider(eventId))),
              data: (events) {
                if (events.isEmpty) {
                  return AsyncStates.empty(
                      context, Icons.event_note_outlined, 'No events yet', 'No itinerary events have been added.');
                }
                return Column(
                  children: [
                    for (var i = 0; i < events.length; i++)
                      _TimelineRow(
                        event: events[i],
                        isLast: i == events.length - 1,
                        index: i,
                        canEdit: canEdit,
                        canManage: canManage,
                        onEdit: () => showGlassSheet(context, (_) => ItineraryForm(eventId: eventId, event: events[i])),
                        onDelete: () async {
                          if (await confirmDelete(context, 'Delete event?', 'Remove "${events[i].title}"?')) {
                            await ref.read(itineraryRepoProvider).remove(eventId, events[i].id);
                          }
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.isLast,
    required this.index,
    this.canEdit = false,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
  });
  final ItineraryEvent event;
  final bool isLast;
  final int index;
  final bool canEdit;
  final bool canManage;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    final sub = heading.withValues(alpha: 0.65);
    final color = _catColor(event.category);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left rail: dot + connector.
          Column(children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
              ),
            ),
            if (!isLast)
              Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: color.withValues(alpha: 0.3))),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(event.title, style: AppTheme.serif(size: 19, color: heading))),
                    GlassChip(label: _catLabel(event.category), color: color),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.schedule, size: 15, color: sub),
                    const SizedBox(width: 6),
                    Text(
                      '${event.startTime}${event.endTime != null ? ' – ${event.endTime}' : ''} · ${formatDateLong(event.eventDate)}',
                      style: TextStyle(color: sub, fontSize: 13),
                    ),
                  ]),
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.place_outlined, size: 15, color: sub),
                      const SizedBox(width: 6),
                      Expanded(child: Text(event.location!, style: TextStyle(color: sub, fontSize: 13))),
                    ]),
                  ],
                  if (event.responsible != null && event.responsible!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.person_outline, size: 15, color: sub),
                      const SizedBox(width: 6),
                      Text(event.responsible!, style: TextStyle(color: sub, fontSize: 13)),
                    ]),
                  ],
                  if (event.description != null && event.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(event.description!, style: TextStyle(color: sub, fontSize: 13)),
                  ],
                  if (canEdit || canManage) ...[
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (canEdit)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit_outlined, size: 19, color: AppColors.accentDeep),
                          onPressed: onEdit,
                        ),
                      if (canManage)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.declined),
                          onPressed: () => onDelete?.call(),
                        ),
                    ]),
                  ],
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
