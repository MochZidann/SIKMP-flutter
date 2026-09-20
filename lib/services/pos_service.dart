import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/qris_response.dart';
import '../models/sale_record.dart';
import 'auth_service.dart';

class PosService {
  // Singleton pattern
  static final PosService _instance = PosService._internal();
  factory PosService() => _instance;
  PosService._internal();

  static String baseUrl = _getDefaultBaseUrl();

  static String _getDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/pos';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api/pos';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000/api/pos';
  }

  /// Ambil daftar produk aktif dari database
  Future<List<Product>> getProducts({String? search}) async {
    try {
      final uri = Uri.parse('$baseUrl/products').replace(
        queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .map((item) => Product.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getProducts: $e');
      return [];
    }
  }

  /// Ambil riwayat penjualan dan statistik hari ini
  Future<Map<String, dynamic>> getSales({int? cashierId, String? date}) async {
    try {
      final queryParams = <String, String>{};
      if (cashierId != null) queryParams['cashierId'] = cashierId.toString();
      if (date != null && date.isNotEmpty) queryParams['date'] = date;

      final uri = Uri.parse('$baseUrl/sales').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List salesList = data['data'] as List? ?? [];
          final sales = salesList.map((item) => SaleRecord.fromJson(item)).toList();
          return {
            'stats': data['stats'] as Map<String, dynamic>? ?? {},
            'sales': sales,
          };
        }
      }
      return {'stats': {}, 'sales': <SaleRecord>[]};
    } catch (e) {
      debugPrint('Error getSales: $e');
      return {'stats': {}, 'sales': <SaleRecord>[]};
    }
  }

  /// Checkout pembayaran Tunai (Cash)
  Future<Map<String, dynamic>> checkoutTunai({
    List<Map<String, dynamic>>? items,
    int? amount,
    int? amountPaid,
    int? cashierId,
    String? promoCode,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/checkout');
      final body = <String, dynamic>{
        'cashierId': cashierId ?? AuthService().currentUser?.id ?? 1,
      };

      if (items != null && items.isNotEmpty) {
        body['items'] = items;
        if (promoCode != null) body['promoCode'] = promoCode;
      } else if (amount != null) {
        body['amount'] = amount;
      }
      if (amountPaid != null) body['amountPaid'] = amountPaid;

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] as Map<String, dynamic>? ?? {};
      } else {
        throw Exception(data['message'] ?? 'Gagal memproses transaksi tunai.');
      }
    } catch (e) {
      debugPrint('Error checkoutTunai: $e');
      rethrow;
    }
  }

  /// Request Generate Dynamic QRIS ke Laravel Midtrans API
  Future<QrisResponse> generateQris({
    List<Map<String, dynamic>>? items,
    int? amount,
    String? promoCode,
    int? cashierId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/qris/generate');
      final body = <String, dynamic>{
        'cashierId': cashierId ?? AuthService().currentUser?.id ?? 1,
      };

      if (items != null && items.isNotEmpty) {
        body['items'] = items;
        if (promoCode != null && promoCode.isNotEmpty) {
          body['promoCode'] = promoCode;
        }
      } else if (amount != null && amount > 0) {
        body['amount'] = amount;
      } else {
        throw Exception('Nominal atau daftar barang harus diisi.');
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return QrisResponse.fromJson(data);
      } else {
        throw Exception(data['message'] ?? 'Gagal generate QRIS');
      }
    } catch (e) {
      debugPrint('Error generateQris: $e');
      rethrow;
    }
  }

  /// Polling status pembayaran QRIS ke Laravel
  Future<QrisStatusResult> checkQrisStatus(String orderId) async {
    try {
      final uri = Uri.parse('$baseUrl/qris/check-status/$orderId');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      final data = json.decode(response.body);
      return QrisStatusResult.fromJson(data);
    } catch (e) {
      debugPrint('Error checkQrisStatus: $e');
      return QrisStatusResult(
        status: 'error',
        paid: false,
        message: 'Koneksi terputus saat cek status.',
      );
    }
  }

  /// Batalkan transaksi QRIS di Midtrans
  Future<bool> cancelQris(String orderId) async {
    try {
      final uri = Uri.parse('$baseUrl/qris/cancel/$orderId');
      final response = await http.post(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('Error cancelQris: $e');
      return false;
    }
  }

  /// Simulasi Bayar Cepat (Sandbox) langsung dari HP
  Future<QrisStatusResult> simulatePayment(String orderId) async {
    try {
      final uri = Uri.parse('$baseUrl/qris/simulate/$orderId');
      final response = await http.post(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      return QrisStatusResult(
        status: data['status'] ?? (data['success'] == true ? 'settlement' : 'failed'),
        paid: data['paid'] == true || data['success'] == true,
        message: data['message'] ?? '',
        data: data['data'] is Map<String, dynamic> ? data['data'] : null,
      );
    } catch (e) {
      debugPrint('Error simulatePayment: $e');
      return QrisStatusResult(
        status: 'error',
        paid: false,
        message: 'Gagal simulasi: $e',
      );
    }
  }
}
