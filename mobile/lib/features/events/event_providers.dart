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
