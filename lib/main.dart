import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const KopdesApp());
}

class KopdesApp extends StatelessWidget {
  const KopdesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kopdes Merah Putih',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          primary: const Color(0xFFD32F2F),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// -------------------------------------------------------------
// SPLASH SCREEN DENGAN ANIMASI FADE & SCALE
// -------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Controller untuk durasi animasi (1.5 detik)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 2. Animasi Membesar (Scale dari 0.6x ke 1.0x dengan kurva membal halus)
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    // 3. Animasi Muncul Halus (Fade In dari transparan ke pekat)
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Mulai animasi
    _controller.forward();

    // 4. Timer 3 detik sebelum otomatis pindah ke Dashboard
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const DashboardKopdesPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD32F2F), Color(0xFF8E0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo & Judul dengan Animasi Fade & Scale
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // Lingkaran Putih Logo
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFFD32F2F),
                          size: 72,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Teks Brand
                      const Text(
                        'KOPDES',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const Text(
                        'MERAH PUTIH',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Membangun Ekonomi Desa Mandiri',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Loading Indikator & Footer Versi
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Versi 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// DASHBOARD KOPDES MERAH PUTIH
// -------------------------------------------------------------
class DashboardKopdesPage extends StatelessWidget {
  const DashboardKopdesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 0,
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
                color: Color(0xFFD32F2F),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Kopdes Merah Putih',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Desa Maju Makmur',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Kartu Profil & Saldo Anggota
            _buildMemberCard(),
            const SizedBox(height: 24),

            // 2. Menu Cepat / Layanan Koperasi
            const Text(
              'Layanan Utama',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuGrid(context),
            const SizedBox(height: 24),

            // 3. Ringkasan Aktivitas Terkini
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aktivitas Terakhir',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(color: Color(0xFFD32F2F), fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRecentActivityList(),
          ],
        ),
      ),
    );
  }

  // Widget Kartu Saldo / Anggota
  Widget _buildMemberCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Halo, Bpk. Sugeng Waluyo',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ID: KOP-0482',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Total Simpanan Anggota',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            'Rp 4.750.000',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Simpanan Wajib',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        'Rp 1.200.000',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sisa Pinjaman',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        'Rp 500.000',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Grid Menu Layanan
  Widget _buildMenuGrid(BuildContext context) {
    final List<Map<String, dynamic>> menus = [
      {'icon': Icons.savings_outlined, 'title': 'Simpanan', 'color': Colors.blue},
      {'icon': Icons.handshake_outlined, 'title': 'Pinjaman', 'color': Colors.orange},
      {'icon': Icons.shopping_basket_outlined, 'title': 'Toko Desa', 'color': Colors.green},
      {'icon': Icons.receipt_long_outlined, 'title': 'Tagihan PPOB', 'color': Colors.purple},
      {'icon': Icons.history_rounded, 'title': 'Riwayat', 'color': Colors.teal},
      {'icon': Icons.help_outline_rounded, 'title': 'Bantuan', 'color': Colors.indigo},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menus.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final item = menus[index];
        return InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Menu ${item['title']} ditekan')),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: (item['color'] as Color).withValues(alpha: 0.12),
                  child: Icon(item['icon'] as IconData, color: item['color'] as Color),
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget Daftar Riwayat Singkat
  Widget _buildRecentActivityList() {
    final List<Map<String, dynamic>> activities = [
      {
        'title': 'Setor Simpanan Sukarela',
        'date': '15 Sep 2026, 14:30',
        'amount': '+Rp 100.000',
        'isPlus': true,
      },
      {
        'title': 'Pembayaran Angsuran Pinjaman',
        'date': '10 Sep 2026, 09:15',
        'amount': '-Rp 250.000',
        'isPlus': false,
      },
      {
        'title': 'Belanja di Toko Desa',
        'date': '04 Sep 2026, 16:45',
        'amount': '-Rp 75.000',
        'isPlus': false,
      },
    ];

    return Column(
      children: activities.map((act) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: act['isPlus']
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: Icon(
                act['isPlus'] ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: act['isPlus'] ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              act['title'],
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              act['date'],
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            trailing: Text(
              act['amount'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: act['isPlus'] ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
