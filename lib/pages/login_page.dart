import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../services/pos_service.dart';
import 'admin/admin_main_page.dart';
import 'gudang/gudang_main_page.dart';
import 'kasir_main_page.dart';
import 'owner/owner_main_page.dart';
import 'qris_payment_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  final TextEditingController _usernameController =
      TextEditingController(text: 'kasir');
  final TextEditingController _passwordController =
      TextEditingController(text: '123456');

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Role yang didukung sistem
  final List<Map<String, dynamic>> _roles = [
    {
      'role': 'KASIR',
      'title': 'Kasir',
      'subtitle': 'Transaksi & POS',
      'icon': Icons.point_of_sale_rounded,
      'color': const Color(0xFFD32F2F),
      'isReady': true,
      'defaultUser': 'kasir',
    },
    {
      'role': 'ADMIN_SISTEM',
      'title': 'Admin',
      'subtitle': 'Kelola Master Data',
      'icon': Icons.admin_panel_settings_rounded,
      'color': const Color(0xFF1976D2),
      'isReady': true,
      'defaultUser': 'admin',
    },
    {
      'role': 'ADMIN_GUDANG',
      'title': 'Gudang',
      'subtitle': 'Stok & Produk',
      'icon': Icons.warehouse_rounded,
      'color': const Color(0xFFE65100),
      'isReady': true,
      'defaultUser': 'gudang',
    },
    {
      'role': 'OWNER_PENGAWAS',
      'title': 'Owner',
      'subtitle': 'Laporan & Audit',
      'icon': Icons.pie_chart_rounded,
      'color': const Color(0xFF00796B),
      'isReady': true,
      'defaultUser': 'owner',
    },
  ];

  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = 'KASIR'; // Default ke Kasir sesuai instruksi
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleSelected(Map<String, dynamic> item) {
    setState(() {
      _selectedRole = item['role'];
      _usernameController.text = item['defaultUser'];
      _passwordController.text = '123456';
    });
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackbar('Username dan password tidak boleh kosong.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
        username: username,
        password: password,
        role: _selectedRole,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user.isKasir) {
        // Alur KASIR: Langsung masuk ke Dashboard / POS
        _showSnackbar('Selamat datang, Kasir ${user.name}!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const KasirMainPage()),
        );
      } else if (user.isAdmin) {
        // Alur ADMIN SISTEM: Masuk ke Admin Dashboard
        _showSnackbar('Selamat datang, Admin ${user.name}!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminMainPage()),
        );
      } else if (user.isGudang) {
        // Alur ADMIN GUDANG: Masuk ke Gudang Dashboard
        _showSnackbar('Selamat datang, Petugas Gudang ${user.name}!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GudangMainPage()),
        );
      } else if (user.isOwner) {
        // Alur OWNER / PENGAWAS: Masuk ke Owner Dashboard
        _showSnackbar('Selamat datang, Pengawas ${user.name}!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OwnerMainPage()),
        );
      } else {
        // Alur Role Lainnya (Jika ada)
        _showOtherRoleDialog(user);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackbar(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  void _showOtherRoleDialog(AuthUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Info Hak Akses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, ${user.name}!'),
            const SizedBox(height: 6),
            Text(
              'Anda berhasil login dengan hak akses ${user.roleLabel}.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Text(
                'Saat ini aplikasi mobile difokuskan penuh untuk modul KASIR (POS & QRIS). Modul Admin & Gudang dapat diakses lewat Web Dashboard.',
                style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QrisPaymentPage()),
              );
            },
            child: const Text('Buka Kasir QRIS'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSettingsDialog() {
    final urlCtrl = TextEditingController(text: PosService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengaturan Alamat API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Base URL API Backend:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                hintText: 'http://10.0.2.2:8000/api/pos',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              PosService.baseUrl = urlCtrl.text.trim();
              Navigator.pop(ctx);
              _showSnackbar('Alamat API berhasil disimpan.');
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HEADER MERAH PUTIH ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 36, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFF8E0000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  // Action Bar (Settings API)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                      onPressed: _showSettingsDialog,
                      tooltip: 'Pengaturan IP Backend',
                    ),
                  ),

                  // Logo Koperasi
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFFD32F2F),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'KOPDES MERAH PUTIH',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sistem Informasi Koperasi Desa',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── KONTEN FORM LOGIN ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. PILIH ROLE
                  const Text(
                    'Pilih Hak Akses / Role',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Grid / Chips 4 Role
                  Row(
                    children: _roles.map((item) {
                      final isSelected = _selectedRole == item['role'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onRoleSelected(item),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (item['color'] as Color).withValues(alpha: 0.12)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? (item['color'] as Color)
                                    : Colors.grey.shade200,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (item['color'] as Color).withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isSelected
                                      ? (item['color'] as Color)
                                      : Colors.grey.shade100,
                                  child: Icon(
                                    item['icon'] as IconData,
                                    size: 18,
                                    color: isSelected ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? (item['color'] as Color)
                                        : const Color(0xFF555555),
                                  ),
                                ),
                                if (item['isReady'] == true)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'AKTIF',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 2. KARTU INPUT FORM
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Form
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Silakan Masuk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B2B2B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Role: $_selectedRole',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Input Username
                        const Text(
                          'Username',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan username',
                            prefixIcon: const Icon(Icons.person_outline_rounded,
                                color: Color(0xFFD32F2F), size: 20),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Input Password
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Masukkan password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: Color(0xFFD32F2F), size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tombol Masuk
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Masuk sebagai ${_selectedRole == 'KASIR' ? 'Kasir' : _selectedRole}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Info Akun Demo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.key_rounded, size: 18, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Password default semua akun: 123456\nUsername: kasir | admin | gudang | owner',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
