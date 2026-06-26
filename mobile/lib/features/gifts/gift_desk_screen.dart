import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/forms.dart';
import '../guests/guest_models.dart';
import '../guests/guest_providers.dart';
import 'gift_models.dart';
import 'gift_providers.dart';
import 'gift_form.dart';

// Common shagun denominations (₹) for one-tap entry.
const _denominations = [501, 1100, 2100, 5100, 11000, 21000];

/// Fast "gift desk" rapid-entry screen — POS-style: numpad + denomination
/// chips, giver type-ahead (existing guest or free-text), Save & Next, a live
/// session tally and an editable "just recorded" list.
class GiftDeskScreen extends ConsumerStatefulWidget {
  const GiftDeskScreen({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<GiftDeskScreen> createState() => _GiftDeskScreenState();
}

class _GiftDeskScreenState extends ConsumerState<GiftDeskScreen> {
  final _giver = TextEditingController();
  final _giverFocus = FocusNode();
  final _description = TextEditingController();

  String _amount = ''; // digit string for cash
  String _type = 'CASH';
  Guest? _selectedGuest; // set when a suggestion is tapped
  bool _saving = false;
  String? _error;

  // Session tally + recently recorded (this sitting).
  int _sessionCount = 0;
  num _sessionCash = 0;
  final List<Gift> _recent = [];

  @override
  void dispose() {
    _giver.dispose();
    _giverFocus.dispose();
    _description.dispose();
    super.dispose();
  }

  void _tapDigit(String d) {
    HapticFeedback.selectionClick();
    setState(() {
      if (d == '⌫') {
        if (_amount.isNotEmpty) _amount = _amount.substring(0, _amount.length - 1);
      } else if (_amount.length < 9) {
        if (_amount.isEmpty && (d == '0' || d == '00')) return; // no leading zeros
        _amount += d;
      }
    });
  }

  void _setDenom(int v) {
    HapticFeedback.selectionClick();
    setState(() => _amount = v.toString());
  }

  num get _amountValue => num.tryParse(_amount) ?? 0;

  Future<void> _save() async {
    final giverText = _giver.text.trim();
    if (_selectedGuest == null && giverText.isEmpty) {
      setState(() => _error = 'Enter a giver name');
      _giverFocus.requestFocus();
      return;
    }
    if (_type == 'CASH' && _amountValue <= 0) {
      setState(() => _error = 'Enter an amount');
      return;
    }
    if (_type == 'KIND' && _description.text.trim().isEmpty) {
      setState(() => _error = 'Describe the gift');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'giftType': _type,
      if (_selectedGuest != null) 'guestId': _selectedGuest!.id else 'giverName': giverText,
      'amount': _type == 'CASH' ? _amountValue : null,
      'description': _type == 'KIND' ? _description.text.trim() : null,
    };
    try {
      final gift = await ref.read(giftRepoProvider).quickCreate(widget.eventId, body);
      HapticFeedback.mediumImpact();
      setState(() {
        _recent.insert(0, gift);
        _sessionCount++;
        if (gift.isCash) _sessionCash += gift.amount ?? 0;
        // reset for the next giver
        _giver.clear();
        _description.clear();
        _amount = '';
        _selectedGuest = null;
      });
      _giverFocus.requestFocus();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not save — check your connection');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    final guests = ref.watch(guestsProvider(widget.eventId)).asData?.value ?? const <Guest>[];

    // Suggestions: match typed text against guest names (skip once one is picked).
    final q = _giver.text.trim().toLowerCase();
    final suggestions = (_selectedGuest != null || q.isEmpty)
        ? const <Guest>[]
        : guests.where((g) => g.familyName.toLowerCase().contains(q)).take(4).toList();

    return GlassScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header: back + title + live tally.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
              child: Row(children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: heading),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(child: Text('Gift Desk', style: AppTheme.serif(size: 24, color: heading))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatInr(_sessionCash),
                      style: AppTheme.serif(size: 20, color: AppColors.accentDeep)),
                  Text('$_sessionCount this session',
                      style: TextStyle(fontSize: 11, color: heading.withValues(alpha: 0.6))),
                ]),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // Cash / Gift toggle.
                  _SegToggle(
                    value: _type,
                    onChanged: (v) => setState(() => _type = v),
                  ),
                  const SizedBox(height: 12),
                  // Giver field.
                  TextField(
                    controller: _giver,
                    focusNode: _giverFocus,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() => _selectedGuest = null),
                    decoration: InputDecoration(
                      hintText: 'Giver name',
                      prefixIcon: const Icon(Icons.person_outline),
                      suffixIcon: _giver.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() {
                                _giver.clear();
                                _selectedGuest = null;
                              }),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  // Suggestions / "new giver" hint.
                  if (suggestions.isNotEmpty)
                    ...suggestions.map((g) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.badge_outlined, size: 20, color: AppColors.accentDeep),
                          title: Text(g.familyName),
                          subtitle: Text('${g.side} · guest', style: const TextStyle(fontSize: 11)),
                          onTap: () => setState(() {
                            _selectedGuest = g;
                            _giver.text = g.familyName;
                            _giverFocus.unfocus();
                          }),
                        ))
                  else if (q.isNotEmpty && _selectedGuest == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 6),
                      child: Row(children: [
                        const Icon(Icons.person_add_alt, size: 16, color: AppColors.booked),
                        const SizedBox(width: 6),
                        Text('New giver — not in guest list',
                            style: TextStyle(fontSize: 12, color: heading.withValues(alpha: 0.6))),
                      ]),
                    ),
                  if (_selectedGuest != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 6),
                      child: Row(children: [
                        const Icon(Icons.check_circle, size: 16, color: AppColors.booked),
                        const SizedBox(width: 6),
                        Text('Linked to guest', style: TextStyle(fontSize: 12, color: heading.withValues(alpha: 0.6))),
                      ]),
                    ),
                  const SizedBox(height: 14),

                  if (_type == 'CASH') ...[
                    // Amount display.
                    Center(
                      child: Text(
                        _amount.isEmpty ? '₹0' : formatInr(_amountValue),
                        style: AppTheme.serif(size: 44, color: heading),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Denomination chips.
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final d in _denominations)
                          GestureDetector(
                            onTap: () => _setDenom(d),
                            child: GlassChip(label: '₹${formatNumber(d)}', color: AppColors.accent),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _NumPad(onTap: _tapDigit),
                  ] else ...[
                    LabeledField(label: 'Gift description', controller: _description, hint: 'e.g. Dinner set, Gold ring'),
                  ],

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.declined)),
                    ),
                  const SizedBox(height: 14),
                  GradientButton(label: 'Save & Next', icon: Icons.check, loading: _saving, onPressed: _save),

                  // Just recorded (this session).
                  if (_recent.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text('Just recorded', style: AppTheme.eyebrow(AppColors.accentDeep)),
                    const SizedBox(height: 8),
                    for (final g in _recent) _recentTile(g, heading),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentTile(Gift g, Color heading) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Icon(g.isCash ? Icons.payments_outlined : Icons.card_giftcard, size: 18, color: AppColors.booked),
          const SizedBox(width: 10),
          Expanded(
            child: Text(g.familyName, style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
          ),
          Text(g.isCash ? formatInr(g.amount) : (g.description ?? 'Gift'),
              style: AppTheme.serif(size: 16, color: AppColors.accentDeep)),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.edit_outlined, size: 18, color: heading.withValues(alpha: 0.6)),
            onPressed: () => showGlassSheet(context, (_) => GiftForm(eventId: widget.eventId, gift: g)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.declined),
            onPressed: () async {
              if (await confirmDelete(context, 'Delete gift?', 'Remove ${g.familyName}\'s gift?')) {
                await ref.read(giftRepoProvider).remove(widget.eventId, g.id);
                setState(() {
                  _recent.removeWhere((x) => x.id == g.id);
                  _sessionCount = (_sessionCount - 1).clamp(0, 1 << 30);
                  if (g.isCash) _sessionCash -= g.amount ?? 0;
                });
              }
            },
          ),
        ]),
      ),
    );
  }
}

class _SegToggle extends StatelessWidget {
  const _SegToggle({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String v, String label, IconData icon) {
      final active = value == v;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(v),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.accent.withValues(alpha: 0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: active ? AppColors.accentDeep : Colors.grey),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: active ? AppColors.accentDeep : Colors.grey)),
            ]),
          ),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        seg('CASH', 'Cash', Icons.payments_outlined),
        seg('KIND', 'Gift', Icons.card_giftcard),
      ]),
    );
  }
}

class _NumPad extends StatelessWidget {
  const _NumPad({required this.onTap});
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '00', '0', '⌫'];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.1,
      children: [
        for (final k in keys)
          GlassCard(
            padding: EdgeInsets.zero,
            onTap: () => onTap(k),
            child: Center(
              child: k == '⌫'
                  ? Icon(Icons.backspace_outlined, size: 22, color: heading)
                  : Text(k, style: AppTheme.serif(size: 24, color: heading)),
            ),
          ),
      ],
    );
  }
}
