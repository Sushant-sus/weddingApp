import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'aayojan_loader.dart';

/// A colour-coded status pill (RSVP, payment, request status …).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: AppTheme.eyebrow(color)),
    );
  }

  static Color rsvp(String s) => switch (s) {
        'CONFIRMED' => AppColors.booked,
        'DECLINED' => AppColors.declined,
        _ => AppColors.pending,
      };

  static Color payment(String s) => switch (s) {
        'PAID' => AppColors.booked,
        'PARTIAL' => AppColors.pending,
        _ => AppColors.declined,
      };
}

/// A small glass stat tile (icon + big value + label).
class SummaryTile extends StatelessWidget {
  const SummaryTile({super.key, required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppColors.accentDeep),
        const SizedBox(height: 8),
        Text(value, style: AppTheme.serif(size: 20, color: heading), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(fontSize: 11, color: heading.withValues(alpha: 0.6))),
      ]),
    );
  }
}

/// Standard loading / error / empty states for a list screen.
class AsyncStates {
  static Widget loading() =>
      const Padding(padding: EdgeInsets.only(top: 70), child: Center(child: AayojanLoader(size: 64)));

  static Widget error(String msg, VoidCallback retry) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          const Icon(Icons.cloud_off, size: 40, color: AppColors.declined),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: retry, child: const Text('Retry')),
        ]),
      );

  static Widget empty(BuildContext context, IconData icon, String title, String note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Icon(icon, size: 44, color: heading.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text(title, style: AppTheme.serif(size: 22, color: heading)),
        const SizedBox(height: 6),
        Text(note, textAlign: TextAlign.center, style: TextStyle(color: heading.withValues(alpha: 0.6))),
      ]),
    );
  }
}
