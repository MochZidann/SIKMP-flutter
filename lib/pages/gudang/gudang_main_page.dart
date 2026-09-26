import 'package:flutter/material.dart';
import '../../core/widgets/app_top_bar_title.dart';
import '../../services/auth_service.dart';
import '../login_page.dart';
import '../pos/widgets/pos_settings_dialog.dart';
import 'tabs/gudang_category_tab.dart';
import 'tabs/gudang_dashboard_tab.dart';
import 'tabs/gudang_inbound_tab.dart';
import 'tabs/gudang_stock_tab.dart';

class GudangMainPage extends StatefulWidget {
  final int initialIndex;

  const GudangMainPage({super.key, this.initialIndex = 0});

  @override
  State<GudangMainPage> createState() => _GudangMainPageState();
}

class _GudangMainPageState extends State<GudangMainPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Apakah Anda yakin ingin logout dari akun Admin Gudang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Ya, Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const AppTopBarTitle(roleName: 'Admin Gudang'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan API Server',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              PosSettingsDialog.show(context, onSaved: () => setState(() {}));
            },
          ),
          IconButton(
            tooltip: 'Keluar / Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          GudangDashboardTab(onNavigateTab: _onTabTapped),
          const GudangStockTab(),
          const GudangInboundTab(),
          const GudangCategoryTab(),
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
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 68,
            backgroundColor: Colors.white,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
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
                  color: Color(0xFFE65100),
                  size: 24,
                );
              }
              return IconThemeData(
                color: Colors.grey.shade600,
                size: 24,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            animationDuration: const Duration(milliseconds: 300),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
                tooltip: 'Dashboard Gudang',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded),
                label: 'Stok Barang',
                tooltip: 'Katalog Stok & Opname',
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_vert_outlined),
                selectedIcon: Icon(Icons.swap_vert_rounded),
                label: 'Barang Masuk',
                tooltip: 'Riwayat Mutasi Stok',
              ),
              NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category_rounded),
                label: 'Kategori',
                tooltip: 'Daftar Kategori Produk',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
