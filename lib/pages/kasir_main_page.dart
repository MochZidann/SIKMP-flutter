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
            height: 68,
            child: Row(
              children: [
                // 1. Dashboard
                _buildNavItem(
                  index: 0,
                  assetPath: 'assets/images/dashboard.png',
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  iconSize: 24,
                ),
                // 2. POS
                _buildNavItem(
                  index: 1,
                  assetPath: 'assets/images/pos.png',
                  icon: Icons.point_of_sale_outlined,
                  selectedIcon: Icons.point_of_sale_rounded,
                  label: 'POS',
                  iconSize: 28,
                ),

                // 3. Tombol Scan QR (Di tengah, rata bawah, tanpa teks, style gradasi bulat seperti semula)
                Expanded(
                  child: Center(
                    child: Tooltip(
                      message: 'Scan Barcode Kamera',
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC62828).withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 3.0,
                          ),
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
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Produk
                _buildNavItem(
                  index: 2,
                  icon: Icons.inventory_2_outlined,
                  selectedIcon: Icons.inventory_2_rounded,
                  label: 'Produk',
                  iconSize: 24,
                ),
                // 5. Penjualan
                _buildNavItem(
                  index: 3,
                  assetPath: 'assets/images/penjualan.png',
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long_rounded,
                  label: 'Penjualan',
                  iconSize: 24,
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
