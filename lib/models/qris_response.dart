class QrisResponse {
  final bool success;
  final String orderId;
  final int grossAmount;
  final String qrString;
  final String? qrImageUrl;
  final String? expiryTime;
  final bool isSandbox;
  final String? message;

  QrisResponse({
    required this.success,
    required this.orderId,
    required this.grossAmount,
    required this.qrString,
    this.qrImageUrl,
    this.expiryTime,
    this.isSandbox = true,
    this.message,
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
