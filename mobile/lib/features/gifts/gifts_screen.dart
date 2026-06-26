import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/forms.dart';
import '../events/event_providers.dart';
import 'gift_models.dart';
import 'gift_providers.dart';
import 'gift_form.dart';
import 'gift_desk_screen.dart';

class GiftsScreen extends ConsumerWidget {
  const GiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(selectedEventIdProvider);
    if (eventId == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    final giftsAsync = ref.watch(giftsProvider(eventId));
    final summaryAsync = ref.watch(giftSummaryProvider(eventId));
    final event = ref.watch(selectedEventProvider);
    final canContribute = event?.canContribute ?? false;
    final canEdit = event?.canEdit ?? false;
    final canManage = event?.canManage ?? false;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(giftsProvider(eventId));
          ref.invalidate(giftSummaryProvider(eventId));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            Row(children: [
              Expanded(child: Text('Gifts', style: AppTheme.serif(size: 30, color: heading))),
              if (canContribute)
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GiftDeskScreen(eventId: eventId)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.point_of_sale, size: 18, color: AppColors.accentDeep),
                    SizedBox(width: 6),
                    Text('Record', style: TextStyle(color: AppColors.accentDeep, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ]),
            const SizedBox(height: 14),
            summaryAsync.when(
              loading: () => const SizedBox(height: 84, child: Center(child: CircularProgressIndicator())),
              error: (_, _) => const SizedBox.shrink(),
              data: (s) => Row(children: [
                Expanded(child: SummaryTile(icon: Icons.payments_outlined, value: formatInr(s.totalCash), label: 'Cash')),
                const SizedBox(width: 12),
                Expanded(child: SummaryTile(icon: Icons.card_giftcard, value: '${s.kindItems}', label: 'In-kind')),
                const SizedBox(width: 12),
                Expanded(child: SummaryTile(icon: Icons.inventory_2_outlined, value: '${s.totalGifts}', label: 'Total')),
              ]),
            ),
            const SizedBox(height: 16),
            giftsAsync.when(
              loading: () => AsyncStates.loading(),
              error: (e, _) => AsyncStates.error('$e', () => ref.invalidate(giftsProvider(eventId))),
              data: (gifts) => gifts.isEmpty
                  ? AsyncStates.empty(context, Icons.card_giftcard, 'No gifts yet', 'Gifts recorded against guests appear here.')
                  : Column(children: [
                      for (final g in gifts)
                        _GiftCard(
                          gift: g,
                          canEdit: canEdit,
                          canManage: canManage,
                          onEdit: () => showGlassSheet(context, (_) => GiftForm(eventId: eventId, gift: g)),
                          onDelete: () async {
                            if (await confirmDelete(context, 'Delete gift?', 'Remove this gift from ${g.familyName}?')) {
                              await ref.read(giftRepoProvider).remove(eventId, g.id);
                            }
                          },
                        ),
                    ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({required this.gift, this.canEdit = false, this.canManage = false, this.onEdit, this.onDelete});
  final Gift gift;
  final bool canEdit;
  final bool canManage;
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
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (gift.isCash ? AppColors.booked : AppColors.categoryColor('sangeet')).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(gift.isCash ? Icons.payments_outlined : Icons.card_giftcard,
                color: gift.isCash ? AppColors.booked : AppColors.categoryColor('sangeet')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(gift.familyName, style: AppTheme.serif(size: 17, color: heading)),
              const SizedBox(height: 2),
              Text(
                gift.isCash
                    ? 'Cash · ${DateFormat('d MMM yyyy').format(gift.receivedAt)}'
                    : '${gift.description ?? 'In-kind gift'} · ${DateFormat('d MMM yyyy').format(gift.receivedAt)}',
                style: TextStyle(color: sub, fontSize: 13),
              ),
              if (gift.remarks != null && gift.remarks!.isNotEmpty)
                Text(gift.remarks!, style: TextStyle(color: sub, fontSize: 12)),
            ]),
          ),
          if (gift.isCash && gift.amount != null)
            Text(formatInr(gift.amount), style: AppTheme.serif(size: 18, color: AppColors.accentDeep)),
          if (canEdit || canManage)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20, color: heading.withValues(alpha: 0.6)),
              onSelected: (v) {
                if (v == 'edit') onEdit?.call();
                if (v == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
                if (canEdit) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (canManage) const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ]),
      ),
    );
  }
}
