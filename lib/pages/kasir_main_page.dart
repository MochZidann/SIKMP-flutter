import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/widgets/barcode_scanner_sheet.dart';
import 'pos/pos_page.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/penjualan_tab.dart';
import 'tabs/produk_tab.dart';

class KasirMainPage extends StatefulWidget {
  final int initialIndex;

  const KasirMainPage({super.key, this.initialIndex = 0});

  @override
  State<KasirMainPage> createState() => _KasirMainPageState();
}

class _KasirMainPageState extends State<KasirMainPage> {
  late int _currentIndex;
  final GlobalKey<PosPageState> _posKey = GlobalKey<PosPageState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  /// Aksi Scan Barcode Kamera Kasir
  Future<void> _openBarcodeScanner() async {
    HapticFeedback.mediumImpact();

    final scannedCode = await BarcodeScannerSheet.show(
      context,
      title: 'Scan Barcode Produk Kasir',
    );

    if (scannedCode == null || !mounted) return;

    // Otomatis arahkan ke tab POS (index 1) agar kasir langsung melihat ringkasan item & struk
    if (_currentIndex != 1) {
      setState(() {
        _currentIndex = 1;
      });
    }

    // Masukkan produk hasil scan ke transaksi POS kasir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _posKey.currentState?.addProductByBarcode(scannedCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    const double barHeight = 66.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardTab(onNavigateTab: _onTabTapped),
          PosPage(key: _posKey, isEmbedded: true),
          ProdukTab(
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
          const PenjualanTab(),
        ],
      ),

      // ── TOMBOL SCAN BARCODE DI TENGAH (MENONJOL KE ATAS) ───────────
      floatingActionButton: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF5350), Color(0xFFC62828)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC62828).withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _openBarcodeScanner,
            splashColor: Colors.white.withValues(alpha: 0.3),
            child: const Center(
              child: Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── BOTTOM NAVIGATION BAR DENGAN 4 TAB & GAP DI TENGAH ──────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: barHeight,
            child: Row(
              children: [
                // 1. Dashboard
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                ),
                // 2. POS
                _buildNavItem(
                  index: 1,
                  icon: Icons.point_of_sale_outlined,
                  selectedIcon: Icons.point_of_sale_rounded,
                  label: 'POS',
                ),

                // ── Slot Tengah Khusus untuk Tombol Scan yang Menonjol ──
                Expanded(
                  child: InkWell(
                    onTap: _openBarcodeScanner,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          'Scan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC62828),
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // 3. Produk
                _buildNavItem(
                  index: 2,
                  icon: Icons.inventory_2_outlined,
                  selectedIcon: Icons.inventory_2_rounded,
                  label: 'Produk',
                ),
                // 4. Penjualan
                _buildNavItem(
                  index: 3,
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long_rounded,
                  label: 'Penjualan',
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
    required IconData icon,
    required IconData selectedIcon,
    required String label,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? primaryColor : unselectedColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
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
