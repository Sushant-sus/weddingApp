import '../../core/format.dart';

class Gift {
  Gift({
    required this.id,
    required this.guestId,
    required this.giftType,
    this.amount,
    this.description,
    required this.receivedAt,
    this.remarks,
    required this.familyName,
    this.giverName,
  });

  final String id;
  final String? guestId; // null for free-text giver gifts
  final String giftType; // CASH | KIND
  final num? amount;
  final String? description;
  final DateTime receivedAt;
  final String? remarks;
  final String familyName; // guest family name OR free-text giver name
  final String? giverName;

  bool get isCash => giftType == 'CASH';

  factory Gift.fromJson(Map<String, dynamic> j) => Gift(
        id: j['id'] as String,
        guestId: j['guest_id'] as String?,
        giftType: j['gift_type'] as String? ?? 'CASH',
        amount: j['amount'] == null ? null : parseMoney(j['amount']),
        description: j['description'] as String?,
        receivedAt: DateTime.tryParse(j['received_at'] as String? ?? '') ?? DateTime.now(),
        remarks: j['remarks'] as String?,
        familyName: j['family_name'] as String? ?? '',
        giverName: j['giver_name'] as String?,
      );
}

class GiftSummary {
  GiftSummary({required this.totalCash, required this.kindItems, required this.totalGifts});
  final num totalCash;
  final int kindItems;
  final int totalGifts;

  factory GiftSummary.fromJson(Map<String, dynamic> j) => GiftSummary(
        totalCash: parseMoney(j['total_cash']),
        kindItems: (j['total_kind_items'] as num?)?.toInt() ?? 0,
        totalGifts: (j['total_gifts'] as num?)?.toInt() ?? 0,
      );
}
