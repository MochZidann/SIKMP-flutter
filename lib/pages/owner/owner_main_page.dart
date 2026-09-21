import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login_page.dart';
import '../pos/widgets/pos_settings_dialog.dart';
import 'tabs/owner_dashboard_tab.dart';
import 'tabs/owner_inventory_tab.dart';
import 'tabs/owner_sales_tab.dart';

class OwnerMainPage extends StatefulWidget {
  final int initialIndex;

  const OwnerMainPage({super.key, this.initialIndex = 0});

  @override
  State<OwnerMainPage> createState() => _OwnerMainPageState();
}

class _OwnerMainPageState extends State<OwnerMainPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  String get _appBarTitle {
    switch (_currentIndex) {
      case 1:
        return 'Laporan Penjualan';
      case 2:
        return 'Kesehatan Stok';
      case 0:
      default:
        return 'Dashboard Owner';
    }
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
        content: const Text('Apakah Anda yakin ingin logout dari akun Owner / Pengawas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00796B)),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00796B),
        elevation: 0,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Color(0xFF00796B),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _appBarTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
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
          OwnerDashboardTab(onNavigateTab: _onTabTapped),
          const OwnerSalesTab(),
          const OwnerInventoryTab(),
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
            indicatorColor: const Color(0xFFE0F2F1),
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00796B),
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
                  color: Color(0xFF00796B),
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
                tooltip: 'Dashboard Owner',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics_rounded),
                label: 'Penjualan',
                tooltip: 'Laporan Penjualan & Kasir',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded),
                label: 'Kesehatan Stok',
                tooltip: 'Valuasi Aset & Stok Kritis',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
