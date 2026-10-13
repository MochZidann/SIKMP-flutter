import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/app_skeleton.dart';
import '../../core/widgets/app_top_bar_title.dart';
import '../../core/widgets/header_curve_clipper.dart';
import '../../models/sale_record.dart';
import '../../services/auth_service.dart';
import '../../services/pos_service.dart';
import '../login_page.dart';
import '../pos/widgets/pos_closing_sheet.dart';

class DashboardTab extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardTab({super.key, required this.onNavigateTab});

  @override
  DashboardTabState createState() => DashboardTabState();
}

class DashboardTabState extends State<DashboardTab> {
  final PosService _posService = PosService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<SaleRecord> _recentSales = [];

  /// Memuat ulang statistik dashboard kasir dari server
  Future<void> reload() async {
    await _loadDashboardData();
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final user = AuthService().currentUser;
    final result = await _posService.getSales(
      cashierId: user?.id,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    if (mounted) {
      final rawStats = result['stats'] as Map? ?? {};
      final statsMap = rawStats.map((k, v) => MapEntry(k.toString(), v));
      final allSales = (result['sales'] as List? ?? []).cast<SaleRecord>();

      // Fallback penghitungan omzet per metode jika belum dikembalikan API
      if (!statsMap.containsKey('qrisRevenue')) {
        statsMap['qrisRevenue'] = allSales
            .where((s) => s.paymentMethod == 'QRIS')
            .fold<int>(0, (sum, s) => sum + s.total);
      }
      if (!statsMap.containsKey('tunaiRevenue')) {
        statsMap['tunaiRevenue'] = allSales
            .where((s) => s.paymentMethod == 'TUNAI')
            .fold<int>(0, (sum, s) => sum + s.total);
      }

      setState(() {
        _stats = statsMap;
        _recentSales = allSales.take(5).toList();
        _isLoading = false;
      });
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Keluar dari Akun Kasir?'),
        content: const Text(
          'Sebelum logout, disarankan melakukan Tutup Kasir (Closing Shift) agar laporan penjualan hari ini otomatis terkirim ke Owner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade800,
              side: BorderSide(color: Colors.grey.shade400),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AuthService().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Logout Saja'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              Navigator.pop(ctx);
              PosClosingSheet.show(context, onClosingSuccess: _loadDashboardData);
            },
            child: const Text('Tutup Kasir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatTodayIndonesian(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      final dayName = days[date.weekday - 1];
      final monthName = months[date.month - 1];
      return '$dayName, ${date.day} $monthName ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final todayStr = _formatTodayIndonesian(DateTime.now());

    final todayRevenue = _stats['todayRevenue'] ?? 0;
    final todayTransactions = _stats['todayTransactions'] ?? 0;
    final qrisCount = _stats['qrisCount'] ?? 0;
    final tunaiCount = _stats['tunaiCount'] ?? 0;
    final qrisRevenue = _stats['qrisRevenue'] ?? 0;
    final tunaiRevenue = _stats['tunaiRevenue'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const AppTopBarTitle(roleName: 'Kasir'),
        actions: [
          IconButton(
            tooltip: 'Tutup Kasir / Closing Shift',
            icon: const Icon(Icons.storefront_rounded),
            onPressed: () => PosClosingSheet.show(context, onClosingSuccess: _loadDashboardData),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFD32F2F),
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. HEADER MERAH DENGAN BACKGROUND MELENGKUNG & CARD 2 LAYER ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background Merah Melengkung di Tengah ke Bawah
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 35,
                    child: ClipPath(
                      clipper: const HeaderCurveClipper(),
                      child: Container(
                        color: const Color(0xFFD32F2F),
                      ),
                    ),
                  ),

                  // Card 2 Layer (Layer 1: Putih, Layer 2: Merah Solid + Aksi Cepat)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── LAYER KEDUA (BERWARNA MERAH SOLID) ───────────
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD32F2F).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  (user?.name ?? 'Petugas Kasir').toUpperCase(),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 14.5,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                const Text(
                                                  'Kasir Toko • Unit Koperasi',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Tanggal Hari Ini
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 10.5, color: Colors.white70),
                                          const SizedBox(width: 4),
                                          Text(
                                            todayStr,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.payment_rounded, size: 13, color: Colors.white70),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Layanan Transaksi Tunai & QRIS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── LAYER PERTAMA WARNA PUTIH (DI BAWAH LAYER MERAH): AKSI CEPAT ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 3.5,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD32F2F),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Aksi Kasir Cepat',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2B2B2B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _buildQuickActionBtn(
                                      title: 'Buka POS',
                                      assetPath: 'assets/images/pos.png',
                                      icon: Icons.point_of_sale_rounded,
                                      color: const Color(0xFFD32F2F),
                                      onTap: () => widget.onNavigateTab(1),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuickActionBtn(
                                      title: 'Cek Produk',
                                      icon: Icons.inventory_2_rounded,
                                      color: Colors.blue.shade700,
                                      onTap: () => widget.onNavigateTab(2),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuickActionBtn(
                                      title: 'Penjualan',
                                      assetPath: 'assets/images/penjualan.png',
                                      icon: Icons.receipt_long_rounded,
                                      color: Colors.teal.shade700,
                                      onTap: () => widget.onNavigateTab(3),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuickActionBtn(
                                      title: 'Tutup Kasir',
                                      icon: Icons.storefront_rounded,
                                      color: const Color(0xFF8E0000),
                                      onTap: () => PosClosingSheet.show(context, onClosingSuccess: _loadDashboardData),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 2. METRIK PENJUALAN HARI INI (COMPACT) ───────────────
                    const Text(
                      'Ringkasan Penjualan Hari Ini',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
              const SizedBox(height: 10),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Total Omzet',
                        value: _currencyFormat.format(todayRevenue),
                        isLoading: _isLoading,
                        icon: Icons.payments_rounded,
                        color: const Color(0xFFD32F2F),
                        subtitle: 'Hari Ini',
                        onTap: () => widget.onNavigateTab(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Total Transaksi',
                        value: '$todayTransactions Struk',
                        isLoading: _isLoading,
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF1976D2),
                        subtitle: 'Selesai',
                        onTap: () => widget.onNavigateTab(3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Omzet QRIS',
                        value: _currencyFormat.format(qrisRevenue),
                        isLoading: _isLoading,
                        icon: Icons.qr_code_2_rounded,
                        color: const Color(0xFF7B1FA2),
                        subtitle: '$qrisCount TRX',
                        onTap: () => widget.onNavigateTab(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Omzet Tunai',
                        value: _currencyFormat.format(tunaiRevenue),
                        isLoading: _isLoading,
                        icon: Icons.local_atm_rounded,
                        color: const Color(0xFF2E7D32),
                        subtitle: '$tunaiCount TRX',
                        onTap: () => widget.onNavigateTab(3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 4. TRANSAKSI TERBARU HARI INI ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaksi Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigateTab(3),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Semua',
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFD32F2F)),
                      ],
                    ),
                  ),
                ],
              ),

              if (_isLoading)
                Column(
                  children: List.generate(
                    4,
                    (index) => const SkeletonTransactionTile(),
                  ),
                )
              else if (_recentSales.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 44, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada transaksi hari ini',
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mulai transaksi baru melalui menu POS Kasir.',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _recentSales.map((sale) {
                    final timeStr = DateFormat('HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(sale.createdAtEpochMs),
                    );

                    final isQris = sale.paymentMethod == 'QRIS';
                    final badgeColor = isQris ? const Color(0xFF7B1FA2) : const Color(0xFF2E7D32);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isQris ? Icons.qr_code_2_rounded : Icons.local_atm_rounded,
                            color: badgeColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          sale.transactionId,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                        subtitle: Text(
                          '$timeStr • ${sale.items.length} item • ${sale.paymentMethod}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        trailing: Text(
                          _currencyFormat.format(sale.total),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        onTap: () => widget.onNavigateTab(3),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    ),
  ),
),
);
}

  Widget _buildQuickActionBtn({
    required String title,
    IconData? icon,
    String? assetPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: assetPath != null
                      ? Image.asset(
                          assetPath,
                          width: 24,
                          height: 24,
                          color: color,
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(icon ?? Icons.circle, color: color, size: 24),
                        )
                      : Icon(icon ?? Icons.circle, color: color, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (subtitle != null)
                    isLoading
                        ? const AppSkeleton(width: 40, height: 14, borderRadius: 6)
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: AppSkeleton(width: 70, height: 16, borderRadius: 4),
                    )
                  else
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



