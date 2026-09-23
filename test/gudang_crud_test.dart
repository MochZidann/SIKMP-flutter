import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kop/core/widgets/barcode_scanner_sheet.dart';
import 'package:flutter_kop/models/product.dart';
import 'package:flutter_kop/services/gudang_service.dart';

void main() {
  group('Admin Gudang CRUD & Security Unit Tests', () {
    test('Product model parses purchasePrice, minimumStock, and converts to JSON', () {
      final json = {
        'id': 101,
        'name': 'Kopi Robusta 250g',
        'barcode': '8991234567890',
        'category': 'Minuman',
        'price': 25000,
        'purchase_price': 18000,
        'stock': 40,
        'minimum_stock': 10,
        'image_path': 'products/kopi.jpg',
      };

      final product = Product.fromJson(json);

      expect(product.id, 101);
      expect(product.name, 'Kopi Robusta 250g');
      expect(product.barcode, '8991234567890');
      expect(product.category, 'Minuman');
      expect(product.price, 25000);
      expect(product.purchasePrice, 18000);
      expect(product.stock, 40);
      expect(product.minimumStock, 10);
      expect(product.imagePath, 'products/kopi.jpg');

      final exportedJson = product.toJson();
      expect(exportedJson['name'], 'Kopi Robusta 250g');
      expect(exportedJson['purchasePrice'], 18000);
      expect(exportedJson['minimumStock'], 10);
    });

    test('Product copyWith updates fields without mutating originals', () {
      final original = Product(
        id: 1,
        name: 'Gula Pasir 1kg',
        barcode: '8991111111111',
        category: 'Sembako',
        price: 15000,
        stock: 50,
        purchasePrice: 12000,
        minimumStock: 5,
      );

      final updated = original.copyWith(
        name: 'Gula Pasir Kristal 1kg',
        price: 16000,
        stock: 45,
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Gula Pasir Kristal 1kg');
      expect(updated.price, 16000);
      expect(updated.stock, 45);
      expect(updated.barcode, original.barcode);
      expect(updated.purchasePrice, 12000);
    });

    test('GudangService generates correct gudangBaseUrl and syncBaseUrl', () {
      final service = GudangService();
      expect(service.gudangBaseUrl.endsWith('/gudang'), isTrue);
      expect(service.syncBaseUrl.endsWith('/sync'), isTrue);
    });

    test('Barcode sanitization protects against malformed and malicious input', () {
      // Valid barcodes
      expect(BarcodeScannerSheet.sanitizeBarcode('8992753123456'), '8992753123456');
      expect(BarcodeScannerSheet.sanitizeBarcode('ITEM-001'), 'ITEM-001');

      // Invalid / Dangerous payloads
      expect(BarcodeScannerSheet.sanitizeBarcode("'; DROP TABLE products; --"), isNull);
      expect(BarcodeScannerSheet.sanitizeBarcode('<script>alert(1)</script>'), isNull);
      expect(BarcodeScannerSheet.sanitizeBarcode('12'), isNull); // Too short (<3)
      expect(BarcodeScannerSheet.sanitizeBarcode(''), isNull);
      expect(BarcodeScannerSheet.sanitizeBarcode(null), isNull);
    });

    test('Critical stock logic defines critical as strictly less than 5 (stock > 0 && stock < 5)', () {
      final pLow4 = Product(id: 1, name: 'A', price: 1000, stock: 4);
      final pLow1 = Product(id: 2, name: 'B', price: 1000, stock: 1);
      final pSafe5 = Product(id: 3, name: 'C', price: 1000, stock: 5);
      final pSafe10 = Product(id: 4, name: 'D', price: 1000, stock: 10);
      final pOut0 = Product(id: 5, name: 'E', price: 1000, stock: 0);

      // Low stock / Kritis: stock 1..4 (< 5)
      expect(pLow4.isLowStock, isTrue);
      expect(pLow1.isLowStock, isTrue);
      expect(pLow4.isOutOfStock, isFalse);

      // Safe / Aman: stock >= 5
      expect(pSafe5.isLowStock, isFalse);
      expect(pSafe10.isLowStock, isFalse);

      // Habis / Out of stock: stock <= 0
      expect(pOut0.isLowStock, isFalse);
      expect(pOut0.isOutOfStock, isTrue);

      // Default minimumStock is 5
      expect(pLow4.minimumStock, 5);
    });
  });
}
