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

// Category colours for the wedding itinerary enum.
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

class ItineraryScreen extends ConsumerStatefulWidget {
  const ItineraryScreen({super.key});
  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  // Local ordered copy so dragging/status changes feel instant; kept in sync
  // with the server via a listener (below).
  List<ItineraryEvent> _items = [];

  void _sync(List<ItineraryEvent> list) {
    if (mounted) setState(() => _items = [...list]);
  }

  // newIndex is already adjusted for the removed item (onReorderItem semantics).
  Future<void> _onReorder(String eventId, int oldIndex, int newIndex) async {
    setState(() {
      final moved = _items.removeAt(oldIndex);
      _items.insert(newIndex, moved);
    });
    final order = [
      for (var i = 0; i < _items.length; i++) {'id': _items[i].id, 'orderIndex': i},
    ];
    try {
      await ref.read(itineraryRepoProvider).reorder(eventId, order);
    } catch (_) {
      ref.invalidate(itineraryProvider(eventId));
      _toast('Could not save the new order');
    }
  }

  Future<void> _setStatus(String eventId, ItineraryEvent e, String status) async {
    setState(() {
      final i = _items.indexWhere((x) => x.id == e.id);
      if (i != -1) _items[i] = _items[i].copyWith(status: status);
    });
    try {
      await ref.read(itineraryRepoProvider).setStatus(eventId, e.id, status);
    } catch (_) {
      ref.invalidate(itineraryProvider(eventId));
      _toast('Could not update status');
    }
  }

  void _toast(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(selectedEventIdProvider);
    if (eventId == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    final event = ref.watch(selectedEventProvider);
    final canEdit = event?.canEdit ?? false;
    final canManage = event?.canManage ?? false;

    // Keep the local list in sync whenever the server data changes.
    ref.listen(itineraryProvider(eventId), (_, next) => next.whenData(_sync));
    final async = ref.watch(itineraryProvider(eventId));

    Widget body;
    if (_items.isEmpty && async.isLoading) {
      body = AsyncStates.loading();
    } else if (_items.isEmpty && async.hasError) {
      body = AsyncStates.error('${async.error}', () => ref.invalidate(itineraryProvider(eventId)));
    } else if (_items.isEmpty) {
      body = AsyncStates.empty(context, Icons.event_note_outlined, 'No events yet', 'Add your first ceremony event.');
    } else {
      body = ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.only(bottom: 110),
        itemCount: _items.length,
        onReorderItem: (o, n) => _onReorder(eventId, o, n),
        itemBuilder: (ctx, i) => _EventCard(
          key: ValueKey(_items[i].id),
          event: _items[i],
          index: i,
          canEdit: canEdit,
          canManage: canManage,
          onEdit: () => showGlassSheet(context, (_) => ItineraryForm(eventId: eventId, event: _items[i])),
          onDelete: () async {
            if (await confirmDelete(context, 'Delete event?', 'Remove "${_items[i].title}"?')) {
              await ref.read(itineraryRepoProvider).remove(eventId, _items[i].id);
            }
          },
          onToggleDone: () => _setStatus(eventId, _items[i], _items[i].isDone ? 'PLANNED' : 'DONE'),
          onToggleCancel: () => _setStatus(eventId, _items[i], _items[i].isCancelled ? 'PLANNED' : 'CANCELLED'),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Itinerary', style: AppTheme.serif(size: 30, color: heading)),
                  Text(canEdit ? 'Drag to reorder · tap ✓ to complete' : 'Your ceremony timeline',
                      style: TextStyle(color: heading.withValues(alpha: 0.6), fontSize: 12)),
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
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(itineraryProvider(eventId)),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    super.key,
    required this.event,
    required this.index,
    required this.canEdit,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleDone,
    required this.onToggleCancel,
  });

  final ItineraryEvent event;
  final int index;
  final bool canEdit;
  final bool canManage;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    final sub = heading.withValues(alpha: 0.65);
    final color = _catColor(event.category);
    final dim = event.isCancelled ? 0.5 : (event.isDone ? 0.8 : 1.0);
    final strike = event.isCancelled;

    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Opacity(
        opacity: dim,
        child: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (canEdit)
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.drag_indicator, color: heading.withValues(alpha: 0.4)),
                  ),
                ),
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: AppTheme.serif(size: 19, color: heading).copyWith(
                    decoration: strike ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (event.isDone) StatusBadge(label: 'Done', color: AppColors.booked),
              if (event.isCancelled) StatusBadge(label: 'Cancelled', color: AppColors.declined),
              if (!event.isDone && !event.isCancelled)
                GlassChip(label: _catLabel(event.category), color: color),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.schedule, size: 15, color: sub),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${event.startTime}${event.endTime != null ? ' – ${event.endTime}' : ''} · ${formatDateLong(event.eventDate)}',
                  style: TextStyle(color: sub, fontSize: 13),
                ),
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
            if (canEdit) ...[
              const Divider(height: 18),
              Row(children: [
                // Complete (tick)
                _ActionBtn(
                  icon: event.isDone ? Icons.check_circle : Icons.check_circle_outline,
                  color: AppColors.booked,
                  label: event.isDone ? 'Completed' : 'Complete',
                  onTap: onToggleDone,
                ),
                const SizedBox(width: 6),
                // Cancel
                _ActionBtn(
                  icon: event.isCancelled ? Icons.cancel : Icons.cancel_outlined,
                  color: AppColors.declined,
                  label: event.isCancelled ? 'Cancelled' : 'Cancel',
                  onTap: onToggleCancel,
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 19, color: AppColors.accentDeep),
                  onPressed: onEdit,
                ),
                if (canManage)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.declined),
                    onPressed: () => onDelete(),
                  ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.color, required this.label, required this.onTap});
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
