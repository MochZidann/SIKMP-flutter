import 'package:flutter/material.dart';
import '../../core/utils/date_helper.dart';
import '../../core/widgets/app_skeleton.dart';
import '../../core/widgets/empty_data_view.dart';
import '../../models/supplier.dart';
import '../../models/supplier_mutation.dart';
import '../../services/supplier_service.dart';

class GudangSupplierMutationsPage extends StatefulWidget {
  final Supplier supplier;

  const GudangSupplierMutationsPage({super.key, required this.supplier});

  @override
  State<GudangSupplierMutationsPage> createState() => _GudangSupplierMutationsPageState();
}

class _GudangSupplierMutationsPageState extends State<GudangSupplierMutationsPage> {
  final SupplierService _supplierService = SupplierService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'ALL'; // ALL, IN, OUT
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  List<SupplierMutation> _allMutations = [];
  Map<String, dynamic> _summary = {'totalIn': 0, 'totalOut': 0, 'net': 0};

  @override
  void initState() {
    super.initState();
    _loadMutations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMutations() async {
    setState(() => _isLoading = true);
    final result = await _supplierService.getSupplierMutations(
      widget.supplier.id,
      type: _selectedFilter == 'ALL' ? null : _selectedFilter,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (mounted) {
      setState(() {
        _allMutations = (result['mutations'] as List<SupplierMutation>?) ?? [];
        _summary = (result['summary'] as Map<String, dynamic>?) ?? {
          'totalIn': 0,
          'totalOut': 0,
          'net': 0,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Pilih Rentang Tanggal Pasokan',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
      saveText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE65100),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadMutations();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadMutations();
  }

  String _formatShortDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatFullDate(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  List<SupplierMutation> get _filteredMutations {
    final query = _searchController.text.trim().toLowerCase();

    return _allMutations.where((m) {
      final matchesQuery = query.isEmpty ||
          m.productName.toLowerCase().contains(query) ||
          (m.barcode != null && m.barcode!.toLowerCase().contains(query)) ||
          (m.note != null && m.note!.toLowerCase().contains(query)) ||
          (m.userName != null && m.userName!.toLowerCase().contains(query));
      if (!matchesQuery) return false;

      // Filter client-side berdasarkan rentang tanggal epoch ms
      if (_startDate != null) {
        final startMs = DateTime(_startDate!.year, _startDate!.month, _startDate!.day).millisecondsSinceEpoch;
        if ((m.createdAtEpochMs ?? 0) < startMs) return false;
      }
      if (_endDate != null) {
        final endMs = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59, 999).millisecondsSinceEpoch;
        if ((m.createdAtEpochMs ?? 0) > endMs) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);

    final totalIn = _summary['totalIn'] ?? 0;
    final totalOut = _summary['totalOut'] ?? 0;
    final net = _summary['net'] ?? (totalIn - totalOut);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Pasokan Rekanan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              widget.supplier.name,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _startDate != null
                ? 'Filter Aktif: ${_formatShortDate(_startDate!)} - ${_formatShortDate(_endDate!)}'
                : 'Filter Rentang Tanggal',
            icon: Badge(
              isLabelVisible: _startDate != null,
              backgroundColor: Colors.amberAccent,
              smallSize: 8,
              child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
            ),
            onPressed: _pickDateRange,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── KARTU PROFIL REKANAN & KPI METRICS ───────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Rekanan
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business_rounded, color: primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.supplier.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (widget.supplier.contactPerson != null && widget.supplier.contactPerson!.isNotEmpty)
                                'PIC: ${widget.supplier.contactPerson}',
                              if (widget.supplier.phone != null && widget.supplier.phone!.isNotEmpty)
                                widget.supplier.phone!,
                              if (widget.supplier.email != null && widget.supplier.email!.isNotEmpty)
                                widget.supplier.email!,
                            ].join('  •  '),
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.supplier.address != null && widget.supplier.address!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.supplier.address!,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // KPI 3 Kotak (Total Masuk, Total Retur, Netto Pasokan)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Masuk',
                        value: '+$totalIn',
                        subtitle: 'Barang pasokan',
                        textColor: const Color(0xFF047857),
                        bgColor: const Color(0xFFECFDF5),
                        borderColor: const Color(0xFFA7F3D0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Retur',
                        value: '-$totalOut',
                        subtitle: 'Dikembalikan',
                        textColor: const Color(0xFFBE123C),
                        bgColor: const Color(0xFFFFF1F2),
                        borderColor: const Color(0xFFFECDD3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Net Saldo',
                        value: '${net >= 0 ? "+" : ""}$net',
                        subtitle: 'Stok tersimpan',
                        textColor: primaryColor,
                        bgColor: const Color(0xFFFFF7ED),
                        borderColor: const Color(0xFFFFEDD5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── FILTER TAB BAR & PENCARIAN ───────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                // Banner Indikator Rentang Tanggal Aktif (Bila Terpilih)
                if (_startDate != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_note_rounded, size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Periode: ${_formatFullDate(_startDate!)} s/d ${_formatFullDate(_endDate!)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _clearDateRange,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close_rounded, size: 12, color: Colors.red.shade700),
                                const SizedBox(width: 3),
                                Text(
                                  'Reset',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Search Input
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari barang, barcode, atau catatan...',
                      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade500),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Buttons Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua Transaksi', 'ALL', primaryColor),
                      const SizedBox(width: 8),
                      _buildFilterChip('Barang Masuk (IN)', 'IN', const Color(0xFF047857)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Retur Barang (OUT)', 'OUT', const Color(0xFFBE123C)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── DAFTAR RIWAYAT MUTASI DENGAN ZERO OVERFLOW ──────────────
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (_, _) => const SkeletonProductTile(),
                  )
                : _filteredMutations.isEmpty
                    ? EmptyDataView(
                        icon: Icons.history_rounded,
                        title: 'Belum Ada Riwayat Mutasi',
                        subtitle: _startDate != null || _searchController.text.isNotEmpty
                            ? 'Tidak ada mutasi yang sesuai dengan filter atau rentang tanggal yang dipilih.'
                            : 'Belum ada catatan transaksi barang masuk atau retur untuk supplier ini.',
                        actionLabel: 'Muat Ulang',
                        onAction: _loadMutations,
                      )
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: _loadMutations,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredMutations.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _filteredMutations[index];
                            final isIn = item.type == 'IN';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ikon Masuk / Keluar
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isIn ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isIn ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3),
                                      ),
                                    ),
                                    child: Icon(
                                      isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
                                      size: 18,
                                      color: isIn ? const Color(0xFF047857) : const Color(0xFFBE123C),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Detail Mutasi Barang
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            color: Color(0xFF1E293B),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.barcode != null && item.barcode!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Barcode: ${item.barcode}',
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        if (item.note != null && item.note!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Catatan: ${item.note}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade700,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          '${DateHelper.formatEpochMs(item.createdAtEpochMs)}'
                                          '${item.userName != null && item.userName!.isNotEmpty ? " • Petugas: ${item.userName}" : ""}',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.grey.shade500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Badge Kuantitas Delta
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isIn ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isIn ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3),
                                      ),
                                    ),
                                    child: Text(
                                      '${isIn ? "+" : ""}${item.quantityDelta} unit',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isIn ? const Color(0xFF047857) : const Color(0xFFBE123C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.5,
              color: textColor.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        if (_selectedFilter != value) {
          setState(() {
            _selectedFilter = value;
          });
          _loadMutations();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
