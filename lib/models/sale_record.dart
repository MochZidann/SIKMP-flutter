class SaleRecord {
  final int id;
  final String transactionId;
  final int cashierId;
  final String? cashierName;
  final int subtotal;
  final int discount;
  final int tax;
  final int total;
  final String paymentMethod;
  final String status;
  final int? memberId;
  final String? memberNo;
  final int pointsEarned;
  final int pointsRedeemed;
  final int pointsDiscount;
  final int memberDiscount;
  final int createdAtEpochMs;
  final List<SaleRecordItem> items;

  SaleRecord({
    required this.id,
    required this.transactionId,
    required this.cashierId,
    this.cashierName,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.status,
    this.memberId,
    this.memberNo,
    this.pointsEarned = 0,
    this.pointsRedeemed = 0,
    this.pointsDiscount = 0,
    this.memberDiscount = 0,
    required this.createdAtEpochMs,
    required this.items,
  });

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      transactionId: json['transactionId']?.toString() ?? '',
      cashierId: json['cashierId'] is int
          ? json['cashierId']
          : int.parse(json['cashierId']?.toString() ?? '1'),
      cashierName: json['cashier']?['name']?.toString() ?? 'Kasir',
      subtotal: (json['subtotal'] is num
              ? json['subtotal']
              : num.tryParse(json['subtotal']?.toString() ?? '0') ?? 0)
          .toInt(),
      discount: (json['discount'] is num
              ? json['discount']
              : num.tryParse(json['discount']?.toString() ?? '0') ?? 0)
          .toInt(),
      tax: (json['tax'] is num
              ? json['tax']
              : num.tryParse(json['tax']?.toString() ?? '0') ?? 0)
          .toInt(),
      total: (json['total'] is num
              ? json['total']
              : num.tryParse(json['total']?.toString() ?? '0') ?? 0)
          .toInt(),
      paymentMethod: json['paymentMethod']?.toString() ?? 'TUNAI',
      status: json['status']?.toString() ?? 'SUCCESS',
      memberId: json['memberId'] is int
          ? json['memberId']
          : (json['member_id'] is int
              ? json['member_id']
              : int.tryParse(json['memberId']?.toString() ?? json['member_id']?.toString() ?? '')),
      memberNo: json['memberNo']?.toString() ?? json['member_no']?.toString(),
      pointsEarned: (json['pointsEarned'] is num
              ? json['pointsEarned']
              : (json['points_earned'] is num
                  ? json['points_earned']
                  : num.tryParse(json['pointsEarned']?.toString() ?? json['points_earned']?.toString() ?? '0') ?? 0))
          .toInt(),
      pointsRedeemed: (json['pointsRedeemed'] is num
              ? json['pointsRedeemed']
              : (json['points_redeemed'] is num
                  ? json['points_redeemed']
                  : num.tryParse(json['pointsRedeemed']?.toString() ?? json['points_redeemed']?.toString() ?? '0') ?? 0))
          .toInt(),
      pointsDiscount: (json['pointsDiscount'] is num
              ? json['pointsDiscount']
              : (json['points_discount'] is num
                  ? json['points_discount']
                  : num.tryParse(json['pointsDiscount']?.toString() ?? json['points_discount']?.toString() ?? '0') ?? 0))
          .toInt(),
      memberDiscount: (json['memberDiscount'] is num
              ? json['memberDiscount']
              : (json['member_discount'] is num
                  ? json['member_discount']
                  : num.tryParse(json['memberDiscount']?.toString() ?? json['member_discount']?.toString() ?? '0') ?? 0))
          .toInt(),
      createdAtEpochMs: json['createdAtEpochMs'] is int
          ? json['createdAtEpochMs']
          : int.tryParse(json['createdAtEpochMs']?.toString() ?? '0') ?? 0,
      items: (json['items'] as List? ?? [])
          .map((i) => SaleRecordItem.fromJson(i))
          .toList(),
    );
  }
}

class SaleRecordItem {
  final int id;
  final int productId;
  final String productName;
  final int unitPrice;
  final int quantity;
  final int lineTotal;

  SaleRecordItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory SaleRecordItem.fromJson(Map<String, dynamic> json) {
    return SaleRecordItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: json['productId'] is int
          ? json['productId']
          : int.tryParse(json['productId']?.toString() ?? '0') ?? 0,
      productName: json['productName']?.toString() ?? 'Produk',
      unitPrice: (json['unitPrice'] is num
              ? json['unitPrice']
              : num.tryParse(json['unitPrice']?.toString() ?? '0') ?? 0)
          .toInt(),
      quantity: (json['quantity'] is num
              ? json['quantity']
              : num.tryParse(json['quantity']?.toString() ?? '0') ?? 0)
          .toInt(),
      lineTotal: (json['lineTotal'] is num
              ? json['lineTotal']
              : num.tryParse(json['lineTotal']?.toString() ?? '0') ?? 0)
          .toInt(),
    );
  }
}
