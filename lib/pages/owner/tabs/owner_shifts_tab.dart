import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../models/cashier_shift_model.dart';
import '../../../services/owner_shift_service.dart';
import '../widgets/owner_shift_detail_sheet.dart';

class OwnerShiftsTab extends StatefulWidget {
  const OwnerShiftsTab({super.key});

  @override
  State<OwnerShiftsTab> createState() => OwnerShiftsTabState();
}

class OwnerShiftsTabState extends State<OwnerShiftsTab> {
  final OwnerShiftService _shiftService = OwnerShiftService();
  final TextEditingController _searchController = TextEditingController();

  List<CashierShiftModel> _shifts = [];
  Map<String, dynamic> _kpis = {};
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    loadShifts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadShifts() async {
    setState(() => _isLoading = true);
    final res = await _shiftService.getShifts(
      status: _selectedStatus,
      search: _searchController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _shifts = res['shifts'] as List<CashierShiftModel>? ?? [];
          _kpis = res['kpis'] as Map<String, dynamic>? ?? {};
        }
      });
    }
  }

  void reload() {
    loadShifts();
  }

  @override
  Widget build(BuildContext context) {
    const ownerTeal = Color(0xFF00796B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // ── KPI METRIK SHIFT ───────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Total Shift',
                        value: '${_kpis['total_shifts'] ?? 0} Sesi',
                        icon: Icons.history_rounded,
                        color: const Color(0xFF00796B),
                        bgColor: const Color(0xFFE0F2F1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Shift Aktif',
                        value: '${_kpis['open_shifts'] ?? 0} Buka',
                        icon: Icons.lock_open_rounded,
                        color: const Color(0xFF1D4ED8),
                        bgColor: const Color(0xFFEFF6FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Perlu Review',
                        value: '${_kpis['needs_review'] ?? 0} Shift',
                        icon: Icons.pending_actions_rounded,
                        color: const Color(0xFFB45309),
                        bgColor: const Color(0xFFFFFBEB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Total Selisih Kas',
                        value: CurrencyHelper.formatRupiah(_kpis['total_discrepancy'] ?? 0),
                        icon: Icons.account_balance_wallet_rounded,
                        color: (_kpis['total_discrepancy'] ?? 0) != 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF047857),
                        bgColor: (_kpis['total_discrepancy'] ?? 0) != 0
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFECFDF5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => loadShifts(),
                  decoration: InputDecoration(
                    hintText: 'Cari kasir atau nomor shift...',
                    hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9E9E9E)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              loadShifts();
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

                // Filter Status Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('Semua Shift', 'all'),
                      const SizedBox(width: 6),
                      _buildChip('Aktif (Buka)', 'OPEN'),
                      const SizedBox(width: 6),
                      _buildChip('Ditutup', 'CLOSED'),
                      const SizedBox(width: 6),
                      _buildChip('Disetujui', 'APPROVED'),
                      const SizedBox(width: 6),
                      _buildChip('Hitung Ulang', 'RECOUNT'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── DAFTAR RIWAYAT SHIFT KASIR ─────────────────────────────────
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    itemBuilder: (_, _) => const SkeletonTransactionTile(),
                  )
                : _shifts.isEmpty
                    ? EmptyDataView(
                        icon: Icons.badge_outlined,
                        title: 'Riwayat Shift Kosong',
                        subtitle: 'Daftar penutupan shift dan rekonsiliasi kas kasir akan muncul di sini.',
                        actionLabel: 'Muat Ulang',
                        onAction: loadShifts,
                      )
                    : RefreshIndicator(
                        color: ownerTeal,
                        onRefresh: loadShifts,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _shifts.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final s = _shifts[index];
                            return _buildShiftCard(s);
                          },
                        ),
                      ),
          ),
        ],
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
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: const Color(0xFF00796B),
      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF374151)),
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) {
        setState(() => _selectedStatus = value);
        loadShifts();
      },
    );
  }

  Widget _buildShiftCard(CashierShiftModel s) {
    final diff = s.difference;
    return InkWell(
      onTap: () {
        OwnerShiftDetailSheet.show(
          context,
          shift: s,
          onReviewed: loadShifts,
        );
      },
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
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Shift #${s.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF00796B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.cashierName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                    ),
                  ],
                ),
                _buildStatusBadge(s.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Buka: ${s.openedAt ?? '-'}   •   Tutup: ${s.closedAt ?? 'Aktif'}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kas Fisik Dihitung', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text(
                      CurrencyHelper.formatRupiah(s.countedCash),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF111827)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Selisih Kas', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text(
                      diff == 0
                          ? 'Pas (Rp 0)'
                          : diff < 0
                              ? 'Tekor -${CurrencyHelper.formatRupiah(diff.abs())}'
                              : 'Lebih +${CurrencyHelper.formatRupiah(diff)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: diff == 0
                            ? const Color(0xFF047857)
                            : diff < 0
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF1D4ED8),
                      ),
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

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFEFF6FF);
    Color text = const Color(0xFF1D4ED8);
    String label = 'Aktif';

    switch (status.toUpperCase()) {
      case 'OPEN':
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1D4ED8);
        label = 'Aktif';
        break;
      case 'CLOSED':
      case 'SUBMITTED':
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFB45309);
        label = 'Menunggu Review';
        break;
      case 'APPROVED':
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF047857);
        label = 'Disetujui';
        break;
      case 'RECOUNT':
        bg = const Color(0xFFFEF2F2);
        text = const Color(0xFFDC2626);
        label = 'Hitung Ulang';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: text)),
    );
  }
}
