import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/providers.dart';
import 'event_models.dart';

/// All events the signed-in user belongs to.
final eventsProvider = FutureProvider.autoDispose<List<WeddingEvent>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<List<dynamic>>('/events');
  return data.map((e) => WeddingEvent.fromJson(e as Map<String, dynamic>)).toList();
});

final eventRepoProvider = Provider<EventRepo>((ref) => EventRepo(ref));

class EventRepo {
  EventRepo(this._ref);

  final Ref _ref;

  Future<WeddingEvent> create(Map<String, dynamic> body) async {
    final data = await _ref.read(apiClientProvider).post<Map<String, dynamic>>('/events', data: body);
    _ref.invalidate(eventsProvider);
    return WeddingEvent.fromJson(data);
  }

  /// Accept a pending invite to [eventId]; the event becomes fully accessible.
  Future<WeddingEvent> acceptInvite(String eventId) async {
    final data =
        await _ref.read(apiClientProvider).post<Map<String, dynamic>>('/events/$eventId/accept');
    _ref.invalidate(eventsProvider);
    return WeddingEvent.fromJson(data);
  }

  /// Decline a pending invite to [eventId]; it drops off the user's list.
  Future<void> declineInvite(String eventId) async {
    await _ref.read(apiClientProvider).post('/events/$eventId/decline');
    _ref.invalidate(eventsProvider);
  }
}

/// The currently selected event id (drives the per-event tabs).
final selectedEventIdProvider = StateProvider<String?>((ref) => null);

/// Convenience: the selected event object, if loaded.
final selectedEventProvider = Provider<WeddingEvent?>((ref) {
  final id = ref.watch(selectedEventIdProvider);
  final events = ref.watch(eventsProvider).asData?.value;
  if (id == null || events == null) return null;
  for (final e in events) {
    if (e.id == id) return e;
  }
  return null;
});
