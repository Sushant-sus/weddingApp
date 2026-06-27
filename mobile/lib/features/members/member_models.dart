/// A person attached to an event, with their access role and invite status.
class EventMember {
  EventMember({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.inviteStatus,
    this.invitedByName,
    this.joinedAt,
  });

  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String inviteStatus;
  final String? invitedByName;
  final DateTime? joinedAt;

  bool get isOwner => role == 'OWNER';
  bool get isPending => inviteStatus == 'PENDING';

  factory EventMember.fromJson(Map<String, dynamic> j) => EventMember(
        userId: j['user_id'] as String,
        fullName: (j['full_name'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        role: (j['event_role'] as String?) ?? 'VIEWER',
        inviteStatus: (j['invite_status'] as String?) ?? 'PENDING',
        invitedByName: j['invited_by_name'] as String?,
        joinedAt: j['joined_at'] == null ? null : DateTime.tryParse(j['joined_at'] as String),
      );
}

/// The roles an OWNER/LEADER can grant when sharing an event.
/// OWNER is never assignable via invite (use transfer ownership instead).
const assignableRoles = <String>['LEADER', 'EDITOR', 'CONTRIBUTOR', 'VIEWER'];

/// Short human description of what each role can do.
String roleDescription(String role) {
  switch (role) {
    case 'OWNER':
      return 'Full control, can delete the event';
    case 'LEADER':
      return 'Co-organiser — full edit + manage members';
    case 'EDITOR':
      return 'Edit guests, gifts and itinerary';
    case 'CONTRIBUTOR':
      return 'Add guests and record gifts';
    case 'VIEWER':
      return 'Read-only access';
    default:
      return '';
  }
}
