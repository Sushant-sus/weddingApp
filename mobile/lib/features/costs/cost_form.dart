import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/widgets/forms.dart';
import '../../core/widgets/glass.dart';
import 'cost_models.dart';
import 'cost_providers.dart';

class CostForm extends ConsumerStatefulWidget {
  const CostForm({super.key, required this.eventId, this.item});
  final String eventId;
  final CostItem? item;

  @override
  ConsumerState<CostForm> createState() => _CostFormState();
}

class _CostFormState extends ConsumerState<CostForm> {
  late final _category = TextEditingController(text: widget.item?.category ?? '');
  late final _name = TextEditingController(text: widget.item?.itemName ?? '');
  late final _estimated = TextEditingController(text: widget.item?.estimated.toStringAsFixed(0) ?? '');
  late final _actual = TextEditingController(text: widget.item?.actual?.toStringAsFixed(0) ?? '');
  late final _vendor = TextEditingController(text: widget.item?.vendor ?? '');
  late final _notes = TextEditingController(text: widget.item?.notes ?? '');

  late String _payment = widget.item?.paymentStatus ?? 'UNPAID';
  bool _saving = false;
  String? _error;

  bool get isEdit => widget.item != null;

  @override
  void dispose() {
    for (final c in [_category, _name, _estimated, _actual, _vendor, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_category.text.trim().isEmpty || _name.text.trim().isEmpty || _estimated.text.trim().isEmpty) {
      setState(() => _error = 'Category, item name and estimated cost are required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = {
      'category': _category.text.trim(),
      'itemName': _name.text.trim(),
      'estimatedCost': num.tryParse(_estimated.text.trim()) ?? 0,
      'actualCost': _actual.text.trim().isEmpty ? null : num.tryParse(_actual.text.trim()),
      'vendor': _vendor.text.trim().isEmpty ? null : _vendor.text.trim(),
      'paymentStatus': _payment,
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    };
    try {
      final repo = ref.read(costRepoProvider);
      if (isEdit) {
        await repo.update(widget.eventId, widget.item!.id, body);
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
      SheetTitle(isEdit ? 'Edit cost' : 'Add cost', subtitle: 'Budget line item'),
      LabeledField(label: 'Item name', controller: _name),
      LabeledField(label: 'Category', controller: _category, hint: 'e.g. Venue, Catering'),
      Row(children: [
        Expanded(child: LabeledField(label: 'Estimated (₹)', controller: _estimated, keyboardType: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: LabeledField(label: 'Actual (₹)', controller: _actual, keyboardType: TextInputType.number)),
      ]),
      LabeledField(label: 'Vendor', controller: _vendor),
      LabeledDropdown<String>(
        label: 'Payment status',
        value: _payment,
        items: const [
          DropdownMenuItem(value: 'UNPAID', child: Text('Unpaid')),
          DropdownMenuItem(value: 'PARTIAL', child: Text('Partial')),
          DropdownMenuItem(value: 'PAID', child: Text('Paid')),
        ],
        onChanged: (v) => setState(() => _payment = v ?? _payment),
      ),
      LabeledField(label: 'Notes', controller: _notes, maxLines: 2),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(_error!, style: const TextStyle(color: Color(0xFFD9737A), fontSize: 13)),
        ),
      const SizedBox(height: 4),
      GradientButton(label: isEdit ? 'Save changes' : 'Add cost', loading: _saving, onPressed: _submit),
    ]);
  }
}
