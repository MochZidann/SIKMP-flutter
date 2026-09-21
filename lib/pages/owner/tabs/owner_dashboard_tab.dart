import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helper.dart';
import '../../../models/owner_models.dart';
import '../../../services/owner_service.dart';

class OwnerDashboardTab extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const OwnerDashboardTab({super.key, this.onNavigateTab});

  @override
  State<OwnerDashboardTab> createState() => _OwnerDashboardTabState();
}

class _OwnerDashboardTabState extends State<OwnerDashboardTab> {
  final OwnerService _ownerService = OwnerService();

  bool _isLoading = true;
  String? _errorMessage;
  OwnerDashboardData? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _ownerService.getDashboard();
      if (!mounted) return;

      if (data != null) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data dari server. Periksa koneksi atau URL API.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00796B)),
            SizedBox(height: 16),
            Text(
              'Menghubungkan ke data eksekutif...',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _dashboardData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Data tidak tersedia',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loadDashboardData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _dashboardData!;

    return RefreshIndicator(
      color: const Color(0xFF00796B),
      onRefresh: _loadDashboardData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Smart Executive Insights Card
          _buildInsightsCard(data),

          const SizedBox(height: 16),

          // 2. Grid KPI Cards (2x2)
          _buildKpiGrid(data),

          const SizedBox(height: 20),

          // 3. Tren Penjualan 7 Hari Terakhir
          _buildSalesTrendCard(data.salesTrend),

          const SizedBox(height: 20),

          // 4. Top 5 Produk Terlaris
          _buildTopProductsCard(data.topProducts),

          const SizedBox(height: 20),

          // 5. Transaksi Terkini
          _buildRecentSalesCard(data.recentSales),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 1. Smart Executive Insights Card
  Widget _buildInsightsCard(OwnerDashboardData data) {
    final isRevenueUp = data.revenueGrowthPercent >= 0;
    final isLowStockAlert = data.lowStockCount > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Eksekutif Hari Ini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Analisis performa & stok terkini',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Point 1: Pertumbuhan Revenue
          _buildInsightBullet(
            icon: isRevenueUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: isRevenueUp ? Colors.greenAccent : Colors.orangeAccent,
            text: data.todayRevenue > 0
                ? 'Omzet hari ini ${formatRupiah(data.todayRevenue)} (${isRevenueUp ? '+' : ''}${data.revenueGrowthPercent}% dibanding kemarin).'
                : 'Belum ada transaksi penjualan hari ini.',
          ),

          const SizedBox(height: 8),

          // Point 2: Transaksi
          _buildInsightBullet(
            icon: Icons.receipt_long_rounded,
            color: Colors.cyanAccent,
            text: '${data.todayTxCount} transaksi kasir telah tuntas hari ini.',
          ),

          const SizedBox(height: 8),

          // Point 3: Peringatan Stok
          _buildInsightBullet(
            icon: isLowStockAlert ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            color: isLowStockAlert ? Colors.amberAccent : Colors.tealAccent,
            text: isLowStockAlert
                ? '${data.lowStockCount} barang berada di bawah batas minimum stok!'
                : 'Semua stok produk dalam kondisi aman terkendali.',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightBullet({required IconData icon, required Color color, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
          ),
        ),
      ],
    );
  }

  /// 2. Grid KPI Cards
  Widget _buildKpiGrid(OwnerDashboardData data) {
    return Column(
      children: [
        Row(
          children: [
            // Omzet Hari Ini
            Expanded(
              child: _buildMetricCard(
                title: 'Omzet Hari Ini',
                value: formatRupiah(data.todayRevenue),
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFF00796B),
                badgeText: '${data.revenueGrowthPercent >= 0 ? '+' : ''}${data.revenueGrowthPercent}%',
                isPositive: data.revenueGrowthPercent >= 0,
              ),
            ),
            const SizedBox(width: 12),
            // Transaksi Hari Ini
            Expanded(
              child: _buildMetricCard(
                title: 'Transaksi Hari Ini',
                value: '${data.todayTxCount} Struk',
                icon: Icons.point_of_sale_rounded,
                iconColor: const Color(0xFF1976D2),
                badgeText: '${data.txGrowthPercent >= 0 ? '+' : ''}${data.txGrowthPercent}%',
                isPositive: data.txGrowthPercent >= 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Stok Kritis
            Expanded(
              child: _buildMetricCard(
                title: 'Stok Kritis',
                value: '${data.lowStockCount} Produk',
                icon: Icons.notification_important_rounded,
                iconColor: data.lowStockCount > 0 ? const Color(0xFFD32F2F) : Colors.teal,
                badgeText: data.lowStockCount > 0 ? 'Perlu Restock' : 'Aman',
                isPositive: data.lowStockCount == 0,
                onTap: () => widget.onNavigateTab?.call(2),
              ),
            ),
            const SizedBox(width: 12),
            // Total Nilai Aset
            Expanded(
              child: _buildMetricCard(
                title: 'Valuasi Aset Stok',
                value: formatRupiah(data.totalAssetValue),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF6A1B9A),
                badgeText: 'Total Modal',
                isPositive: true,
                onTap: () => widget.onNavigateTab?.call(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required bool isPositive,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Grafik Tren Penjualan 7 Hari Terakhir
  Widget _buildSalesTrendCard(List<SalesTrendItem> trend) {
    int maxVal = 1;
    for (final item in trend) {
      if (item.total > maxVal) maxVal = item.total;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: Color(0xFF00796B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tren Penjualan 7 Hari Terakhir',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => widget.onNavigateTab?.call(1),
                child: const Text('Detail', style: TextStyle(fontSize: 12, color: Color(0xFF00796B))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bar Chart Container
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: trend.map((item) {
                final ratio = maxVal > 0 ? (item.total / maxVal).clamp(0.05, 1.0) : 0.05;
                final isToday = item == trend.last;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Nilai angka
                    Text(
                      item.total >= 1000000
                          ? '${(item.total / 1000000).toStringAsFixed(1)}jt'
                          : item.total >= 1000
                              ? '${(item.total / 1000).round()}k'
                              : '${item.total}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isToday ? const Color(0xFF00796B) : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Bar
                    Container(
                      width: 22,
                      height: 80 * ratio,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [const Color(0xFF004D40), const Color(0xFF00796B)]
                              : [const Color(0xFF80CBC4), const Color(0xFFB2DFDB)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Tanggal
                    Text(
                      item.date,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? const Color(0xFF00796B) : Colors.grey.shade700,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Top 5 Produk Terlaris
  Widget _buildTopProductsCard(List<TopProductItem> topProducts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.military_tech_rounded, color: Colors.amber, size: 22),
              SizedBox(width: 8),
              Text(
                'Top Produk Terlaris',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (topProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Belum ada data produk terjual',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            )
          else
            ...List.generate(topProducts.length, (index) {
              final product = topProducts[index];
              final rank = index + 1;

              Color rankColor = Colors.grey.shade400;
              if (rank == 1) rankColor = Colors.amber.shade700;
              if (rank == 2) rankColor = Colors.blueGrey.shade400;
              if (rank == 3) rankColor = Colors.brown.shade400;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Terjual: ${product.quantity} pcs',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRupiah(product.totalRevenue),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00796B),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  /// 5. Transaksi Terkini
  Widget _buildRecentSalesCard(List<OwnerRecentSaleItem> recentSales) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, color: Color(0xFF00796B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Transaksi Terkini',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => widget.onNavigateTab?.call(1),
                child: const Text('Semua', style: TextStyle(fontSize: 12, color: Color(0xFF00796B))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recentSales.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Belum ada transaksi',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            )
          else
            ...recentSales.map((sale) {
              final isQris = sale.paymentMethod.toUpperCase() == 'QRIS';

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: isQris ? Colors.purple.shade50 : Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isQris ? 'QRIS' : 'TUNAI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isQris ? Colors.purple.shade700 : Colors.teal.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.transactionId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '${sale.cashierName} • ${DateHelper.formatEpochMs(sale.createdAtEpochMs)}',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRupiah(sale.total),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
