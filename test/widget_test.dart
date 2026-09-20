import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kop/main.dart';

void main() {
  testWidgets('App starts with KopdesApp and renders splash branding', (WidgetTester tester) async {
    await tester.pumpWidget(const KopdesApp());
    expect(find.text('KOPDES'), findsOneWidget);
    expect(find.text('MERAH PUTIH'), findsOneWidget);
    // Jalankan timer splash hingga selesai
    await tester.pump(const Duration(seconds: 4));
  });
}
