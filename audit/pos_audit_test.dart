import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_kop/core/services/api_http.dart' as api;
import 'package:flutter_kop/core/config/api_config.dart';
import 'package:flutter_kop/services/pos_service.dart';
import 'package:flutter_kop/pages/pos/widgets/cash_payment_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uri requested;
  setUp(() {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    api.actorIdentity = 'audit'; api.accessToken = 'test';
    api.client = MockClient((r) async {
      requested = r.url;
      return http.Response(jsonEncode({'success':true,'data':{},'status':'pending','paid':false}),200);
    });
  });
  tearDown(() { api.client.close(); api.accessToken = null; });
  test('products must use configured server URL', () async {
    await PosService().getProducts();
    expect(requested.toString(), '${ApiConfig.posUrl}/products');
  });
  test('checkout must use configured server URL', () async {
    await PosService().checkoutTunai(amount:10000,amountPaid:10000);
    expect(requested.toString(), '${ApiConfig.posUrl}/checkout');
  });
  test('QRIS polling must include server and order ID', () async {
    await PosService().checkQrisStatus('ORDER-AUDIT');
    expect(requested.toString(), '${ApiConfig.posUrl}/qris/check-status/ORDER-AUDIT');
  });
  test('QRIS cancel must include server and order ID', () async {
    await PosService().cancelQris('ORDER-AUDIT');
    expect(requested.toString(), '${ApiConfig.posUrl}/qris/cancel/ORDER-AUDIT');
  });
  testWidgets('cash receipt uses server total after discount', (tester) async {

    await tester.binding.setSurfaceSize(const Size(800,1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Map<String,dynamic>? receipt;
    api.client = MockClient((r) async => http.Response(jsonEncode({'success':true,'data':{'transactionId':'AUDIT','total':9000,'amountPaid':10000,'change':1000,'items':[]}}),200));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder:(context) => TextButton(onPressed:() {
      CashPaymentBottomSheet.show(context,finalAmount:10000,itemsPayload:[{'productId':1,'qty':1}],onSuccess:(data)=>receipt=data,onError:(message)=>fail(message));
    },child:const Text('Buka'))))));
    await tester.tap(find.text('Buka')); await tester.pumpAndSettle();
    await tester.tap(find.text('Konfirmasi Pembayaran Cash')); await tester.pumpAndSettle();
    expect(receipt?['total'],9000);
    expect(receipt?['change'],1000);
  });
}

