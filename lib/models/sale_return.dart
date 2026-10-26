class SaleReturn {
  final int id;
  final String returnNo;
  final int saleId;
  final String saleTransactionId;
  final String? customerName;
  final String processedBy;
  final String returnDate;
  final String status;
  final String refundMethod;
  final int totalItems;
  final int totalRefundAmount;
  final int pointsReversed;
  final int pointsRefunded;
  final String reason;
  final String? note;
  final List<SaleReturnItem> items;

  SaleReturn({
    required this.id,
    required this.returnNo,
    required this.saleId,
    required this.saleTransactionId,
    this.customerName,
    required this.processedBy,
    required this.returnDate,
    required this.status,
    required this.refundMethod,
    required this.totalItems,
    required this.totalRefundAmount,
    this.pointsReversed = 0,
    this.pointsRefunded = 0,
    required this.reason,
    this.note,
    this.items = const [],
  });

  factory SaleReturn.fromJson(Map<String, dynamic> json) {
    return SaleReturn(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      returnNo: json['return_no'] ?? '',
      saleId: json['sale_id'] is int ? json['sale_id'] : int.tryParse(json['sale_id'].toString()) ?? 0,
      saleTransactionId: json['sale_transaction_id_snapshot'] ?? '',
      customerName: json['customer_name_snapshot'],
      processedBy: json['processed_by_snapshot'] ?? '',
      returnDate: json['return_date'] ?? '',
      status: json['status'] ?? 'POSTED',
      refundMethod: json['refund_method'] ?? 'CASH',
      totalItems: json['total_items'] is int ? json['total_items'] : int.tryParse(json['total_items'].toString()) ?? 0,
      totalRefundAmount: json['total_refund_amount'] is int ? json['total_refund_amount'] : int.tryParse(json['total_refund_amount'].toString()) ?? 0,
      pointsReversed: json['points_reversed'] is int ? json['points_reversed'] : int.tryParse(json['points_reversed'].toString()) ?? 0,
      pointsRefunded: json['points_refunded'] is int ? json['points_refunded'] : int.tryParse(json['points_refunded'].toString()) ?? 0,
      reason: json['reason'] ?? '',
      note: json['note'],
      items: (json['items'] as List?)
              ?.map((item) => SaleReturnItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class SaleReturnItem {
  final int id;
  final int saleReturnId;
  final int saleItemId;
  final int productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int subtotal;
  final String condition;
  final String action;
  final String? note;

  SaleReturnItem({
    required this.id,
    required this.saleReturnId,
    required this.saleItemId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.condition,
    required this.action,
    this.note,
  });

  factory SaleReturnItem.fromJson(Map<String, dynamic> json) {
    return SaleReturnItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      saleReturnId: json['sale_return_id'] is int ? json['sale_return_id'] : int.tryParse(json['sale_return_id'].toString()) ?? 0,
      saleItemId: json['sale_item_id'] is int ? json['sale_item_id'] : int.tryParse(json['sale_item_id'].toString()) ?? 0,
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id'].toString()) ?? 0,
      productName: json['product_name_snapshot'] ?? '',
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity'].toString()) ?? 0,
      unitPrice: json['unit_price'] is int ? json['unit_price'] : int.tryParse(json['unit_price'].toString()) ?? 0,
      subtotal: json['subtotal'] is int ? json['subtotal'] : int.tryParse(json['subtotal'].toString()) ?? 0,
      condition: json['condition'] ?? 'GOOD',
      action: json['action'] ?? 'RESTOCK',
      note: json['note'],
    );
  }
}

class SaleReturnableItem {
  final int saleItemId;
  final int productId;
  final String productName;
  final String productCode;
  final int unitPrice;
  final int quantitySold;
  final int quantityReturned;
  final int quantityReturnable;

  SaleReturnableItem({
    required this.saleItemId,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.unitPrice,
    required this.quantitySold,
    required this.quantityReturned,
    required this.quantityReturnable,
  });

  factory SaleReturnableItem.fromJson(Map<String, dynamic> json) {
    return SaleReturnableItem(
      saleItemId: json['sale_item_id'] is int ? json['sale_item_id'] : int.tryParse(json['sale_item_id'].toString()) ?? 0,
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id'].toString()) ?? 0,
      productName: json['product_name'] ?? '',
      productCode: json['product_code'] ?? '-',
      unitPrice: json['unit_price'] is int ? json['unit_price'] : int.tryParse(json['unit_price'].toString()) ?? 0,
      quantitySold: json['quantity_sold'] is int ? json['quantity_sold'] : int.tryParse(json['quantity_sold'].toString()) ?? 0,
      quantityReturned: json['quantity_returned'] is int ? json['quantity_returned'] : int.tryParse(json['quantity_returned'].toString()) ?? 0,
      quantityReturnable: json['quantity_returnable'] is int ? json['quantity_returnable'] : int.tryParse(json['quantity_returnable'].toString()) ?? 0,
    );
  }
}