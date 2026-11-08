import 'package:flutter/material.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../models/supplier.dart';
import '../../../models/supplier_mutation.dart';
import '../../../services/supplier_service.dart';

class SupplierMutationsDialog extends StatefulWidget {
  final Supplier supplier;

  const SupplierMutationsDialog({super.key, required this.supplier});

  static Future<void> show(BuildContext context, {required Supplier supplier}) {
    return showDialog(
      context: context,
      builder: (ctx) => SupplierMutationsDialog(supplier: supplier),
    );
  }

  @override
  State<SupplierMutationsDialog> createState() => _SupplierMutationsDialogState();
}

class _SupplierMutationsDialogState extends State<SupplierMutationsDialog> {
  final SupplierService _supplierService = SupplierService();
  String _selectedFilter = 'ALL'; // ALL, IN, OUT
  bool _isLoading = true;
  List<SupplierMutation> _mutations = [];
  Map<String, dynamic> _summary = {'totalIn': 0, 'totalOut': 0, 'net': 0};

  @override
  void initState() {
    super.initState();
    _loadMutations();
  }

  Future<void> _loadMutations() async {
    setState(() => _isLoading = true);
    final result = await _supplierService.getSupplierMutations(
      widget.supplier.id,
      type: _selectedFilter == 'ALL' ? null : _selectedFilter,
    );

    if (mounted) {
      setState(() {
        _mutations = (result['mutations'] as List<SupplierMutation>?) ?? [];
        _summary = (result['summary'] as Map<String, dynamic>?) ?? {
          'totalIn': 0,
          'totalOut': 0,
          'net': 0,
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);

    final totalIn = _summary['totalIn'] ?? 0;
    final totalOut = _summary['totalOut'] ?? 0;
    final net = _summary['net'] ?? (totalIn - totalOut);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Column(
          children: [
            // ── TOP HEADER (BERSIH & PROFESIONAL TEMA GUDANG) ───────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.history_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.supplier.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            if (widget.supplier.contactPerson != null && widget.supplier.contactPerson!.isNotEmpty)
                              Text(
                                'PIC: ${widget.supplier.contactPerson}  •  Telp: ${widget.supplier.phone ?? "-"}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF94A3B8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── 3 KOTAK KPI RINGKASAN REKANAN ──────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderKpi(
                          label: 'TOTAL MASUK',
                          value: '+$totalIn',
                          sub: 'Barang pasokan',
                          color: const Color(0xFF34D399),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHeaderKpi(
                          label: 'TOTAL RETUR',
                          value: '-$totalOut',
                          sub: 'Dikembalikan',
                          color: const Color(0xFFFB7185),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHeaderKpi(
                          label: 'NETTO PASOKAN',
                          value: '${net >= 0 ? "+" : ""}$net',
                          sub: 'Saldo di gudang',
                          color: Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── FILTER TAB BAR (SEMUA, MASUK, RETUR) ────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  _buildFilterChip('Semua Transaksi', 'ALL', primaryColor),
                  const SizedBox(width: 8),
                  _buildFilterChip('Masuk (IN)', 'IN', const Color(0xFF059669)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Retur (OUT)', 'OUT', const Color(0xFFE11D48)),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── DAFTAR RIWAYAT MUTASI DENGAN ZERO OVERFLOW ──────────────
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 4,
                      itemBuilder: (_, _) => const SkeletonProductTile(),
                    )
                  : _mutations.isEmpty
                      ? EmptyDataView(
                          icon: Icons.history_rounded,
                          title: 'Belum Ada Riwayat Mutasi',
                          subtitle: 'Belum ada transaksi barang masuk atau retur untuk supplier ini.',
                          actionLabel: 'Muat Ulang',
                          onAction: _loadMutations,
                        )
                      : RefreshIndicator(
                          color: primaryColor,
                          onRefresh: _loadMutations,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _mutations.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _mutations[index];
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
                                        size: 16,
                                        color: isIn ? const Color(0xFF059669) : const Color(0xFFE11D48),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Detail mutasi barang
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
                                            maxLines: 1,
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
                                                color: Colors.grey.shade600,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          // Baris tanggal & petugas yang tidak akan overflow
                                          Text(
                                            '${DateHelper.formatEpochMs(item.createdAtEpochMs)}'
                                            '${item.userName != null && item.userName!.isNotEmpty ? " • Petugas: ${item.userName}" : ""}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade400,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Badge kuantitas delta
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                                          fontSize: 11.5,
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
      ),
    );
  }

  Widget _buildHeaderKpi({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color activeColor) {
    final isSelected = _selectedFilter == value;

    return InkWell(
      onTap: () {
        if (_selectedFilter != value) {
          setState(() => _selectedFilter = value);
          _loadMutations();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
