import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/forms.dart';
import '../../core/widgets/glass.dart';
import 'event_providers.dart';

class EventForm extends ConsumerStatefulWidget {
  const EventForm({super.key});

  @override
  ConsumerState<EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<EventForm> {
  final _name = TextEditingController();
  final _venue = TextEditingController();
  final _description = TextEditingController();
  DateTime? _weddingDate;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _weddingDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _weddingDate = picked);
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Event name must be at least 2 characters.');
      return;
    }
    if (_weddingDate == null) {
      setState(() => _error = 'Choose the wedding date.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final event = await ref.read(eventRepoProvider).create({
        'name': name,
        'weddingDate': DateFormat('yyyy-MM-dd').format(_weddingDate!),
        'venue': _venue.text.trim().isEmpty ? null : _venue.text.trim(),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      });
      if (!mounted) return;
      final router = GoRouter.of(context);
      ref.read(selectedEventIdProvider.notifier).state = event.id;
      Navigator.of(context).pop();
      router.go('/app/dashboard');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not create event.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle('Create event', subtitle: 'You will be the owner of this event.'),
        LabeledField(label: 'Event name', controller: _name, hint: 'Ram & Sita Wedding 2026'),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text('Wedding date', style: AppTheme.eyebrow(AppColors.accentDeep)),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 18, color: heading.withValues(alpha: 0.7)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _weddingDate == null
                            ? 'Choose date'
                            : DateFormat('EEE, d MMM yyyy').format(_weddingDate!),
                        style: TextStyle(color: heading.withValues(alpha: _weddingDate == null ? 0.55 : 0.85)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
        LabeledField(label: 'Venue', controller: _venue),
        LabeledField(label: 'Description', controller: _description, maxLines: 3),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: AppColors.declined, fontSize: 13)),
          const SizedBox(height: 12),
        ],
        GradientButton(label: 'Create event', icon: Icons.add, loading: _saving, onPressed: _submit),
      ],
    );
  }
}
