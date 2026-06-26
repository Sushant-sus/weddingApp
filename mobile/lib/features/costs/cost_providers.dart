import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'cost_models.dart';

final costsProvider = FutureProvider.autoDispose.family<List<CostItem>, String>((ref, eventId) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<List<dynamic>>('/events/$eventId/costs');
  return data.map((e) => CostItem.fromJson(e as Map<String, dynamic>)).toList();
});

final costSummaryProvider = FutureProvider.autoDispose.family<CostSummary, String>((ref, eventId) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<Map<String, dynamic>>('/events/$eventId/costs/summary');
  return CostSummary.fromJson(data);
});

final costRepoProvider = Provider((ref) => CostRepo(ref));

class CostRepo {
  CostRepo(this._ref);
  final Ref _ref;

  void _invalidate(String eventId) {
    _ref.invalidate(costsProvider(eventId));
    _ref.invalidate(costSummaryProvider(eventId));
  }

  Future<void> create(String eventId, Map<String, dynamic> body) async {
    await _ref.read(apiClientProvider).post('/events/$eventId/costs', data: body);
    _invalidate(eventId);
  }

  Future<void> update(String eventId, String id, Map<String, dynamic> body) async {
    await _ref.read(apiClientProvider).patch('/events/$eventId/costs/$id', data: body);
    _invalidate(eventId);
  }

  Future<void> remove(String eventId, String id) async {
    await _ref.read(apiClientProvider).delete('/events/$eventId/costs/$id');
    _invalidate(eventId);
  }
}
