class WeddingEvent {
  WeddingEvent({
    required this.id,
    required this.name,
    required this.weddingDate,
    this.venue,
    this.description,
    required this.myRole,
    this.inviteStatus = 'ACCEPTED',
    this.memberCount = 0,
    this.guestCount,
  });

  final String id;
  final String name;
  final DateTime weddingDate;
  final String? venue;
  final String? description;
  final String myRole;
  final String inviteStatus;
  final int memberCount;
  final int? guestCount;

  /// A pending invite the user has been given but not yet accepted. Such events
  /// appear in the list but can't be opened until accepted.
  bool get isPending => inviteStatus == 'PENDING';

  bool get canManage => myRole == 'OWNER' || myRole == 'LEADER';
  bool get canEdit => canManage || myRole == 'EDITOR';
  bool get canContribute => canEdit || myRole == 'CONTRIBUTOR';
  bool get canViewCosts => canManage;

  int get daysToWedding => weddingDate.difference(DateTime.now()).inDays;

  factory WeddingEvent.fromJson(Map<String, dynamic> j) => WeddingEvent(
        id: j['id'] as String,
        name: j['name'] as String,
        weddingDate: DateTime.parse(j['wedding_date'] as String),
        venue: j['venue'] as String?,
        description: j['description'] as String?,
        myRole: j['my_role'] as String? ?? 'VIEWER',
        inviteStatus: j['invite_status'] as String? ?? 'ACCEPTED',
        memberCount: (j['member_count'] as num?)?.toInt() ?? 0,
        guestCount: (j['guest_count'] as num?)?.toInt(),
      );
}
