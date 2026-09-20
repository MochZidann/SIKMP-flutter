import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login_page.dart';
import '../pos/widgets/pos_settings_dialog.dart';
import 'tabs/admin_audit_tab.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/admin_members_tab.dart';
import 'tabs/admin_users_tab.dart';

class AdminMainPage extends StatefulWidget {
  final int initialIndex;

  const AdminMainPage({super.key, this.initialIndex = 0});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
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
        content: const Text('Apakah Anda yakin ingin logout dari akun Admin Sistem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
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
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
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
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF1976D2),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Sistem',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  user != null ? 'Operator: ${user.name}' : 'Panel Kontrol Koperasi',
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
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
          AdminDashboardTab(onNavigateTab: _onTabTapped),
          const AdminUsersTab(),
          const AdminMembersTab(),
          const AdminAuditTab(),
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
            indicatorColor: const Color(0xFFE3F2FD),
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
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
                  color: Color(0xFF1976D2),
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
                tooltip: 'Dashboard Admin Sistem',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'Pengguna',
                tooltip: 'Kelola Akun Pengguna',
              ),
              NavigationDestination(
                icon: Icon(Icons.card_membership_outlined),
                selectedIcon: Icon(Icons.card_membership_rounded),
                label: 'Anggota',
                tooltip: 'Data Anggota Koperasi',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_edu_outlined),
                selectedIcon: Icon(Icons.history_edu_rounded),
                label: 'Audit Log',
                tooltip: 'Log Aktivitas Sistem',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
