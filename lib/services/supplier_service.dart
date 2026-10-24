import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/supplier.dart';
import '../models/supplier_mutation.dart';

class SupplierService {
  static final SupplierService _instance = SupplierService._internal();
  factory SupplierService() => _instance;
  SupplierService._internal();

  String get baseUrl => ApiConfig.suppliersUrl;

  /// Mengambil daftar semua supplier
  Future<List<Supplier>> getSuppliers({String? search}) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final dynamic dataList = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
        if (dataList is List) {
          return dataList.map((item) => Supplier.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('SupplierService getSuppliers error: $e');
      return [];
    }
  }

  /// Tambah supplier baru
  Future<Map<String, dynamic>> createSupplier({
    required String name,
    String? code,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? note,
  }) async {
    try {
      final uri = Uri.parse(baseUrl);
      final body = {
        'name': name.trim(),
        if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
        if (contactPerson != null && contactPerson.trim().isNotEmpty) 'contact_person': contactPerson.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Supplier berhasil ditambahkan',
          'supplier': data['data'] != null ? Supplier.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambahkan supplier',
        };
      }
    } catch (e) {
      debugPrint('SupplierService createSupplier error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }

  /// Perbarui data supplier
  Future<Map<String, dynamic>> updateSupplier(
    int id, {
    required String name,
    String? code,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? note,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final body = {
        'name': name.trim(),
        if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
        if (contactPerson != null && contactPerson.trim().isNotEmpty) 'contact_person': contactPerson.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Supplier berhasil diperbarui',
          'supplier': data['data'] != null ? Supplier.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memperbarui supplier',
        };
      }
    } catch (e) {
      debugPrint('SupplierService updateSupplier error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }

  /// Hapus supplier
  Future<Map<String, dynamic>> deleteSupplier(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.delete(uri).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Supplier berhasil dihapus',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus supplier',
        };
      }
    } catch (e) {
      debugPrint('SupplierService deleteSupplier error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }

  /// Ambil riwayat mutasi barang masuk/keluar untuk supplier tertentu
  Future<Map<String, dynamic>> getSupplierMutations(int supplierId, {String? type}) async {
    try {
      final uri = Uri.parse('$baseUrl/$supplierId/mutations').replace(queryParameters: {
        if (type != null && type.isNotEmpty && type != 'ALL') 'type': type,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final dynamic data = decoded['data'];
        if (data is Map<String, dynamic>) {
          final mutationsRaw = data['mutations'] as List? ?? [];
          final mutations = mutationsRaw.map((m) => SupplierMutation.fromJson(m)).toList();
          return {
            'success': true,
            'mutations': mutations,
            'summary': data['summary'] ?? {'totalIn': 0, 'totalOut': 0, 'net': 0},
          };
        }
      }
      return {
        'success': false,
        'mutations': <SupplierMutation>[],
        'summary': {'totalIn': 0, 'totalOut': 0, 'net': 0},
      };
    } catch (e) {
      debugPrint('SupplierService getSupplierMutations error: $e');
      return {
        'success': false,
        'mutations': <SupplierMutation>[],
        'summary': {'totalIn': 0, 'totalOut': 0, 'net': 0},
      };
    }
  }
}
