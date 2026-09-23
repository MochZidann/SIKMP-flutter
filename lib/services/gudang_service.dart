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

  String get gudangBaseUrl {
    final base = PosService.baseUrl;
    if (base.endsWith('/pos')) {
      return '${base.substring(0, base.length - 4)}/gudang';
    }
    return '$base/gudang';
  }

  // ── PRODUK (PRODUCT CRUD) ─────────────────────────────────────

  /// Mengambil daftar produk gudang dengan opsi pencarian & filter stok
  Future<List<Product>> getProducts({String? search, String? status}) async {
    try {
      final uri = Uri.parse('$gudangBaseUrl/products').replace(
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (status != null && status != 'ALL') 'status': status,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final dynamic jsonResp = json.decode(response.body);
        if (jsonResp['success'] == true && jsonResp['data'] is List) {
          final List list = jsonResp['data'];
          return list.map((item) => Product.fromJson(item)).toList();
        }
      }
      // Fallback ke PosService jika endpoint gudang belum sinkron
      return _posService.getProducts(search: search);
    } catch (e) {
      debugPrint('GudangService getProducts error: $e');
      return _posService.getProducts(search: search);
    }
  }

  /// Menambahkan barang baru ke katalog gudang
  Future<Map<String, dynamic>> storeProduct(Product product, {int? userId}) async {
    try {
      final currentUserId = userId ?? AuthService().currentUser?.id ?? 1;
      final uri = Uri.parse('$gudangBaseUrl/products');

      final payload = {
        'name': product.name.trim(),
        'barcode': (product.barcode != null && product.barcode!.trim().isNotEmpty)
            ? product.barcode!.trim()
            : null,
        'category': product.category?.trim() ?? 'Umum',
        'price': product.price,
        'purchase_price': product.purchasePrice,
        'stock': product.stock,
        'minimum_stock': product.minimumStock,
        'user_id': currentUserId,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Produk berhasil ditambahkan',
          'product': data['data'] != null ? Product.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambahkan produk',
        };
      }
    } catch (e) {
      debugPrint('GudangService storeProduct error: $e');
      return {
        'success': false,
        'message': 'Koneksi ke server bermasalah: $e',
      };
    }
  }

  /// Memperbarui data produk yang ada
  Future<Map<String, dynamic>> updateProduct(Product product, {int? userId}) async {
    try {
      final currentUserId = userId ?? AuthService().currentUser?.id ?? 1;
      final uri = Uri.parse('$gudangBaseUrl/products/${product.id}');

      final payload = {
        'name': product.name.trim(),
        'barcode': (product.barcode != null && product.barcode!.trim().isNotEmpty)
            ? product.barcode!.trim()
            : null,
        'category': product.category?.trim() ?? 'Umum',
        'price': product.price,
        'purchase_price': product.purchasePrice,
        'stock': product.stock,
        'minimum_stock': product.minimumStock,
        'user_id': currentUserId,
      };

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Data produk berhasil diperbarui',
          'product': data['data'] != null ? Product.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memperbarui produk',
        };
      }
    } catch (e) {
      debugPrint('GudangService updateProduct error: $e');
      return {
        'success': false,
        'message': 'Koneksi ke server bermasalah: $e',
      };
    }
  }

  /// Menghapus produk dari katalog gudang secara aman
  Future<Map<String, dynamic>> deleteProduct(int productId, {int? userId}) async {
    try {
      final currentUserId = userId ?? AuthService().currentUser?.id ?? 1;
      final uri = Uri.parse('$gudangBaseUrl/products/$productId');

      final response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'user_id': currentUserId}),
      ).timeout(const Duration(seconds: 8));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Produk berhasil dihapus',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus produk',
        };
      }
    } catch (e) {
      debugPrint('GudangService deleteProduct error: $e');
      return {
        'success': false,
        'message': 'Koneksi ke server bermasalah: $e',
      };
    }
  }

  // ── MUTASI & STOK ─────────────────────────────────────────────

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
      final uri = Uri.parse('$gudangBaseUrl/categories');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          return data.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }

      // Fallback
      final fallbackUri = Uri.parse('$syncBaseUrl/categories');
      final fallbackRes = await http.get(fallbackUri).timeout(const Duration(seconds: 6));
      if (fallbackRes.statusCode == 200) {
        final dynamic data = json.decode(fallbackRes.body);
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

  /// Menghitung ringkasan inventaris untuk dashboard secara efisien
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final uri = Uri.parse('$gudangBaseUrl/dashboard');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final jsonResp = json.decode(response.body);
        if (jsonResp['success'] == true && jsonResp['data'] != null) {
          final data = jsonResp['data'];
          final recentRaw = data['recentMovements'] as List? ?? [];
          return {
            'totalProducts': data['totalProducts'] ?? 0,
            'lowStockCount': data['lowStockCount'] ?? 0,
            'outOfStockCount': data['outOfStockCount'] ?? 0,
            'totalValuation': data['totalValuation'] ?? 0,
            'todayMovements': data['todayMovements'] ?? 0,
            'recentMovements': recentRaw.map((e) => StockMovement.fromJson(e)).toList(),
          };
        }
      }

      return await _fallbackInventoryStats();
    } catch (e) {
      debugPrint('GudangService getInventoryStats error (falling back): $e');
      return await _fallbackInventoryStats();
    }
  }

  Future<Map<String, dynamic>> _fallbackInventoryStats() async {
    try {
      final productsFuture = _posService.getProducts();
      final movementsFuture = getStockMovements();
      final results = await Future.wait([productsFuture, movementsFuture]);

      final products = results[0] as List<Product>;
      final movements = results[1] as List<StockMovement>;

      int lowStockCount = 0;
      int outOfStockCount = 0;
      int totalValuation = 0;

      for (final p in products) {
        if (p.isOutOfStock) {
          outOfStockCount++;
        } else if (p.isLowStock) {
          lowStockCount++;
        }
        totalValuation += (p.stock * p.price);
      }

      final now = DateTime.now();
      final startOfDayMs = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final todayMovements = movements.where((m) => (m.createdAtEpochMs ?? 0) >= startOfDayMs).length;

      return {
        'totalProducts': products.length,
        'lowStockCount': lowStockCount,
        'outOfStockCount': outOfStockCount,
        'totalValuation': totalValuation,
        'todayMovements': todayMovements,
        'recentMovements': movements.take(6).toList(),
      };
    } catch (e) {
      debugPrint('GudangService _fallbackInventoryStats error: $e');
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
