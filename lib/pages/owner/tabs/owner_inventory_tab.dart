import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/owner_models.dart';
import '../../../services/owner_service.dart';

class OwnerInventoryTab extends StatefulWidget {
  const OwnerInventoryTab({super.key});

  @override
  State<OwnerInventoryTab> createState() => _OwnerInventoryTabState();
}

class _OwnerInventoryTabState extends State<OwnerInventoryTab> {
  final OwnerService _ownerService = OwnerService();

  bool _isLoading = true;
  String? _errorMessage;
  OwnerInventoryData? _inventoryData;

  @override
  void initState() {
    super.initState();
    _loadInventoryData();
  }

  Future<void> _loadInventoryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _ownerService.getInventoryHealth();
      if (!mounted) return;

      if (data != null) {
        setState(() {
          _inventoryData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data inventori dari server.';
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
              'Menganalisis kesehatan inventori & aset...',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _inventoryData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Data inventori tidak tersedia',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                ),
                onPressed: _loadInventoryData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _inventoryData!;

    return RefreshIndicator(
      color: const Color(0xFF00796B),
      onRefresh: _loadInventoryData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. KPI Metrik Valuasi & Kesehatan Aset (2x2)
          _buildMetricsGrid(data),

          const SizedBox(height: 20),

          // 2. Sebaran Nilai Aset per Kategori
          _buildCategoryDistributionCard(data.assetByCategory),

          const SizedBox(height: 20),

          // 3. Peringatan Stok Kritis (Urgent Restock)
          _buildLowStockCard(data.lowStockProducts),

          const SizedBox(height: 20),

          // 4. Dead Stock Monitor (>30 hari)
          _buildDeadStockCard(data.deadStockProducts, data.deadStockValue),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(OwnerInventoryData data) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total Valuasi Aset
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Valuasi Aset',
                  value: formatRupiah(data.totalAssetValue),
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF00796B),
                  badgeText: 'Modal Fisik',
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              // Total SKU Produk
              Expanded(
                child: _buildMetricCard(
                  title: 'Total SKU Produk',
                  value: '${data.totalSku} SKU',
                  icon: Icons.category_rounded,
                  iconColor: const Color(0xFF1976D2),
                  badgeText: 'Katalog',
                  isPositive: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                ),
              ),
              const SizedBox(width: 12),
              // Dead Stock (>30hr)
              Expanded(
                child: _buildMetricCard(
                  title: 'Dead Stock (>30hr)',
                  value: '${data.deadStockCount} Produk',
                  icon: Icons.hourglass_disabled_rounded,
                  iconColor: const Color(0xFFE65100),
                  badgeText: data.deadStockCount > 0 ? 'Tertahan' : 'Optimal',
                  isPositive: data.deadStockCount == 0,
                ),
              ),
            ],
          ),
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
                    color: isPositive
                        ? Colors.green.shade50
                        : (iconColor == const Color(0xFFE65100)
                            ? Colors.orange.shade50
                            : Colors.red.shade50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPositive
                          ? Colors.green.shade700
                          : (iconColor == const Color(0xFFE65100)
                              ? Colors.orange.shade800
                              : Colors.red.shade700),
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

  Widget _buildCategoryDistributionCard(List<CategoryAssetItem> categories) {
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
              Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF00796B), size: 20),
              SizedBox(width: 8),
              Text(
                'Sebaran Nilai Aset per Kategori',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Belum ada data kategori',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            )
          else
            ...categories.map((c) {
              final ratio = (c.percentage / 100.0).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${c.category} (${c.skuCount} SKU)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '${formatRupiah(c.totalValue)} (${c.percentage}%)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00796B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00796B)),
                        minHeight: 6,
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

  Widget _buildLowStockCard(List<LowStockProductItem> lowStock) {
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
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Peringatan Stok Kritis (Restock)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: lowStock.isNotEmpty ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${lowStock.length} Item',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: lowStock.isNotEmpty ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lowStock.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  '🎉 Luar biasa! Tidak ada stok kritis saat ini.',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            )
          else
            ...lowStock.map((item) {
              final isZero = item.stock <= 0;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isZero ? Colors.red.shade50.withValues(alpha: 0.5) : Colors.orange.shade50.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isZero ? Colors.red.shade200 : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: isZero ? Colors.red.shade600 : Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isZero ? 'HABIS' : 'MENIPIS',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '${item.category} • ${formatRupiah(item.price)}',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.stock} ${item.unit}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isZero ? Colors.red.shade700 : Colors.orange.shade900,
                          ),
                        ),
                        Text(
                          'Min: ${item.minimumStock} ${item.unit}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDeadStockCard(List<DeadStockProductItem> deadStock, int totalValue) {
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
                  Icon(Icons.hourglass_disabled_rounded, color: Color(0xFFE65100), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Dead Stock (>30 Hari Mengendap)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                formatRupiah(totalValue),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Barang yang tidak mengalami mutasi masuk/keluar dalam 30 hari terakhir. Modal tertahan yang perlu dipromosikan.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
          ),
          const SizedBox(height: 12),
          if (deadStock.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Tidak ada dead stock, perputaran barang optimal!',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            )
          else
            ...deadStock.take(15).map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.archive_outlined, size: 14, color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.category} • Stok: ${item.stock} pcs',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRupiah(item.value),
                      style: const TextStyle(
                        fontSize: 12,
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
