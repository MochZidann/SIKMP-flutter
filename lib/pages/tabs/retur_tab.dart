import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_skeleton.dart';
import '../../core/widgets/app_top_bar_title.dart';
import '../../core/widgets/empty_data_view.dart';
import '../../models/sale_return.dart';
import '../../services/return_service.dart';
import '../pos/widgets/pos_closing_sheet.dart';
import '../pos/widgets/return_detail_sheet.dart';
import '../pos/widgets/return_form_sheet.dart';

class ReturTab extends StatefulWidget {
  const ReturTab({super.key});

  @override
  State<ReturTab> createState() => ReturTabState();
}

class ReturTabState extends State<ReturTab> {
  final ReturnService _returnService = ReturnService();
  final TextEditingController _searchController = TextEditingController();

  List<SaleReturnModel> _returns = [];
  Map<String, dynamic> _kpis = {};
  bool _isLoading = true;
  String _selectedReason = 'all'; // 'all', 'RUSAK', 'KADALUARSA', 'SALAH_BELI', 'LAINNYA'
  final String _selectedRange = 'all'; // 'all', 'today', '7d', '30d'

  @override
  void initState() {
    super.initState();
    loadReturns();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadReturns({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    final res = await _returnService.getReturns(
      search: _searchController.text.trim(),
      reason: _selectedReason,
      range: _selectedRange,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _returns = res['returns'] as List<SaleReturnModel>? ?? [];
          _kpis = res['kpis'] as Map<String, dynamic>? ?? {};
        }
      });
    }
  }

  void reload() {
    loadReturns(silent: true);
  }

  void _openReturnForm() {
    ReturnFormSheet.show(
      context,
      onReturnSuccess: () {
        loadReturns();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryKasir = Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: primaryKasir,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const AppTopBarTitle(roleName: 'Kasir'),
        actions: [
          IconButton(
            tooltip: 'Tutup Kasir / Closing Shift',
            icon: const Icon(Icons.storefront_rounded),
            onPressed: () => PosClosingSheet.show(context, onClosingSuccess: reload),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── KPI METRIK SUMMARY CARDS ───────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Total Retur',
                        value: '${_kpis['total_returns'] ?? 0} Kasus',
                        icon: Icons.assignment_return_rounded,
                        color: const Color(0xFFD32F2F),
                        bgColor: const Color(0xFFFFF1F2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Total Refund',
                        value: CurrencyHelper.formatRupiah(_kpis['total_refund'] ?? 0),
                        icon: Icons.payments_rounded,
                        color: const Color(0xFF047857),
                        bgColor: const Color(0xFFECFDF5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Barang Rusak',
                        value: '${_kpis['total_damaged'] ?? 0} Unit',
                        icon: Icons.broken_image_rounded,
                        color: const Color(0xFFB45309),
                        bgColor: const Color(0xFFFFFBEB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Kadaluarsa',
                        value: '${_kpis['total_expired'] ?? 0} Unit',
                        icon: Icons.event_busy_rounded,
                        color: const Color(0xFF6B7280),
                        bgColor: const Color(0xFFF3F4F6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => loadReturns(),
                  decoration: InputDecoration(
                    hintText: 'Cari no retur, ref transaksi, pembeli...',
                    hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9E9E9E)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              loadReturns();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Reason Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('Semua Alasan', 'all'),
                      const SizedBox(width: 6),
                      _buildChip('Barang Rusak', 'RUSAK'),
                      const SizedBox(width: 6),
                      _buildChip('Kadaluarsa', 'KADALUARSA'),
                      const SizedBox(width: 6),
                      _buildChip('Salah Beli', 'SALAH_BELI'),
                      const SizedBox(width: 6),
                      _buildChip('Lainnya', 'LAINNYA'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── DAFTAR TRANSAKSI RETUR ─────────────────────────────────────
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    itemBuilder: (_, _) => const SkeletonTransactionTile(),
                  )
                : _returns.isEmpty
                    ? EmptyDataView(
                        icon: Icons.assignment_return_outlined,
                        title: 'Belum Ada Transaksi Retur',
                        subtitle: 'Pencatatan komplain dan pengembalian barang dari pembeli akan muncul di sini.',
                        actionLabel: 'Buat Retur Baru',
                        onAction: _openReturnForm,
                      )
                    : RefreshIndicator(
                        color: primaryKasir,
                        onRefresh: loadReturns,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _returns.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final ret = _returns[index];
                            return _buildReturnCard(ret);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryKasir,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Retur', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _openReturnForm,
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700)),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _selectedReason == value;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: const Color(0xFFD32F2F),
      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF374151)),
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) {
        setState(() => _selectedReason = value);
        loadReturns();
      },
    );
  }

  Widget _buildReturnCard(SaleReturnModel ret) {
    const primaryKasir = Color(0xFFD32F2F);

    return InkWell(
      onTap: () => ReturnDetailSheet.show(context, returnItem: ret),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ret.returnNo,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: primaryKasir),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ret.reasonLabel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                      ),
                    ),
                  ],
                ),
                Text(
                  ret.createdAtFormatted ?? '-',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ref: ${ret.transactionId}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pelanggan: ${ret.customerName}  •  Kasir: ${ret.cashierName}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ret.actionType == 'REFUND_CASH'
                          ? CurrencyHelper.formatRupiah(ret.totalRefund)
                          : 'Tukar Barang',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: primaryKasir),
                    ),
                    Text(
                      '${ret.itemCount} unit barang',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
