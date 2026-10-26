import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/services/api_http.dart' as http;
import '../core/config/api_config.dart';
import '../models/sale_return.dart';

class ReturnService {
  static final ReturnService _instance = ReturnService._internal();
  factory ReturnService() => _instance;
  ReturnService._internal();

  String get baseUrl => ApiConfig.returnsUrl;

  Future<Map<String, dynamic>> getPurchaseReceipts({
    String search = '',
    int page = 1,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/purchases/receipts',
    ).replace(queryParameters: {'search': search, 'page': '$page'});
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('Gagal memuat penerimaan');
    return Map<String, dynamic>.from(json.decode(response.body) as Map);
  }

  Future<List<Map<String, dynamic>>> getPurchaseReturns() async {
    final response = await http
        .get(Uri.parse('$baseUrl/purchases'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('Gagal memuat retur');
    return List<Map<String, dynamic>>.from(
      json.decode(response.body)['data'] as List,
    );
  }

  /// Mengambil rincian barang yang dapat diretur untuk suatu transaksi penjualan
  Future<Map<String, dynamic>?> getSaleReturnableSummary(dynamic saleId) async {
    try {
      final uri = Uri.parse('$baseUrl/sales/summary/$saleId');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('ReturnService getSaleReturnableSummary error: $e');
      return null;
    }
  }

  /// Membuat dan memproses transaksi Retur Penjualan (Customer Return)
  Future<Map<String, dynamic>> createSaleReturn({
    required dynamic saleId,
    required List<Map<String, dynamic>> items,
    String refundMethod = 'CASH',
    String? reason,
    String? note,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/sales');
      final payload = {
        'sale_id': saleId,
        'refund_method': refundMethod,
        'reason': reason ?? 'Retur Penjualan',
        'note': note,
        'items': items,
      };

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Retur penjualan berhasil diproses',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
            'Gagal memproses retur penjualan (${response.statusCode})',
        'errors': data['errors'],
      };
    } catch (e) {
      debugPrint('ReturnService createSaleReturn error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan jaringan atau koneksi ke server: $e',
      };
    }
  }

  /// Mengambil daftar riwayat retur penjualan
  Future<List<SaleReturn>> getSaleReturns({
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse(
        '$baseUrl/sales',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = decoded['data'] as List?;
        if (list != null) {
          return list.map((item) => SaleReturn.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('ReturnService getSaleReturns error: $e');
      return [];
    }
  }

  /// Mengambil rincian barang yang dapat diretur ke supplier untuk suatu penerimaan barang
  Future<Map<String, dynamic>?> getReceiptReturnableSummary(
    dynamic receiptId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/purchases/summary/$receiptId');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('ReturnService getReceiptReturnableSummary error: $e');
      return null;
    }
  }

  /// Membuat dan memproses transaksi Retur Pembelian ke Supplier
  Future<Map<String, dynamic>> createPurchaseReturn({
    required int supplierId,
    dynamic goodsReceiptId,
    required List<Map<String, dynamic>> items,
    String? reason,
    String? note,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/purchases');
      final payload = <String, dynamic>{
        'supplier_id': supplierId,
        'reason': reason ?? 'Retur Pembelian ke Supplier',
        'note': note,
        'items': items,
      };
      if (goodsReceiptId != null) {
        payload['goods_receipt_id'] = goodsReceiptId;
      }

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Retur pembelian berhasil diproses',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
            'Gagal memproses retur pembelian (${response.statusCode})',
        'errors': data['errors'],
      };
    } catch (e) {
      debugPrint('ReturnService createPurchaseReturn error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan jaringan atau koneksi ke server: $e',
      };
    }
  }
}
