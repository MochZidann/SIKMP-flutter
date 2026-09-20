import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/stock_movement.dart';
import 'auth_service.dart';
import 'pos_service.dart';

class GudangService {
  static final GudangService _instance = GudangService._internal();
  factory GudangService() => _instance;
  GudangService._internal();

  final PosService _posService = PosService();

  String get syncBaseUrl {
    final base = PosService.baseUrl;
    if (base.endsWith('/pos')) {
      return '${base.substring(0, base.length - 4)}/sync';
    }
    return '$base/sync';
  }

  /// Mengambil daftar semua produk untuk inventaris gudang
  Future<List<Product>> getProducts({String? search}) async {
    return _posService.getProducts(search: search);
  }

  /// Mengambil riwayat mutasi / pergerakan stok
  Future<List<StockMovement>> getStockMovements() async {
    try {
      final uri = Uri.parse('$syncBaseUrl/stock-movements');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          final movements = data.map((item) => StockMovement.fromJson(item)).toList();
          movements.sort((a, b) => (b.createdAtEpochMs ?? 0).compareTo(a.createdAtEpochMs ?? 0));
          return movements;
        }
      }
      return [];
    } catch (e) {
      debugPrint('GudangService getStockMovements error: $e');
      return [];
    }
  }

  /// Mencatat barang masuk (Stock In) dan menambah stok produk
  Future<bool> recordStockIn({
    required Product product,
    required int quantity,
    String? note,
  }) async {
    try {
      final currentUserId = AuthService().currentUser?.id ?? 1;
      final nowEpoch = DateTime.now().millisecondsSinceEpoch;

      // 1. Catat mutasi stok
      final movementUri = Uri.parse('$syncBaseUrl/stock-movements');
      final movementPayload = [
        {
          'productId': product.id,
          'userId': currentUserId,
          'type': 'IN',
          'quantityDelta': quantity,
          'note': note ?? 'Barang Masuk Gudang',
          'createdAtEpochMs': nowEpoch,
        }
      ];

      final moveRes = await http.post(
        movementUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(movementPayload),
      ).timeout(const Duration(seconds: 10));

      // 2. Perbarui stok produk
      final newStock = product.stock + quantity;
      final productUri = Uri.parse('$syncBaseUrl/products');
      final prodPayload = [
        {
          'id': product.id,
          'name': product.name,
          'barcode': product.barcode,
          'category': product.category,
          'price': product.price,
          'stock': newStock,
          'imagePath': product.imagePath,
        }
      ];

      await http.post(
        productUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(prodPayload),
      ).timeout(const Duration(seconds: 10));

      return moveRes.statusCode == 200;
    } catch (e) {
      debugPrint('GudangService recordStockIn error: $e');
      return false;
    }
  }

  /// Melakukan penyesuaian stok (Stock Opname)
  Future<bool> adjustStock({
    required Product product,
    required int newStock,
    String? note,
  }) async {
    try {
      final currentUserId = AuthService().currentUser?.id ?? 1;
      final delta = newStock - product.stock;
      final nowEpoch = DateTime.now().millisecondsSinceEpoch;

      // 1. Catat mutasi stok penyesuaian
      final movementUri = Uri.parse('$syncBaseUrl/stock-movements');
      final movementPayload = [
        {
          'productId': product.id,
          'userId': currentUserId,
          'type': 'ADJUST',
          'quantityDelta': delta,
          'note': note ?? 'Penyesuaian Stok Fisik (Opname)',
          'createdAtEpochMs': nowEpoch,
        }
      ];

      await http.post(
        movementUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(movementPayload),
      ).timeout(const Duration(seconds: 10));

      // 2. Perbarui stok produk
      final productUri = Uri.parse('$syncBaseUrl/products');
      final prodPayload = [
        {
          'id': product.id,
          'name': product.name,
          'barcode': product.barcode,
          'category': product.category,
          'price': product.price,
          'stock': newStock,
          'imagePath': product.imagePath,
        }
      ];

      final res = await http.post(
        productUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(prodPayload),
      ).timeout(const Duration(seconds: 10));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('GudangService adjustStock error: $e');
      return false;
    }
  }

  /// Mengambil daftar kategori produk
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final uri = Uri.parse('$syncBaseUrl/categories');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('GudangService getCategories error: $e');
      return [];
    }
  }

  /// Menghitung ringkasan inventaris untuk dashboard
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final productsFuture = getProducts();
      final movementsFuture = getStockMovements();
      final results = await Future.wait([productsFuture, movementsFuture]);

      final products = results[0] as List<Product>;
      final movements = results[1] as List<StockMovement>;

      int lowStockCount = 0;
      int outOfStockCount = 0;
      int totalValuation = 0;

      for (final p in products) {
        if (p.stock <= 0) {
          outOfStockCount++;
        } else if (p.stock <= 5) {
          lowStockCount++;
        }
        totalValuation += (p.stock * p.price);
      }

      // Hitung mutasi hari ini
      final now = DateTime.now();
      final startOfDayMs = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final todayMovements = movements.where((m) => (m.createdAtEpochMs ?? 0) >= startOfDayMs).length;

      return {
        'totalProducts': products.length,
        'lowStockCount': lowStockCount,
        'outOfStockCount': outOfStockCount,
        'totalValuation': totalValuation,
        'todayMovements': todayMovements,
        'recentMovements': movements.take(5).toList(),
      };
    } catch (e) {
      debugPrint('GudangService getInventoryStats error: $e');
      return {
        'totalProducts': 0,
        'lowStockCount': 0,
        'outOfStockCount': 0,
        'totalValuation': 0,
        'todayMovements': 0,
        'recentMovements': <StockMovement>[],
      };
    }
  }
}
