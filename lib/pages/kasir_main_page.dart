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

    // Otomatis sinkronkan data saat kasir berpindah tab agar selalu mutakhir
    switch (index) {
      case 0:
        _dashboardKey.currentState?.reload();
        break;
      case 1:
        _posKey.currentState?.reloadProducts();
        break;
      case 2:
        _produkKey.currentState?.reload();
        break;
      case 3:
        _penjualanKey.currentState?.reload();
        break;
      case 4:
        _returKey.currentState?.reload();
        break;
    }
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
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                // 1. Dashboard
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  iconSize: 22,
                ),
                // 2. POS
                _buildNavItem(
                  index: 1,
                  icon: Icons.point_of_sale_outlined,
                  selectedIcon: Icons.point_of_sale_rounded,
                  label: 'POS',
                  iconSize: 22,
                ),
                // 3. Produk
                _buildNavItem(
                  index: 2,
                  icon: Icons.inventory_2_outlined,
                  selectedIcon: Icons.inventory_2_rounded,
                  label: 'Produk',
                  iconSize: 22,
                ),
                // 4. Penjualan
                _buildNavItem(
                  index: 3,
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long_rounded,
                  label: 'Penjualan',
                  iconSize: 22,
                ),
                // 5. Retur
                _buildNavItem(
                  index: 4,
                  icon: Icons.assignment_return_outlined,
                  selectedIcon: Icons.assignment_return_rounded,
                  label: 'Retur',
                  iconSize: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    String? assetPath,
    IconData? icon,
    IconData? selectedIcon,
    required String label,
    double iconSize = 24.0,
  }) {
    final isSelected = _currentIndex == index;
    const primaryColor = Color(0xFFD32F2F);
    final unselectedColor = Colors.grey.shade600;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: primaryColor.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 28,
              child: Center(
                child: assetPath != null
                    ? Image.asset(
                        assetPath,
                        width: iconSize,
                        height: iconSize,
                        color: isSelected ? primaryColor : unselectedColor,
                        colorBlendMode: BlendMode.srcIn,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          isSelected ? (selectedIcon ?? icon ?? Icons.circle) : (icon ?? Icons.circle),
                          color: isSelected ? primaryColor : unselectedColor,
                          size: 24,
                        ),
                      )
                    : Icon(
                        isSelected ? (selectedIcon ?? icon) : icon,
                        color: isSelected ? primaryColor : unselectedColor,
                        size: iconSize,
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
