import '../../core/format.dart';

class CostItem {
  CostItem({
    required this.id,
    required this.category,
    required this.itemName,
    required this.estimated,
    this.actual,
    this.vendor,
    required this.paymentStatus,
    this.notes,
  });

  final String id;
  final String category;
  final String itemName;
  final num estimated;
  final num? actual;
  final String? vendor;
  final String paymentStatus; // UNPAID | PARTIAL | PAID
  final String? notes;

  factory CostItem.fromJson(Map<String, dynamic> j) => CostItem(
        id: j['id'] as String,
        category: j['category'] as String? ?? 'Other',
        itemName: j['item_name'] as String? ?? '',
        estimated: parseMoney(j['estimated_cost']),
        actual: j['actual_cost'] == null ? null : parseMoney(j['actual_cost']),
        vendor: j['vendor'] as String?,
        paymentStatus: j['payment_status'] as String? ?? 'UNPAID',
        notes: j['notes'] as String?,
      );
}

class CostSummary {
  CostSummary({required this.estimated, required this.actual, required this.variance});
  final num estimated;
  final num actual;
  final num variance;

  factory CostSummary.fromJson(Map<String, dynamic> j) => CostSummary(
        estimated: parseMoney(j['grand_estimated']),
        actual: parseMoney(j['grand_actual']),
        variance: parseMoney(j['variance']),
      );
}
