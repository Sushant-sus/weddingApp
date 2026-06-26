import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Presents [builder] as a rising glass bottom sheet over a blurred backdrop.
Future<T?> showGlassSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final fill = isDark ? const Color(0xFF2A1E33).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.86);
      return Padding(
        // lift above the keyboard
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: Glass.sheetBlur, sigmaY: Glass.sheetBlur),
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
                border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.5), width: 1),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
                    ),
                    builder(ctx),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Confirms a destructive action; returns true when the user taps Delete.
Future<bool> confirmDelete(BuildContext context, String title, String message) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete', style: TextStyle(color: AppColors.declined)),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// A labelled text field tuned for the glass forms.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(label, style: AppTheme.eyebrow(AppColors.accentDeep)),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ]),
    );
  }
}

/// A labelled dropdown for enum-style choices.
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(label, style: AppTheme.eyebrow(AppColors.accentDeep)),
        ),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ]),
    );
  }
}

/// Sheet title + optional subtitle.
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Align(alignment: Alignment.centerLeft, child: Text(title, style: AppTheme.serif(size: 24, color: heading))),
        if (subtitle != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(subtitle!, style: TextStyle(color: heading.withValues(alpha: 0.6), fontSize: 13)),
          ),
      ]),
    );
  }
}
