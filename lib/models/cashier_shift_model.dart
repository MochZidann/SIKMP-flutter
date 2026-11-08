class CashierShiftModel {
  final int id;
  final int? cashierId;
  final String cashierName;
  final String status;
  final String statusLabel;
  final int openingCash;
  final int expectedCash;
  final int countedCash;
  final int difference;
  final int retainedCash;
  final String? openedAt;
  final String? closedAt;
  final String? closingNote;
  final String? reviewNote;
  final String? approvedBy;
  final String? approvedAt;
  final Map<String, dynamic> summary;

  const CashierShiftModel({
    required this.id,
    this.cashierId,
    required this.cashierName,
    required this.status,
    required this.statusLabel,
    required this.openingCash,
    required this.expectedCash,
    required this.countedCash,
    required this.difference,
    required this.retainedCash,
    this.openedAt,
    this.closedAt,
    this.closingNote,
    this.reviewNote,
    this.approvedBy,
    this.approvedAt,
    this.summary = const {},
  });

  bool get isOpen => status == 'OPEN';
  bool get isClosed => status == 'CLOSED';
  bool get isApproved => status == 'APPROVED';
  bool get isRecount => status == 'RECOUNT';
  bool get hasDifference => difference != 0;

  factory CashierShiftModel.fromJson(Map<String, dynamic> json) {
    return CashierShiftModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      cashierId: json['cashier_id'] is int
          ? json['cashier_id']
          : int.tryParse(json['cashier_id']?.toString() ?? ''),
      cashierName: json['cashier_name']?.toString() ?? 'Kasir',
      status: json['status']?.toString().toUpperCase() ?? 'OPEN',
      statusLabel: json['status_label']?.toString() ?? 'Aktif',
      openingCash: json['opening_cash'] is int
          ? json['opening_cash']
          : int.tryParse(json['opening_cash']?.toString() ?? '0') ?? 0,
      expectedCash: json['expected_cash'] is int
          ? json['expected_cash']
          : int.tryParse(json['expected_cash']?.toString() ?? '0') ?? 0,
      countedCash: json['counted_cash'] is int
          ? json['counted_cash']
          : int.tryParse(json['counted_cash']?.toString() ?? '0') ?? 0,
      difference: json['difference'] is int
          ? json['difference']
          : int.tryParse(json['difference']?.toString() ?? '0') ?? 0,
      retainedCash: json['retained_cash'] is int
          ? json['retained_cash']
          : int.tryParse(json['retained_cash']?.toString() ?? '0') ?? 0,
      openedAt: json['opened_at']?.toString(),
      closedAt: json['closed_at']?.toString(),
      closingNote: json['closing_note']?.toString(),
      reviewNote: json['review_note']?.toString(),
      approvedBy: json['approved_by']?.toString(),
      approvedAt: json['approved_at']?.toString(),
      summary: json['summary'] is Map<String, dynamic> ? json['summary'] as Map<String, dynamic> : {},
    );
  }
}

