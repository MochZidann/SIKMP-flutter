import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/widgets/barcode_scanner_sheet.dart';
import 'pos/pos_page.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/penjualan_tab.dart';
import 'tabs/produk_tab.dart';
import 'tabs/retur_tab.dart';

class KasirMainPage extends StatefulWidget {
  final int initialIndex;

  const KasirMainPage({super.key, this.initialIndex = 0});

  @override
  State<KasirMainPage> createState() => _KasirMainPageState();
}

class _KasirMainPageState extends State<KasirMainPage> {
  late int _currentIndex;
  final GlobalKey<DashboardTabState> _dashboardKey = GlobalKey<DashboardTabState>();
  final GlobalKey<PosPageState> _posKey = GlobalKey<PosPageState>();
  final GlobalKey<ProdukTabState> _produkKey = GlobalKey<ProdukTabState>();
  final GlobalKey<PenjualanTabState> _penjualanKey = GlobalKey<PenjualanTabState>();
  final GlobalKey<ReturTabState> _returKey = GlobalKey<ReturTabState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  /// Sinkronkan seluruh tab kasir saat barang berhasil terjual di POS
  void _onSaleCompleted() {
    _dashboardKey.currentState?.reload();
    _produkKey.currentState?.reload();
    _penjualanKey.currentState?.reload();
    _returKey.currentState?.reload();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  /// Aksi Scan Barcode Kamera Kasir (Mode Beruntun / Banyak Barang)
  Future<void> _openBarcodeScanner() async {
    HapticFeedback.mediumImpact();

    // Otomatis arahkan ke tab POS (index 1) agar kasir langsung melihat ringkasan item & struk
    if (_currentIndex != 1) {
      setState(() {
        _currentIndex = 1;
      });
    }

    // Buka scanner dengan mode continuous (kamera tetap menyala untuk banyak barang)
    await BarcodeScannerSheet.show(
      context,
      title: 'Scan Produk Kasir',
      isContinuous: true,
      onScanned: (scannedCode) async {
        final product = await _posKey.currentState?.addProductByBarcode(scannedCode);
        if (product != null) {
          return '+1 ${product.name} (Rp ${product.price})';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardTab(key: _dashboardKey, onNavigateTab: _onTabTapped),
          PosPage(
            key: _posKey,
            isEmbedded: true,
            onSaleCompleted: _onSaleCompleted,
          ),
          ProdukTab(
            key: _produkKey,
            onAddToCart: (product) {
              _posKey.currentState?.addToCart(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} dimasukkan ke keranjang POS'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          PenjualanTab(key: _penjualanKey),
          ReturTab(key: _returKey),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              tooltip: 'Scan Barcode Produk Kasir',
              onPressed: _openBarcodeScanner,
              child: const Icon(Icons.qr_code_scanner_rounded, size: 24),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 64,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFD32F2F).withValues(alpha: 0.12),
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F),
                );
              }
              return TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(
                  color: Color(0xFFD32F2F),
                  size: 22,
                );
              }
              return IconThemeData(
                color: Colors.grey.shade600,
                size: 22,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale_rounded),
                label: 'POS',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded),
                label: 'Produk',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Penjualan',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_return_outlined),
                selectedIcon: Icon(Icons.assignment_return_rounded),
                label: 'Retur',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
