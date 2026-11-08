class StockMovement {
  final int id;
  final int productId;
  final int? userId;
  final String type; // 'IN', 'OUT', 'ADJUST'
  final int quantityDelta;
  final int? supplierId;
  final String? supplierName;
  final String? productName;
  final String? referenceNo;
  final String? claimStatus;
  final String? note;
  final int? createdAtEpochMs;

  const StockMovement({
    required this.id,
    required this.productId,
    this.userId,
    this.supplierId,
    this.supplierName,
    this.productName,
    this.referenceNo,
    this.claimStatus,
    required this.type,
    required this.quantityDelta,
    this.note,
    this.createdAtEpochMs,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    // Parse nested supplier or product if present
    String? sName;
    if (json['supplier'] is Map<String, dynamic>) {
      sName = json['supplier']['name']?.toString();
    } else {
      sName = json['supplier_name']?.toString() ?? json['supplierName']?.toString();
    }

    String? pName;
    if (json['product'] is Map<String, dynamic>) {
      pName = json['product']['name']?.toString();
    } else {
      pName = json['product_name']?.toString() ?? json['productName']?.toString();
    }

    return StockMovement(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: json['productId'] is int
          ? json['productId']
          : int.tryParse(json['product_id']?.toString() ?? json['productId']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['user_id']?.toString() ?? json['userId']?.toString() ?? ''),
      supplierId: json['supplierId'] is int
          ? json['supplierId']
          : int.tryParse(json['supplier_id']?.toString() ?? json['supplierId']?.toString() ?? ''),
      supplierName: sName,
      productName: pName,
      referenceNo: json['reference_no']?.toString() ?? json['referenceNo']?.toString(),
      claimStatus: json['claim_status']?.toString() ?? json['claimStatus']?.toString(),
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
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'product_name': productName,
      'reference_no': referenceNo,
      'claim_status': claimStatus,
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
