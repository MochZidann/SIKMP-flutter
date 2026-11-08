class SaleReturnItemModel {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int subtotal;
  final String condition;
  final String conditionLabel;
  final String? supplierName;
  final String? note;

  const SaleReturnItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.condition,
    required this.conditionLabel,
    this.supplierName,
    this.note,
  });

  factory SaleReturnItemModel.fromJson(Map<String, dynamic> json) {
    return SaleReturnItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? 'Barang',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unitPrice: json['unit_price'] is int
          ? json['unit_price']
          : int.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
      subtotal: json['subtotal'] is int
          ? json['subtotal']
          : int.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      condition: json['condition']?.toString() ?? 'RUSAK',
      conditionLabel: json['condition_label']?.toString() ?? 'Barang Rusak',
      supplierName: json['supplier_name']?.toString(),
      note: json['note']?.toString(),
    );
  }
}

class SaleReturnModel {
  final int id;
  final String returnNo;
  final String transactionId;
  final int? saleId;
  final int? cashierId;
  final String cashierName;
  final String customerName;
  final String customerPhone;
  final String reason;
  final String reasonLabel;
  final String actionType;
  final String actionTypeLabel;
  final int totalRefund;
  final String? note;
  final int itemCount;
  final int? createdAtEpochMs;
  final String? createdAtFormatted;
  final List<SaleReturnItemModel> items;

  const SaleReturnModel({
    required this.id,
    required this.returnNo,
    required this.transactionId,
    this.saleId,
    this.cashierId,
    required this.cashierName,
    required this.customerName,
    required this.customerPhone,
    required this.reason,
    required this.reasonLabel,
    required this.actionType,
    required this.actionTypeLabel,
    required this.totalRefund,
    this.note,
    required this.itemCount,
    this.createdAtEpochMs,
    this.createdAtFormatted,
    this.items = const [],
  });

  factory SaleReturnModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<SaleReturnItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems.map((i) => SaleReturnItemModel.fromJson(i as Map<String, dynamic>)).toList();
    }

    return SaleReturnModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      returnNo: json['return_no']?.toString() ?? 'RET-000',
      transactionId: json['transactionId']?.toString() ?? '-',
      saleId: json['sale_id'] is int ? json['sale_id'] : int.tryParse(json['sale_id']?.toString() ?? ''),
      cashierId: json['cashier_id'] is int ? json['cashier_id'] : int.tryParse(json['cashier_id']?.toString() ?? ''),
      cashierName: json['cashier_name']?.toString() ?? 'Kasir',
      customerName: json['customer_name']?.toString() ?? 'Umum',
      customerPhone: json['customer_phone']?.toString() ?? '-',
      reason: json['reason']?.toString() ?? 'RUSAK',
      reasonLabel: json['reason_label']?.toString() ?? 'Barang Rusak',
      actionType: json['action_type']?.toString() ?? 'REFUND_CASH',
      actionTypeLabel: json['action_type_label']?.toString() ?? 'Refund Uang Tunai',
      totalRefund: json['total_refund'] is int
          ? json['total_refund']
          : int.tryParse(json['total_refund']?.toString() ?? '0') ?? 0,
      note: json['note']?.toString(),
      itemCount: json['item_count'] is int
          ? json['item_count']
          : int.tryParse(json['item_count']?.toString() ?? '0') ?? parsedItems.length,
      createdAtEpochMs: json['createdAtEpochMs'] is int
          ? json['createdAtEpochMs']
          : int.tryParse(json['createdAtEpochMs']?.toString() ?? ''),
      createdAtFormatted: json['created_at']?.toString(),
      items: parsedItems,
    );
  }
}

