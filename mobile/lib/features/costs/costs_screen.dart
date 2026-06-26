import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/forms.dart';
import '../events/event_providers.dart';
import 'cost_models.dart';
import 'cost_providers.dart';
import 'cost_form.dart';

class CostsScreen extends ConsumerWidget {
  const CostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(selectedEventIdProvider);
    final event = ref.watch(selectedEventProvider);
    if (eventId == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;

    // Costs are organiser-only; the backend also enforces this with a 403.
    if (event != null && !event.canViewCosts) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: GlassCard(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_outline, size: 44, color: AppColors.accent),
                const SizedBox(height: 14),
                Text('Costs are private', style: AppTheme.serif(size: 22, color: heading)),
                const SizedBox(height: 6),
                Text('Only the event owner and leaders can view the budget.',
                    textAlign: TextAlign.center, style: TextStyle(color: heading.withValues(alpha: 0.65))),
              ]),
            ),
          ),
        ),
      );
    }

    final costsAsync = ref.watch(costsProvider(eventId));
    final summaryAsync = ref.watch(costSummaryProvider(eventId));

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(costsProvider(eventId));
          ref.invalidate(costSummaryProvider(eventId));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            Row(children: [
              Expanded(child: Text('Cost Tracker', style: AppTheme.serif(size: 30, color: heading))),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onTap: () => showGlassSheet(context, (_) => CostForm(eventId: eventId)),
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
                Expanded(child: SummaryTile(icon: Icons.request_quote_outlined, value: formatInr(s.estimated), label: 'Estimated')),
                const SizedBox(width: 12),
                Expanded(child: SummaryTile(icon: Icons.account_balance_wallet_outlined, value: formatInr(s.actual), label: 'Actual')),
                const SizedBox(width: 12),
                Expanded(child: SummaryTile(icon: Icons.trending_up, value: formatInr(s.variance), label: 'Variance')),
              ]),
            ),
            const SizedBox(height: 16),
            costsAsync.when(
              loading: () => AsyncStates.loading(),
              error: (e, _) => AsyncStates.error('$e', () => ref.invalidate(costsProvider(eventId))),
              data: (items) => items.isEmpty
                  ? AsyncStates.empty(context, Icons.receipt_long_outlined, 'No costs yet', 'Budget line items appear here.')
                  : Column(children: [
                      for (final c in items)
                        _CostCard(
                          item: c,
                          onEdit: () => showGlassSheet(context, (_) => CostForm(eventId: eventId, item: c)),
                          onDelete: () async {
                            if (await confirmDelete(context, 'Delete cost?', 'Remove "${c.itemName}"?')) {
                              await ref.read(costRepoProvider).remove(eventId, c.id);
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

class _CostCard extends StatelessWidget {
  const _CostCard({required this.item, this.onEdit, this.onDelete});
  final CostItem item;
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
            Expanded(child: Text(item.itemName, style: AppTheme.serif(size: 18, color: heading))),
            StatusBadge(label: item.paymentStatus, color: StatusBadge.payment(item.paymentStatus)),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20, color: heading.withValues(alpha: 0.6)),
              onSelected: (v) {
                if (v == 'edit') onEdit?.call();
                if (v == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            GlassChip(label: item.category, color: AppColors.accent),
            if (item.vendor != null && item.vendor!.isNotEmpty)
              Text(item.vendor!, style: TextStyle(color: sub, fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _money('Estimated', formatInr(item.estimated), sub, heading),
            const SizedBox(width: 24),
            _money('Actual', item.actual == null ? '—' : formatInr(item.actual), sub, AppColors.accentDeep),
          ]),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.notes!, style: TextStyle(color: sub, fontSize: 12)),
          ],
        ]),
      ),
    );
  }

  Widget _money(String label, String value, Color sub, Color valueColor) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTheme.eyebrow(sub)),
          const SizedBox(height: 2),
          Text(value, style: AppTheme.serif(size: 17, color: valueColor)),
        ],
      );
}
