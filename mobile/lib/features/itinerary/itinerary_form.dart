import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/forms.dart';
import '../../core/widgets/glass.dart';
import 'itinerary_models.dart';
import 'itinerary_providers.dart';

const _categories = ['CEREMONY', 'RECEPTION', 'RITUAL', 'MEAL', 'ENTERTAINMENT', 'OTHER'];
String _label(String c) => c[0] + c.substring(1).toLowerCase();

class ItineraryForm extends ConsumerStatefulWidget {
  const ItineraryForm({super.key, required this.eventId, this.event});
  final String eventId;
  final ItineraryEvent? event;

  @override
  ConsumerState<ItineraryForm> createState() => _ItineraryFormState();
}

class _ItineraryFormState extends ConsumerState<ItineraryForm> {
  late final _title = TextEditingController(text: widget.event?.title ?? '');
  late final _start = TextEditingController(text: widget.event?.startTime ?? '');
  late final _end = TextEditingController(text: widget.event?.endTime ?? '');
  late final _location = TextEditingController(text: widget.event?.location ?? '');
  late final _responsible = TextEditingController(text: widget.event?.responsible ?? '');
  late final _description = TextEditingController(text: widget.event?.description ?? '');

  late DateTime _date = widget.event?.eventDate ?? DateTime.now();
  late String _category = widget.event?.category ?? 'CEREMONY';
  bool _saving = false;
  String? _error;

  bool get isEdit => widget.event != null;

  @override
  void dispose() {
    for (final c in [_title, _start, _end, _location, _responsible, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _start.text.trim().isEmpty) {
      setState(() => _error = 'Title and start time are required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = {
      'title': _title.text.trim(),
      'eventDate': DateFormat('yyyy-MM-dd').format(_date),
      'startTime': _start.text.trim(),
      'endTime': _end.text.trim().isEmpty ? null : _end.text.trim(),
      'location': _location.text.trim().isEmpty ? null : _location.text.trim(),
      'responsible': _responsible.text.trim().isEmpty ? null : _responsible.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'category': _category,
    };
    try {
      final repo = ref.read(itineraryRepoProvider);
      if (isEdit) {
        await repo.update(widget.eventId, widget.event!.id, body);
      } else {
        await repo.create(widget.eventId, body);
      }
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SheetTitle(isEdit ? 'Edit event' : 'Add event', subtitle: 'Ceremony timeline item'),
      LabeledField(label: 'Title', controller: _title),
      LabeledDropdown<String>(
        label: 'Category',
        value: _category,
        items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(_label(c)))],
        onChanged: (v) => setState(() => _category = v ?? _category),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text('DATE', style: AppTheme.eyebrow(AppColors.accentDeep)),
          ),
          GlassCard(
            onTap: _pickDate,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              const Icon(Icons.event, size: 18, color: AppColors.accentDeep),
              const SizedBox(width: 10),
              Text(DateFormat('EEE, d MMM yyyy').format(_date)),
            ]),
          ),
        ]),
      ),
      Row(children: [
        Expanded(child: LabeledField(label: 'Start time', controller: _start, hint: 'e.g. 16:00')),
        const SizedBox(width: 12),
        Expanded(child: LabeledField(label: 'End time', controller: _end, hint: 'optional')),
      ]),
      LabeledField(label: 'Location', controller: _location),
      LabeledField(label: 'Responsible', controller: _responsible),
      LabeledField(label: 'Description', controller: _description, maxLines: 2),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(_error!, style: const TextStyle(color: Color(0xFFD9737A), fontSize: 13)),
        ),
      const SizedBox(height: 4),
      GradientButton(label: isEdit ? 'Save changes' : 'Add event', loading: _saving, onPressed: _submit),
    ]);
  }
}
