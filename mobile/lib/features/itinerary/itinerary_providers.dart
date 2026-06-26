import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'itinerary_models.dart';

final itineraryProvider = FutureProvider.autoDispose.family<List<ItineraryEvent>, String>((ref, eventId) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<List<dynamic>>('/events/$eventId/itinerary');
  return data.map((e) => ItineraryEvent.fromJson(e as Map<String, dynamic>)).toList();
});

final itineraryRepoProvider = Provider((ref) => ItineraryRepo(ref));

class ItineraryRepo {
  ItineraryRepo(this._ref);
  final Ref _ref;

  Future<void> create(String eventId, Map<String, dynamic> body) async {
    await _ref.read(apiClientProvider).post('/events/$eventId/itinerary', data: body);
    _ref.invalidate(itineraryProvider(eventId));
  }

  Future<void> update(String eventId, String id, Map<String, dynamic> body) async {
    await _ref.read(apiClientProvider).patch('/events/$eventId/itinerary/$id', data: body);
    _ref.invalidate(itineraryProvider(eventId));
  }

  Future<void> remove(String eventId, String id) async {
    await _ref.read(apiClientProvider).delete('/events/$eventId/itinerary/$id');
    _ref.invalidate(itineraryProvider(eventId));
  }

  /// Persist a new order: [{id, orderIndex}] under { order: [...] }.
  Future<void> reorder(String eventId, List<Map<String, dynamic>> order) async {
    await _ref.read(apiClientProvider).patch('/events/$eventId/itinerary/reorder', data: {'order': order});
    _ref.invalidate(itineraryProvider(eventId));
  }
}
