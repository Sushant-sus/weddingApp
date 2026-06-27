import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/forms.dart';
import '../../core/widgets/glass.dart';
import '../events/event_providers.dart';
import 'member_models.dart';
import 'member_providers.dart';

/// Shows everyone with access to the selected event and — for OWNER/LEADER —
/// lets them invite new people, change roles, or revoke access.
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(selectedEventProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;

    if (event == null) {
      return Center(
        child: Text('Select an event first.', style: TextStyle(color: heading.withValues(alpha: 0.7))),
      );
    }

    final canManage = event.canManage;
    final membersAsync = ref.watch(membersProvider(event.id));

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(membersProvider(event.id).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Row(
            children: [
              Expanded(child: Text('Members', style: AppTheme.serif(size: 30, color: heading))),
              if (canManage)
                IconButton(
                  tooltip: 'Invite people',
                  icon: Icon(Icons.person_add_alt_1, color: heading.withValues(alpha: 0.8)),
                  onPressed: () => _showInvite(context, ref, event.id),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            canManage
                ? 'Invite people and choose what they can do.'
                : 'People with access to ${event.name}.',
            style: TextStyle(fontSize: 13, color: heading.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          membersAsync.when(
            loading: () => const Padding(
                padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => _error(context, '$e', () => ref.refresh(membersProvider(event.id))),
            data: (members) => Column(
              children: [
                for (final m in members)
                  _MemberCard(
                    member: m,
                    eventId: event.id,
                    canManage: canManage && !m.isOwner,
                  ),
              ],
            ),
          ),
          if (canManage) ...[
            const SizedBox(height: 8),
            GradientButton(
              label: 'Invite people',
              icon: Icons.person_add_alt_1,
              onPressed: () => _showInvite(context, ref, event.id),
            ),
          ],
        ],
      ),
    );
  }

  void _showInvite(BuildContext context, WidgetRef ref, String eventId) {
    showGlassSheet(context, (_) => _InviteSheet(eventId: eventId));
  }

  Widget _error(BuildContext context, String msg, VoidCallback retry) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          const Icon(Icons.cloud_off, size: 40, color: AppColors.declined),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: retry, child: const Text('Retry')),
        ]),
      );
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({required this.member, required this.eventId, required this.canManage});

  final EventMember member;
  final String eventId;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    final initial = (member.fullName.isNotEmpty ? member.fullName : member.email).characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.accent.withValues(alpha: 0.3),
              child: Text(initial, style: AppTheme.serif(size: 18, color: AppColors.accentDeep)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(member.fullName.isEmpty ? member.email : member.fullName,
                    style: AppTheme.serif(size: 17, color: heading)),
                Text(member.email,
                    style: TextStyle(fontSize: 12, color: heading.withValues(alpha: 0.6)),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  GlassChip(label: member.role, color: AppColors.accent),
                  if (member.isPending) ...[
                    const SizedBox(width: 6),
                    const GlassChip(label: 'Pending', color: AppColors.pending, icon: Icons.schedule),
                  ],
                ]),
              ]),
            ),
            if (canManage)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: heading.withValues(alpha: 0.7)),
                onSelected: (value) => _onAction(context, ref, value),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'role', child: Text('Change role')),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove access', style: TextStyle(color: AppColors.declined)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(BuildContext context, WidgetRef ref, String value) async {
    if (value == 'role') {
      await _changeRole(context, ref);
    } else if (value == 'remove') {
      await _remove(context, ref);
    }
  }

  Future<void> _changeRole(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showGlassSheet<String>(
      context,
      (_) => _RolePickerSheet(current: member.role, name: member.fullName.isEmpty ? member.email : member.fullName),
    );
    if (picked == null || picked == member.role) return;
    try {
      await ref.read(memberRepoProvider).changeRole(eventId, member.userId, picked);
      _toast(messenger, 'Role updated to $picked');
    } on ApiException catch (e) {
      _toast(messenger, e.message);
    } catch (_) {
      _toast(messenger, 'Could not update role.');
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final name = member.fullName.isEmpty ? member.email : member.fullName;
    final ok = await confirmDelete(context, 'Remove access', 'Remove $name from this event?');
    if (!ok) return;
    try {
      await ref.read(memberRepoProvider).remove(eventId, member.userId);
      _toast(messenger, '$name removed');
    } on ApiException catch (e) {
      _toast(messenger, e.message);
    } catch (_) {
      _toast(messenger, 'Could not remove member.');
    }
  }

  void _toast(ScaffoldMessengerState messenger, String msg) {
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// Bottom sheet to invite a registered user by email with a chosen role.
class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet({required this.eventId});
  final String eventId;

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  final _email = TextEditingController();
  String _role = 'EDITOR';
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(memberRepoProvider).invite(widget.eventId, email, _role);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invite sent to $email')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not send invite.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle('Invite people', subtitle: 'They must already have an account.'),
        LabeledField(
          label: 'Email',
          controller: _email,
          hint: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        LabeledDropdown<String>(
          label: 'Access role',
          value: _role,
          items: [
            for (final r in assignableRoles)
              DropdownMenuItem(value: r, child: Text('$r — ${roleDescription(r)}')),
          ],
          onChanged: (v) => setState(() => _role = v ?? _role),
        ),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: AppColors.declined, fontSize: 13)),
          const SizedBox(height: 12),
        ],
        GradientButton(label: 'Send invite', icon: Icons.send, loading: _sending, onPressed: _submit),
      ],
    );
  }
}

/// Bottom sheet that returns the chosen role (or null if dismissed).
class _RolePickerSheet extends StatelessWidget {
  const _RolePickerSheet({required this.current, required this.name});
  final String current;
  final String name;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColors.headingDark : AppColors.headingLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle('Change role', subtitle: 'New access level for $name'),
        for (final r in assignableRoles)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              onTap: () => Navigator.of(context).pop(r),
              child: Row(children: [
                Icon(r == current ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: r == current ? AppColors.accentDeep : heading.withValues(alpha: 0.4)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r, style: TextStyle(fontWeight: FontWeight.w700, color: heading)),
                    Text(roleDescription(r),
                        style: TextStyle(fontSize: 12, color: heading.withValues(alpha: 0.6))),
                  ]),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}
