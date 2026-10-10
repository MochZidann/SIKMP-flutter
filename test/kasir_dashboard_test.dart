import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kop/core/widgets/metric_card.dart';
import 'package:flutter_kop/pages/kasir_main_page.dart';
import 'package:flutter_kop/pages/tabs/dashboard_tab.dart';

void main() {
  group('Kasir Dashboard Card & Widget Tests', () {
    testWidgets('MetricCard renders title, value, icon, and subtitle badge correctly', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricCard(
              title: 'Total Omzet',
              value: 'Rp 150.000',
              icon: Icons.payments_rounded,
              color: const Color(0xFFD32F2F),
              subtitle: 'Hari Ini',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Total Omzet'), findsOneWidget);
      expect(find.text('Rp 150.000'), findsOneWidget);
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.byIcon(Icons.payments_rounded), findsOneWidget);

      await tester.tap(find.byType(MetricCard));
      expect(tapped, isTrue);
    });

    testWidgets('DashboardTab renders all 4 standardized metric cards and quick actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardTab(onNavigateTab: (_) {}),
        ),
      );

      // Verify header and section titles
      expect(find.text('Kasir'), findsOneWidget);
      expect(find.text('Ringkasan Penjualan Hari Ini'), findsOneWidget);
      expect(find.text('Aksi Kasir Cepat'), findsOneWidget);
      expect(find.text('Transaksi Terbaru'), findsOneWidget);

      // Verify the 4 metric cards exist
      expect(find.text('Total Omzet'), findsOneWidget);
      expect(find.text('Total Transaksi'), findsOneWidget);
      expect(find.text('Omzet QRIS'), findsOneWidget);
      expect(find.text('Omzet Tunai'), findsOneWidget);

      // Verify quick action buttons exist
      expect(find.text('Buka POS'), findsOneWidget);
      expect(find.text('Cek Produk'), findsOneWidget);
      expect(find.text('Penjualan'), findsOneWidget);
    });

    testWidgets('KasirMainPage renders unified bottom navigation with lowered Scan QR without text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KasirMainPage(),
        ),
      );

      // Verifikasi label tab utama ada
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('POS'), findsOneWidget);
      expect(find.text('Produk'), findsOneWidget);
      expect(find.text('Penjualan'), findsWidgets);

      // Verifikasi tombol Scan QR tidak menggunakan teks label
      expect(find.text('Scan QR'), findsNothing);

      // Verifikasi icon scan QR ada di dalam navigation bar
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsWidgets);

      // Pastikan tidak ada FloatingActionButton menonjol di Scaffold
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
