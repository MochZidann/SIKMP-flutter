import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_kop/core/services/api_http.dart' as api;
import 'package:flutter_kop/models/product.dart';
import 'package:flutter_kop/services/gudang_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api.accessToken = 'test-token';
    api.actorIdentity = '1';
  });
  tearDown(() { api.client.close(); api.accessToken = null; });

  test('product edit sends token but never sends a stale stock balance', () async {
    api.client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(request.headers['Idempotency-Key'], isNotEmpty);
      final payload = jsonDecode(request.body) as Map;
      expect(payload.containsKey('stock'), isFalse);
      return http.Response(jsonEncode({'success': true, 'data': {'id': 1, 'name': 'Baru', 'price': 10000, 'stock': 8}}), 200);
    });
    final result = await GudangService().updateProduct(Product(id: 1, name: 'Baru', price: 10000, stock: 10));
    expect(result['success'], isTrue);
    expect((result['product'] as Product).stock, 8);
  });

  test('uncertain request retry reuses key, next confirmed operation gets a new key', () async {
    final keys = <String>[];
    api.client = MockClient((request) async {
      keys.add(request.headers['Idempotency-Key']!);
      if (keys.length == 1) throw http.ClientException('Connection lost after commit');
      return http.Response('{}', 200);
    });
    final url = Uri.parse('http://localhost/api/gudang/products/1/stock-out');
    await expectLater(api.post(url, body: '{"quantity":2}'), throwsA(isA<http.ClientException>()));
    api.accessToken = 'renewed-token';
    await api.post(url, body: '{"quantity":2}');
    await api.post(url, body: '{"quantity":2}');
    expect(keys[0], keys[1]);
    expect(keys[2], isNot(keys[1]));
  });

  test('double tap shares one in-flight mutation', () async {
    var calls = 0;
    final gate = Completer<void>();
    api.client = MockClient((request) async {
      calls++;
      await gate.future;
      return http.Response('{}', 200);
    });
    final url = Uri.parse('http://localhost/api/pos/checkout');
    final a = api.post(url, body: '{"amount":1000}');
    final b = api.post(url, body: '{"amount":1000}');
    gate.complete();
    await Future.wait([a, b]);
    expect(calls, 1);
  });

  test('history follows cursor pages and reports load failures', () async {
    var calls = 0;
    api.client = MockClient((request) async {
      calls++;
      expect(request.url.queryParameters['after_id'], calls == 1 ? '0' : '1');
      return http.Response(jsonEncode({'data': [{'id': calls, 'productId': 1, 'type': 'IN', 'quantityDelta': 1}], 'next_cursor': calls, 'has_more': calls == 1}), 200);
    });
    final movements = await GudangService().getStockMovements();
    expect(movements.map((m) => m.id), [2, 1]);
    api.client = MockClient((request) async => http.Response('{}', 503));
    await expectLater(GudangService().getStockMovements(), throwsException);
  });

  test('stock opname sends the stock snapshot used to open the form', () async {
    api.client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map;
      expect(body['expected_stock'], 10);
      expect(body['new_stock'], 9);
      return http.Response('{"success":false,"message":"Stok berubah"}', 422);
    });
    final result = await GudangService().adjustStock(product: Product(id: 1, name: 'Uji', price: 10000, stock: 10), newStock: 9, note: 'Hitung fisik');
    expect(result['success'], isFalse);
  });
}
