import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'gift_models.dart';

final giftsProvider = FutureProvider.autoDispose.family<List<Gift>, String>((ref, eventId) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<List<dynamic>>('/events/$eventId/gifts');
  return data.map((e) => Gift.fromJson(e as Map<String, dynamic>)).toList();
});

final giftSummaryProvider = FutureProvider.autoDispose.family<GiftSummary, String>((ref, eventId) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<Map<String, dynamic>>('/events/$eventId/gifts/summary');
  return GiftSummary.fromJson(data);
});

final giftRepoProvider = Provider((ref) => GiftRepo(ref));

class GiftRepo {
  GiftRepo(this._ref);
  final Ref _ref;

  void _invalidate(String eventId) {
    _ref.invalidate(giftsProvider(eventId));
    _ref.invalidate(giftSummaryProvider(eventId));
  }

  Future<void> create(String eventId, String guestId, Map<String, dynamic> body) async {
    await _ref.read(apiClientProvider).post('/events/$eventId/guests/$guestId/gifts', data: body);
    _invalidate(eventId);
  }

  /// Fast gift-desk entry: body carries either guestId or giverName.
  /// Returns the created gift so the desk can show it in "just recorded".
  Future<Gift> quickCreate(String eventId, Map<String, dynamic> body) async {
    final data = await _ref.read(apiClientProvider).post<Map<String, dynamic>>('/events/$eventId/gifts', data: body);
    _invalidate(eventId);
    return Gift.fromJson(data);
  }

  Future<void> update(String eventId, String id, Map<String, dynamic> body) async {
    await _ref.read(apiClientProvider).patch('/events/$eventId/gifts/$id', data: body);
    _invalidate(eventId);
  }

  Future<void> remove(String eventId, String id) async {
    await _ref.read(apiClientProvider).delete('/events/$eventId/gifts/$id');
    _invalidate(eventId);
  }
}
