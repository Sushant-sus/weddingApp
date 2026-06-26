import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'guest_models.dart';

final guestsProvider = FutureProvider.autoDispose.family<List<Guest>, String>((ref, eventId) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<List<dynamic>>('/events/$eventId/guests');
  return data.map((e) => Guest.fromJson(e as Map<String, dynamic>)).toList();
});

final guestSummaryProvider = FutureProvider.autoDispose.family<GuestSummary, String>((ref, eventId) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<Map<String, dynamic>>('/events/$eventId/guests/summary');
  return GuestSummary.fromJson(data);
});

final guestRepoProvider = Provider((ref) => GuestRepo(ref));

class GuestRepo {
  GuestRepo(this._ref);
  final Ref _ref;

  void _invalidate(String eventId) {
    _ref.invalidate(guestsProvider(eventId));
    _ref.invalidate(guestSummaryProvider(eventId));
  }

  Future<void> create(String eventId, Map<String, dynamic> body) async {
    await _ref.read(apiClientProvider).post('/events/$eventId/guests', data: body);
    _invalidate(eventId);
  }

  Future<void> update(String eventId, String id, Map<String, dynamic> body) async {
    await _ref.read(apiClientProvider).patch('/events/$eventId/guests/$id', data: body);
    _invalidate(eventId);
  }

  Future<void> remove(String eventId, String id) async {
    await _ref.read(apiClientProvider).delete('/events/$eventId/guests/$id');
    _invalidate(eventId);
  }
}
