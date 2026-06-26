import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/widgets/forms.dart';
import '../../core/widgets/glass.dart';
import '../guests/guest_providers.dart';
import 'gift_models.dart';
import 'gift_providers.dart';

/// Add a gift (needs a guest) or edit an existing one.
class GiftForm extends ConsumerStatefulWidget {
  const GiftForm({super.key, required this.eventId, this.gift});
  final String eventId;
  final Gift? gift;

  @override
  ConsumerState<GiftForm> createState() => _GiftFormState();
}

class _GiftFormState extends ConsumerState<GiftForm> {
  late final _amount = TextEditingController(text: widget.gift?.amount?.toStringAsFixed(0) ?? '');
  late final _description = TextEditingController(text: widget.gift?.description ?? '');
  late final _remarks = TextEditingController(text: widget.gift?.remarks ?? '');

  String? _guestId; // chosen on add
  late String _type = widget.gift?.giftType ?? 'CASH';
  bool _saving = false;
  String? _error;

  bool get isEdit => widget.gift != null;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!isEdit && _guestId == null) {
      setState(() => _error = 'Choose a guest');
      return;
    }
    if (_type == 'CASH' && _amount.text.trim().isEmpty) {
      setState(() => _error = 'Amount is required for cash gifts');
      return;
    }
    if (_type == 'KIND' && _description.text.trim().isEmpty) {
      setState(() => _error = 'Description is required for in-kind gifts');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = {
      'giftType': _type,
      'amount': _type == 'CASH' ? num.tryParse(_amount.text.trim()) : null,
      'description': _type == 'KIND' ? _description.text.trim() : null,
      'remarks': _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
    };
    try {
      final repo = ref.read(giftRepoProvider);
      if (isEdit) {
        await repo.update(widget.eventId, widget.gift!.id, body);
      } else {
        await repo.create(widget.eventId, _guestId!, body);
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
    final guestsAsync = ref.watch(guestsProvider(widget.eventId));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SheetTitle(isEdit ? 'Edit gift' : 'Add gift', subtitle: isEdit ? widget.gift!.familyName : 'Record a gift from a guest'),
      if (!isEdit)
        guestsAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
          error: (_, _) => const Text('Could not load guests'),
          data: (guests) => LabeledDropdown<String>(
            label: 'Guest',
            value: _guestId,
            items: [for (final g in guests) DropdownMenuItem(value: g.id, child: Text(g.familyName))],
            onChanged: (v) => setState(() => _guestId = v),
          ),
        ),
      LabeledDropdown<String>(
        label: 'Type',
        value: _type,
        items: const [
          DropdownMenuItem(value: 'CASH', child: Text('Cash')),
          DropdownMenuItem(value: 'KIND', child: Text('In-kind')),
        ],
        onChanged: (v) => setState(() => _type = v ?? _type),
      ),
      if (_type == 'CASH')
        LabeledField(label: 'Amount (₹)', controller: _amount, keyboardType: TextInputType.number)
      else
        LabeledField(label: 'Description', controller: _description),
      LabeledField(label: 'Remarks', controller: _remarks, maxLines: 2),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(_error!, style: const TextStyle(color: Color(0xFFD9737A), fontSize: 13)),
        ),
      const SizedBox(height: 4),
      GradientButton(label: isEdit ? 'Save changes' : 'Add gift', loading: _saving, onPressed: _submit),
    ]);
  }
}
