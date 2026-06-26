class Guest {
  Guest({
    required this.id,
    required this.familyName,
    required this.familyType,
    required this.side,
    required this.attendeeCount,
    this.confirmedCount,
    this.contactPhone,
    this.address,
    this.remarks,
    required this.rsvpStatus,
  });

  final String id;
  final String familyName;
  final String familyType; // CHULEY | SINGLE
  final String side; // BRIDE | GROOM | BOTH
  final int attendeeCount;
  final int? confirmedCount;
  final String? contactPhone;
  final String? address;
  final String? remarks;
  final String rsvpStatus; // PENDING | CONFIRMED | DECLINED

  factory Guest.fromJson(Map<String, dynamic> j) => Guest(
        id: j['id'] as String,
        familyName: j['family_name'] as String? ?? '',
        familyType: j['family_type'] as String? ?? 'SINGLE',
        side: j['side'] as String? ?? 'BOTH',
        attendeeCount: (j['attendee_count'] as num?)?.toInt() ?? 0,
        confirmedCount: (j['confirmed_count'] as num?)?.toInt(),
        contactPhone: j['contact_phone'] as String?,
        address: j['address'] as String?,
        remarks: j['remarks'] as String?,
        rsvpStatus: j['rsvp_status'] as String? ?? 'PENDING',
      );
}

class GuestSummary {
  GuestSummary({required this.families, required this.estimated, required this.confirmed});
  final int families;
  final int estimated;
  final int confirmed;

  factory GuestSummary.fromJson(Map<String, dynamic> j) => GuestSummary(
        families: (j['total_families'] as num?)?.toInt() ?? 0,
        estimated: (j['total_estimated_attendees'] as num?)?.toInt() ?? 0,
        confirmed: (j['total_confirmed_attendees'] as num?)?.toInt() ?? 0,
      );
}
