class SupplierMutation {
  final int id;
  final int? supplierId;
  final int productId;
  final String productName;
  final String? barcode;
  final String type; // 'IN' or 'OUT'
  final int quantityDelta;
  final String? note;
  final int? createdAtEpochMs;
  final String? userName;

  const SupplierMutation({
    required this.id,
    this.supplierId,
    required this.productId,
    required this.productName,
    this.barcode,
    required this.type,
    required this.quantityDelta,
    this.note,
    this.createdAtEpochMs,
    this.userName,
  });

  factory SupplierMutation.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;

    return SupplierMutation(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      supplierId: json['supplier_id'] is int
          ? json['supplier_id']
          : int.tryParse(json['supplier_id']?.toString() ?? ''),
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: product?['name']?.toString() ?? json['product_name']?.toString() ?? 'Produk',
      barcode: product?['barcode']?.toString() ?? json['barcode']?.toString(),
      type: json['type']?.toString().toUpperCase() ?? 'IN',
      quantityDelta: (json['quantityDelta'] is num)
          ? (json['quantityDelta'] as num).toInt()
          : (json['quantity_delta'] is num)
              ? (json['quantity_delta'] as num).toInt()
              : int.tryParse(json['quantityDelta']?.toString() ?? json['quantity_delta']?.toString() ?? '0') ?? 0,
      note: json['note']?.toString(),
      createdAtEpochMs: (json['createdAtEpochMs'] is num)
          ? (json['createdAtEpochMs'] as num).toInt()
          : (json['created_at_epoch_ms'] is num)
              ? (json['created_at_epoch_ms'] as num).toInt()
              : int.tryParse(json['createdAtEpochMs']?.toString() ?? json['created_at_epoch_ms']?.toString() ?? ''),
      userName: user?['name']?.toString() ?? json['user_name']?.toString(),
    );
  }
}
