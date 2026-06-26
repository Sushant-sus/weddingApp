class ItineraryEvent {
  ItineraryEvent({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    required this.startTime,
    this.endTime,
    this.location,
    this.responsible,
    required this.category,
    required this.orderIndex,
    this.status = 'PLANNED',
  });

  final String id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String startTime;
  final String? endTime;
  final String? location;
  final String? responsible;
  final String category; // CEREMONY | RECEPTION | RITUAL | MEAL | ENTERTAINMENT | OTHER
  final int orderIndex;
  final String status; // PLANNED | DONE | CANCELLED

  bool get isDone => status == 'DONE';
  bool get isCancelled => status == 'CANCELLED';

  ItineraryEvent copyWith({String? status}) => ItineraryEvent(
        id: id,
        title: title,
        description: description,
        eventDate: eventDate,
        startTime: startTime,
        endTime: endTime,
        location: location,
        responsible: responsible,
        category: category,
        orderIndex: orderIndex,
        status: status ?? this.status,
      );

  factory ItineraryEvent.fromJson(Map<String, dynamic> j) => ItineraryEvent(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        eventDate: DateTime.parse(j['event_date'] as String),
        startTime: j['start_time'] as String? ?? '',
        endTime: j['end_time'] as String?,
        location: j['location'] as String?,
        responsible: j['responsible'] as String?,
        category: j['category'] as String? ?? 'OTHER',
        orderIndex: (j['order_index'] as num?)?.toInt() ?? 0,
        status: j['status'] as String? ?? 'PLANNED',
      );
}
