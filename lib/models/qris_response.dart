class QrisResponse {
  final bool success;
  final String orderId;
  final int grossAmount;
  final String qrString;
  final String? qrImageUrl;
  final String? expiryTime;
  final bool isSandbox;
  final String? message;
  final int? memberId;
  final String? memberNo;
  final String? customerName;
  final int pointsEarned;
  final int pointsRedeemed;
  final int pointsDiscount;
  final int memberDiscount;

  QrisResponse({
    required this.success,
    required this.orderId,
    required this.grossAmount,
    required this.qrString,
    this.qrImageUrl,
    this.expiryTime,
    this.isSandbox = true,
    this.message,
    this.memberId,
    this.memberNo,
    this.customerName,
    this.pointsEarned = 0,
    this.pointsRedeemed = 0,
    this.pointsDiscount = 0,
    this.memberDiscount = 0,
  });

  factory QrisResponse.fromJson(Map<String, dynamic> json) {
    return QrisResponse(
      success: json['success'] == true,
      orderId: json['order_id']?.toString() ?? '',
      grossAmount: json['gross_amount'] is int
          ? json['gross_amount']
          : (int.tryParse(json['gross_amount']?.toString() ?? '0') ?? 0),
      qrString: json['qr_string']?.toString() ?? '',
      qrImageUrl: json['qr_image_url']?.toString(),
      expiryTime: json['expiry_time']?.toString(),
      isSandbox: json['is_sandbox'] == true,
      message: json['message']?.toString(),
      memberId: json['member_id'] is int
          ? json['member_id']
          : int.tryParse(json['member_id']?.toString() ?? ''),
      memberNo: json['member_no']?.toString(),
      customerName: json['customer_name']?.toString(),
      pointsEarned: json['points_earned'] is int
          ? json['points_earned']
          : (int.tryParse(json['points_earned']?.toString() ?? '0') ?? 0),
      pointsRedeemed: json['points_redeemed'] is int
          ? json['points_redeemed']
          : (int.tryParse(json['points_redeemed']?.toString() ?? '0') ?? 0),
      pointsDiscount: json['points_discount'] is int
          ? json['points_discount']
          : (int.tryParse(json['points_discount']?.toString() ?? '0') ?? 0),
      memberDiscount: json['member_discount'] is int
          ? json['member_discount']
          : (int.tryParse(json['member_discount']?.toString() ?? '0') ?? 0),
    );
  }
}

class QrisStatusResult {
  final String status;
  final bool paid;
  final String message;
  final Map<String, dynamic>? data;

  QrisStatusResult({
    required this.status,
    required this.paid,
    required this.message,
    this.data,
  });

  factory QrisStatusResult.fromJson(Map<String, dynamic> json) {
    return QrisStatusResult(
      status: json['status']?.toString() ?? 'unknown',
      paid: json['paid'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
    );
  }
}
