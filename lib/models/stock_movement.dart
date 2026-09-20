class StockMovement {
  final int id;
  final int productId;
  final int? userId;
  final String type; // 'IN', 'OUT', 'ADJUST'
  final int quantityDelta;
  final String? note;
  final int? createdAtEpochMs;

  const StockMovement({
    required this.id,
    required this.productId,
    this.userId,
    required this.type,
    required this.quantityDelta,
    this.note,
    this.createdAtEpochMs,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: json['productId'] is int
          ? json['productId']
          : int.tryParse(json['product_id']?.toString() ?? json['productId']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['user_id']?.toString() ?? json['userId']?.toString() ?? ''),
      type: json['type']?.toString().toUpperCase() ?? 'IN',
      quantityDelta: json['quantityDelta'] is int
          ? json['quantityDelta']
          : int.tryParse(json['quantity_delta']?.toString() ?? json['quantityDelta']?.toString() ?? '0') ?? 0,
      note: json['note']?.toString(),
      createdAtEpochMs: json['createdAtEpochMs'] is int
          ? json['createdAtEpochMs']
          : int.tryParse(json['created_at_epoch_ms']?.toString() ?? json['createdAtEpochMs']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'type': type,
      'quantityDelta': quantityDelta,
      'note': note,
      'createdAtEpochMs': createdAtEpochMs,
    };
  }

  bool get isIn => type == 'IN';
  bool get isOut => type == 'OUT';
  bool get isAdjust => type == 'ADJUST';
}
