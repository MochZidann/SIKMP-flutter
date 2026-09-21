import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/owner_models.dart';
import 'pos_service.dart';

class OwnerService {
  static final OwnerService _instance = OwnerService._internal();
  factory OwnerService() => _instance;
  OwnerService._internal();

  /// Mengambil URL basis untuk modul Owner, mengikuti PosService.baseUrl
  String get ownerBaseUrl {
    final base = PosService.baseUrl;
    if (base.endsWith('/pos')) {
      return '${base.substring(0, base.length - 4)}/owner';
    }
    return '$base/owner';
  }

  /// 1. Mengambil data ringkasan eksekutif Dashboard
  Future<OwnerDashboardData?> getDashboard() async {
    try {
      final uri = Uri.parse('$ownerBaseUrl/dashboard');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return OwnerDashboardData.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('OwnerService getDashboard error: $e');
      return null;
    }
  }

  /// 2. Mengambil laporan penjualan terfilter (today, 7d, 30d, month)
  Future<OwnerSalesData?> getSalesReport({String filter = 'today'}) async {
    try {
      final uri = Uri.parse('$ownerBaseUrl/sales?filter=$filter');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return OwnerSalesData.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('OwnerService getSalesReport error: $e');
      return null;
    }
  }

  /// 3. Mengambil laporan kesehatan stok & valuasi aset
  Future<OwnerInventoryData?> getInventoryHealth() async {
    try {
      final uri = Uri.parse('$ownerBaseUrl/inventory-health');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return OwnerInventoryData.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('OwnerService getInventoryHealth error: $e');
      return null;
    }
  }
}
