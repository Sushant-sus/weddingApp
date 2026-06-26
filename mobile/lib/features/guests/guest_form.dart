import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/widgets/forms.dart';
import '../../core/widgets/glass.dart';
import 'guest_models.dart';
import 'guest_providers.dart';

/// Add/edit a guest. Pass [guest] = null to add.
class GuestForm extends ConsumerStatefulWidget {
  const GuestForm({super.key, required this.eventId, this.guest});
  final String eventId;
  final Guest? guest;

  @override
  ConsumerState<GuestForm> createState() => _GuestFormState();
}

class _GuestFormState extends ConsumerState<GuestForm> {
  late final _name = TextEditingController(text: widget.guest?.familyName ?? '');
  late final _attendees = TextEditingController(text: (widget.guest?.attendeeCount ?? 1).toString());
  late final _confirmed = TextEditingController(
      text: widget.guest?.confirmedCount == null ? '' : widget.guest!.confirmedCount.toString());
  late final _phone = TextEditingController(text: widget.guest?.contactPhone ?? '');
  late final _remarks = TextEditingController(text: widget.guest?.remarks ?? '');

  late String _type = widget.guest?.familyType ?? 'CHULEY';
  late String _side = widget.guest?.side ?? 'BRIDE';
  late String _rsvp = widget.guest?.rsvpStatus ?? 'PENDING';
  bool _saving = false;
  String? _error;

  bool get isEdit => widget.guest != null;

  @override
  void dispose() {
    for (final c in [_name, _attendees, _confirmed, _phone, _remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Family name is required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(guestRepoProvider);
      if (isEdit) {
        await repo.update(widget.eventId, widget.guest!.id, {
          'familyName': _name.text.trim(),
          'familyType': _type,
          'side': _side,
          'attendeeCount': int.tryParse(_attendees.text) ?? 0,
          'confirmedCount': _confirmed.text.trim().isEmpty ? null : int.tryParse(_confirmed.text),
          'contactPhone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          'remarks': _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
          'rsvpStatus': _rsvp,
        });
      } else {
        await repo.create(widget.eventId, {
          'familyName': _name.text.trim(),
          'familyType': _type,
          'side': _side,
          'attendeeCount': int.tryParse(_attendees.text) ?? 0,
          'contactPhone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          'remarks': _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
        });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(isEdit ? 'Edit guest' : 'Add guest', subtitle: isEdit ? widget.guest!.familyName : 'A new family or guest'),
        LabeledField(label: 'Family name', controller: _name),
        Row(children: [
          Expanded(
            child: LabeledDropdown<String>(
              label: 'Type',
              value: _type,
              items: const [
                DropdownMenuItem(value: 'CHULEY', child: Text('Chuley')),
                DropdownMenuItem(value: 'SINGLE', child: Text('Single')),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LabeledDropdown<String>(
              label: 'Side',
              value: _side,
              items: const [
                DropdownMenuItem(value: 'BRIDE', child: Text('Bride')),
                DropdownMenuItem(value: 'GROOM', child: Text('Groom')),
                DropdownMenuItem(value: 'BOTH', child: Text('Both')),
              ],
              onChanged: (v) => setState(() => _side = v ?? _side),
            ),
          ),
        ]),
        Row(children: [
          Expanded(child: LabeledField(label: 'Est. attendees', controller: _attendees, keyboardType: TextInputType.number)),
          if (isEdit) ...[
            const SizedBox(width: 12),
            Expanded(child: LabeledField(label: 'Confirmed', controller: _confirmed, keyboardType: TextInputType.number)),
          ],
        ]),
        LabeledField(label: 'Contact phone', controller: _phone, keyboardType: TextInputType.phone),
        if (isEdit)
          LabeledDropdown<String>(
            label: 'RSVP status',
            value: _rsvp,
            items: const [
              DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
              DropdownMenuItem(value: 'CONFIRMED', child: Text('Confirmed')),
              DropdownMenuItem(value: 'DECLINED', child: Text('Declined')),
            ],
            onChanged: (v) => setState(() => _rsvp = v ?? _rsvp),
          ),
        LabeledField(label: 'Remarks', controller: _remarks, maxLines: 2),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFD9737A), fontSize: 13)),
          ),
        const SizedBox(height: 4),
        GradientButton(label: isEdit ? 'Save changes' : 'Add guest', loading: _saving, onPressed: _submit),
      ],
    );
  }
}
