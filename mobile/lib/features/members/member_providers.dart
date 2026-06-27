import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'member_models.dart';

/// All members (accepted + pending invites) for a given event.
final membersProvider =
    FutureProvider.autoDispose.family<List<EventMember>, String>((ref, eventId) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<List<dynamic>>('/events/$eventId/members');
  return data.map((e) => EventMember.fromJson(e as Map<String, dynamic>)).toList();
});

final memberRepoProvider = Provider<MemberRepo>((ref) => MemberRepo(ref));

class MemberRepo {
  MemberRepo(this._ref);
  final Ref _ref;

  /// Invite a registered user by email and grant them [role] access.
  Future<void> invite(String eventId, String email, String role) async {
    await _ref.read(apiClientProvider).post(
      '/events/$eventId/members/invite',
      data: {'email': email, 'eventRole': role},
    );
    _ref.invalidate(membersProvider(eventId));
  }

  /// Change an existing member's access role.
  Future<void> changeRole(String eventId, String userId, String role) async {
    await _ref.read(apiClientProvider).patch(
      '/events/$eventId/members/$userId/role',
      data: {'eventRole': role},
    );
    _ref.invalidate(membersProvider(eventId));
  }

  /// Revoke a member's access entirely.
  Future<void> remove(String eventId, String userId) async {
    await _ref.read(apiClientProvider).delete('/events/$eventId/members/$userId');
    _ref.invalidate(membersProvider(eventId));
  }
}
