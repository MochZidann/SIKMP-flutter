import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helper.dart';
import '../../../models/owner_models.dart';
import '../../../services/owner_service.dart';

class OwnerSalesTab extends StatefulWidget {
  const OwnerSalesTab({super.key});

  @override
  State<OwnerSalesTab> createState() => _OwnerSalesTabState();
}

class _OwnerSalesTabState extends State<OwnerSalesTab> {
  final OwnerService _ownerService = OwnerService();

  String _selectedFilter = 'today';
  bool _isLoading = true;
  String? _errorMessage;
  OwnerSalesData? _salesData;
  String _searchQuery = '';

  final List<Map<String, String>> _filterOptions = const [
    {'key': 'today', 'label': 'Hari Ini'},
    {'key': '7d', 'label': '7 Hari'},
    {'key': '30d', 'label': '30 Hari'},
    {'key': 'month', 'label': 'Bulan Ini'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _ownerService.getSalesReport(filter: _selectedFilter);
      if (!mounted) return;

      if (data != null) {
        setState(() {
          _salesData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat laporan penjualan dari server.';
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

  void _onFilterChanged(String newFilter) {
    if (_selectedFilter == newFilter) return;
    setState(() {
      _selectedFilter = newFilter;
    });
    _loadSalesData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Bar Filter Periode
        _buildFilterBar(),

        // 2. Konten Utama
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00796B)),
                )
              : _errorMessage != null || _salesData == null
                  ? _buildErrorView()
                  : _buildSalesContent(_salesData!),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((opt) {
            final isSelected = _selectedFilter == opt['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                showCheckmark: false,
                label: Text(opt['label']!),
                selected: isSelected,
                selectedColor: const Color(0xFF00796B),
                backgroundColor: Colors.grey.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF00796B) : Colors.grey.shade300,
                  ),
                ),
                onSelected: (_) => _onFilterChanged(opt['key']!),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat data',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
              ),
              onPressed: _loadSalesData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesContent(OwnerSalesData data) {
    final filteredSales = data.sales.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.transactionId.toLowerCase().contains(q) ||
          s.cashierName.toLowerCase().contains(q) ||
          s.paymentMethod.toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFF00796B),
      onRefresh: _loadSalesData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // A. Banner Ringkasan Periode
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded, size: 18, color: Color(0xFF00796B)),
                const SizedBox(width: 8),
                Text(
                  'Laporan Periode: ${data.filterLabel}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // B. KPI Grid (2x2)
          _buildSalesKpiGrid(data),

          const SizedBox(height: 18),

          // C. Performa Kasir (Cashier Breakdown)
          _buildCashierPerformanceCard(data.cashierPerformance, data.revenue),

          const SizedBox(height: 18),

          // D. Feed Transaksi dengan Search Box
          _buildTransactionsSection(filteredSales),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSalesKpiGrid(OwnerSalesData data) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Omzet',
                  value: formatRupiah(data.revenue),
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFF00796B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Transaksi',
                  value: '${data.txCount} Struk',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF1976D2),
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
              Expanded(
                child: _buildMetricTile(
                  title: 'Item Terjual',
                  value: '${data.itemsSold} Pcs',
                  icon: Icons.shopping_bag_rounded,
                  color: const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Rata-rata Keranjang',
                  value: formatRupiah(data.avgBasket),
                  icon: Icons.shopping_cart_checkout_rounded,
                  color: const Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
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
    );
  }

  Widget _buildCashierPerformanceCard(List<CashierPerformanceItem> list, int totalRevenue) {
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
              Icon(Icons.badge_rounded, color: Color(0xFF00796B), size: 20),
              SizedBox(width: 8),
              Text(
                'Performa & Kontribusi Kasir',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Tidak ada data kasir pada periode ini',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            )
          else
            ...list.map((c) {
              final ratio = totalRevenue > 0 ? (c.totalRevenue / totalRevenue).clamp(0.0, 1.0) : 0.0;
              final percent = (ratio * 100).toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF00796B).withValues(alpha: 0.15),
                              child: Text(
                                c.cashierName.isNotEmpty ? c.cashierName[0].toUpperCase() : 'K',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00796B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              c.cashierName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          formatRupiah(c.totalRevenue),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00796B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00796B)),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${c.txCount} trx ($percent%)',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

  Widget _buildTransactionsSection(List<OwnerRecentSaleItem> sales) {
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
                  Icon(Icons.list_alt_rounded, color: Color(0xFF00796B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Riwayat Transaksi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                '${sales.length} Struk',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search Box
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Cari No. Struk atau Kasir...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF00796B)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00796B)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (sales.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'Tidak ada transaksi cocok dengan pencarian'
                      : 'Tidak ada transaksi pada periode ini',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            )
          else
            ...sales.map((sale) {
              final isQris = sale.paymentMethod.toUpperCase() == 'QRIS';

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    const SizedBox(width: 12),
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
                          const SizedBox(height: 2),
                          Text(
                            '${sale.cashierName} • ${sale.itemCount} item',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          Text(
                            DateHelper.formatEpochMs(sale.createdAtEpochMs),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRupiah(sale.total),
                      style: const TextStyle(
                        fontSize: 14,
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
