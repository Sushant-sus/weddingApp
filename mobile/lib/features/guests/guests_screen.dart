import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/forms.dart';
import '../events/event_providers.dart';
import 'guest_models.dart';
import 'guest_providers.dart';
import 'guest_form.dart';

class GuestsScreen extends ConsumerStatefulWidget {
  const GuestsScreen({super.key});
  @override
  ConsumerState<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends ConsumerState<GuestsScreen> {
  String _search = '';
  String? _rsvp; // null = all

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(selectedEventIdProvider);
    if (eventId == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;

    final guestsAsync = ref.watch(guestsProvider(eventId));
    final summaryAsync = ref.watch(guestSummaryProvider(eventId));
    final event = ref.watch(selectedEventProvider);
    final canContribute = event?.canContribute ?? false;
    final canEdit = event?.canEdit ?? false;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(guestsProvider(eventId));
          ref.invalidate(guestSummaryProvider(eventId));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            Row(children: [
              Expanded(child: Text('Guests', style: AppTheme.serif(size: 30, color: heading))),
              if (canContribute)
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onTap: () => showGlassSheet(context, (_) => GuestForm(eventId: eventId)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 18, color: AppColors.accentDeep),
                    SizedBox(width: 4),
                    Text('Add', style: TextStyle(color: AppColors.accentDeep, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ]),
            const SizedBox(height: 14),
            summaryAsync.when(
              loading: () => const SizedBox(height: 84, child: Center(child: CircularProgressIndicator())),
              error: (_, _) => const SizedBox.shrink(),
              data: (s) => Row(children: [
                Expanded(child: SummaryTile(icon: Icons.groups_outlined, value: '${s.families}', label: 'Families')),
                const SizedBox(width: 12),
                Expanded(child: SummaryTile(icon: Icons.person_add_alt, value: '${s.estimated}', label: 'Est.')),
                const SizedBox(width: 12),
                Expanded(child: SummaryTile(icon: Icons.how_to_reg_outlined, value: '${s.confirmed}', label: 'Confirmed')),
              ]),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name, phone, remarks…',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              _filterChip('All', null),
              _filterChip('Confirmed', 'CONFIRMED'),
              _filterChip('Pending', 'PENDING'),
              _filterChip('Declined', 'DECLINED'),
            ]),
            const SizedBox(height: 14),
            guestsAsync.when(
              loading: () => AsyncStates.loading(),
              error: (e, _) => AsyncStates.error('$e', () => ref.invalidate(guestsProvider(eventId))),
              data: (guests) {
                final filtered = guests.where((g) {
                  if (_rsvp != null && g.rsvpStatus != _rsvp) return false;
                  if (_search.isEmpty) return true;
                  return [g.familyName, g.contactPhone, g.remarks]
                      .any((v) => (v ?? '').toLowerCase().contains(_search));
                }).toList();
                if (filtered.isEmpty) {
                  return AsyncStates.empty(context, Icons.diversity_3_outlined, 'No guests',
                      guests.isEmpty ? 'No guests added yet.' : 'No guests match your filters.');
                }
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${filtered.length} of ${guests.length} families',
                          style: TextStyle(fontSize: 12, color: heading.withValues(alpha: 0.6))),
                    ),
                  ),
                  for (final g in filtered)
                    _GuestCard(
                      guest: g,
                      canEdit: canEdit,
                      onEdit: () => showGlassSheet(context, (_) => GuestForm(eventId: eventId, guest: g)),
                      onDelete: () async {
                        if (await confirmDelete(context, 'Delete guest?', 'Remove ${g.familyName}?')) {
                          await ref.read(guestRepoProvider).remove(eventId, g.id);
                        }
                      },
                    ),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _rsvp == value;
    return GestureDetector(
      onTap: () => setState(() => _rsvp = value),
      child: GlassChip(
        label: label,
        color: selected ? AppColors.accentDeep : AppColors.accent.withValues(alpha: 0.5),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.guest, this.canEdit = false, this.onEdit, this.onDelete});
  final Guest guest;
  final bool canEdit;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    final sub = heading.withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(guest.familyName, style: AppTheme.serif(size: 19, color: heading))),
            StatusBadge(label: guest.rsvpStatus, color: StatusBadge.rsvp(guest.rsvpStatus)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            GlassChip(label: guest.familyType == 'CHULEY' ? 'Chuley' : 'Single', color: AppColors.accent),
            GlassChip(label: guest.side, color: AppColors.categoryColor('sangeet')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.groups_outlined, size: 15, color: sub),
            const SizedBox(width: 6),
            Text(
              '${guest.attendeeCount} est${guest.confirmedCount != null ? ' · ${guest.confirmedCount} conf' : ''}',
              style: TextStyle(color: sub, fontSize: 13),
            ),
            if (guest.contactPhone != null) ...[
              const SizedBox(width: 14),
              Icon(Icons.phone_outlined, size: 15, color: AppColors.accentDeep),
              const SizedBox(width: 6),
              Text(guest.contactPhone!, style: const TextStyle(color: AppColors.accentDeep, fontSize: 13)),
            ],
          ]),
          if (guest.remarks != null && guest.remarks!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(guest.remarks!, style: TextStyle(color: sub, fontSize: 13)),
          ],
          if (canEdit) ...[
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 19, color: AppColors.accentDeep),
                onPressed: onEdit,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.declined),
                onPressed: () => onDelete?.call(),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
