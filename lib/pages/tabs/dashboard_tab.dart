import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/sale_record.dart';
import '../../services/auth_service.dart';
import '../../services/pos_service.dart';
import '../login_page.dart';

class DashboardTab extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardTab({super.key, required this.onNavigateTab});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final PosService _posService = PosService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<SaleRecord> _recentSales = [];

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
      setState(() {
        _stats = result['stats'] as Map<String, dynamic>? ?? {};
        _recentSales = (result['sales'] as List<SaleRecord>? ?? []).take(5).toList();
        _isLoading = false;
      });
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Apakah Anda yakin ingin logout dari akun kasir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().logout();
              if (context.mounted) {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
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
                color: Color(0xFFD32F2F),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kopdes Merah Putih',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user != null ? 'Kasir: ${user.name}' : 'Desa Maju Makmur',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. KARTU IDENTITAS KASIR ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFF8E0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: const Icon(Icons.person_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Petugas Kasir',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'ID: KASIR-0${user?.id ?? '1'}',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                            SizedBox(width: 6),
                            Text(
                              'Shift Aktif',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    todayStr,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. STATISTIK PENJUALAN HARI INI ────────────────────────────
            const Text(
              'Ringkasan Penjualan Hari Ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                // Total Omset
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                              'Total Omset',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Icon(Icons.monetization_on_outlined,
                                color: Colors.green.shade600, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLoading ? 'Memuat...' : _currencyFormat.format(todayRevenue),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Total Transaksi
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                              'Transaksi',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Icon(Icons.receipt_long_outlined,
                                color: Colors.blue.shade600, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLoading ? '...' : '$todayTransactions Struk',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Rincian QRIS vs Tunai
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_2_rounded,
                            color: Color(0xFFD32F2F), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'QRIS: $qrisCount TRX',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.payments_outlined,
                            color: Colors.green, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tunai: $tunaiCount TRX',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 3. PINTASAN CEPAT (SHORTCUTS) ───────────────────────────────
            const Text(
              'Aksi Kasir Cepat',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                _buildQuickActionBtn(
                  title: 'Buka POS',
                  subtitle: 'Transaksi Baru',
                  icon: Icons.point_of_sale_rounded,
                  color: const Color(0xFFD32F2F),
                  onTap: () => widget.onNavigateTab(1), // Pindah ke Tab POS
                ),
                const SizedBox(width: 10),
                _buildQuickActionBtn(
                  title: 'Cek Produk',
                  subtitle: 'Stok & Harga',
                  icon: Icons.inventory_2_rounded,
                  color: Colors.blue.shade700,
                  onTap: () => widget.onNavigateTab(2), // Pindah ke Tab Produk
                ),
                const SizedBox(width: 10),
                _buildQuickActionBtn(
                  title: 'Penjualan',
                  subtitle: 'Riwayat Struk',
                  icon: Icons.receipt_long_rounded,
                  color: Colors.teal.shade700,
                  onTap: () => widget.onNavigateTab(3), // Pindah ke Tab Penjualan
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── 4. TRANSAKSI TERAKHIR HARI INI ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaksi Terbaru',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab(3),
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(color: Color(0xFFD32F2F), fontSize: 13),
                  ),
                ),
              ],
            ),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                ),
              )
            else if (_recentSales.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_outlined, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada transaksi hari ini.',
                      style: TextStyle(color: Colors.grey),
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

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: sale.paymentMethod == 'QRIS'
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        child: Icon(
                          sale.paymentMethod == 'QRIS'
                              ? Icons.qr_code_2_rounded
                              : Icons.payments_outlined,
                          color: sale.paymentMethod == 'QRIS'
                              ? const Color(0xFFD32F2F)
                              : Colors.green,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        sale.transactionId,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '$timeStr • ${sale.items.length} item • ${sale.paymentMethod}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      trailing: Text(
                        _currencyFormat.format(sale.total),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
