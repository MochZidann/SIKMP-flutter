import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_kop/core/services/api_http.dart' as api;
import 'package:flutter_kop/services/return_service.dart';
import 'package:flutter_kop/pages/gudang/purchase_return_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api.accessToken = 'warehouse';
    api.actorIdentity = '2';
  });
  tearDown(() {
    api.client.close();
    api.accessToken = null;
  });

  test(
    'supplier return uses authenticated business endpoint and document links',
    () async {
      api.client = MockClient((r) async {
        expect(r.url.path, '/api/returns/purchases');
        expect(r.headers['Authorization'], 'Bearer warehouse');
        expect(r.headers['Idempotency-Key'], isNotEmpty);
        final body = jsonDecode(r.body) as Map;
        expect(body['supplier_id'], 3);
        expect(body['goods_receipt_id'], 8);
        expect(body['items'][0]['product_batch_id'], 4);
        return http.Response(
          '{"success":true,"data":{"return_no":"PR-1"}}',
          201,
        );
      });
      final result = await ReturnService().createPurchaseReturn(
        supplierId: 3,
        goodsReceiptId: 8,
        items: [
          {'product_batch_id': 4, 'quantity': 1},
        ],
        reason: 'Rusak',
      );
      expect(result['success'], isTrue);
    },
  );

  test(
    'receipt search preserves pagination and surfaces server failure',
    () async {
      api.client = MockClient((r) async {
        expect(r.url.queryParameters, {'search': 'RC-8', 'page': '2'});
        return http.Response('{"data":[],"pagination":{"last_page":2}}', 200);
      });
      final data = await ReturnService().getPurchaseReceipts(
        search: 'RC-8',
        page: 2,
      );
      expect(data['pagination']['last_page'], 2);
      api.client = MockClient((r) async => http.Response('{}', 503));
      await expectLater(ReturnService().getPurchaseReceipts(), throwsException);
    },
  );

  testWidgets('warehouse selects receipt and sends a purchase return', (
    tester,
  ) async {
    Map? posted;
    api.client = MockClient((r) async {
      if (r.method == 'POST') {
        posted = jsonDecode(r.body) as Map;
        return http.Response(
          '{"success":true,"message":"Retur tersimpan"}',
          201,
        );
      }
      if (r.url.path.endsWith('/receipts')) {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 8,
                'receipt_no': 'RC-8',
                'supplier_name_snapshot': 'Supplier Uji',
              },
            ],
            'pagination': {'last_page': 1},
          }),
          200,
        );
      }
      if (r.url.path.contains('/summary/')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'receipt': {
                'id': 8,
                'receipt_no': 'RC-8',
                'supplier_id': 3,
                'supplier_name': 'Supplier Uji',
              },
              'items': [
                {
                  'batch_id': 4,
                  'goods_receipt_item_id': 9,
                  'product_name': 'Susu',
                  'batch_no': 'B-4',
                  'quantity_returnable': 2,
                  'purchase_price': 5000,
                },
              ],
              'is_returnable': true,
            },
          }),
          200,
        );
      }
      return http.Response('{"data":[]}', 200);
    });
    await tester.pumpWidget(const MaterialApp(home: PurchaseReturnPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RC-8'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Kemasan rusak');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Proses retur ke supplier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proses retur ke supplier'));
    await tester.pumpAndSettle();
    expect(posted?['supplier_id'], 3);
    expect(posted?['goods_receipt_id'], 8);
    expect(posted?['items'][0]['quantity'], 1);
  });
}
