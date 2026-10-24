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
    const primaryColor = Color(0xFF7C3AED);

    final totalIn = _summary['totalIn'] ?? 0;
    final totalOut = _summary['totalOut'] ?? 0;
    final net = _summary['net'] ?? (totalIn - totalOut);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Column(
          children: [
            // ── TOP HEADER WITH PURPLE GRADIENT ────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF581C87), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (widget.supplier.code.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.supplier.code,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    widget.supplier.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PIC: ${widget.supplier.contactPerson ?? "-"} | Telp: ${widget.supplier.phone ?? "-"}',
                              style: TextStyle(
                                color: Colors.purple.shade100,
                                fontSize: 12,
                              ),
                            ),
                            if (widget.supplier.address != null && widget.supplier.address!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.supplier.address!,
                                style: TextStyle(
                                  color: Colors.purple.shade200,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── 3 SUMMARY METRIC BOXES ─────────────────────────
                  Row(
                    children: [
                      // Total Masuk
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL MASUK', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 9, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('+$totalIn', style: const TextStyle(color: Color(0xFF34D399), fontSize: 16, fontWeight: FontWeight.bold)),
                              const Text('Barang masuk', style: TextStyle(color: Colors.white70, fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Total Retur
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL RETUR', style: TextStyle(color: Color(0xFFFDA4AF), fontSize: 9, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('-$totalOut', style: const TextStyle(color: Color(0xFFFB7185), fontSize: 16, fontWeight: FontWeight.bold)),
                              const Text('Dikembalikan', style: TextStyle(color: Colors.white70, fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Netto
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('NETTO PASOKAN', style: TextStyle(color: Color(0xFFFDE68A), fontSize: 9, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                '${net >= 0 ? '+' : ''}$net',
                                style: TextStyle(
                                  color: net >= 0 ? const Color(0xFFFBBF24) : const Color(0xFFF87171),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Saldo di gudang', style: TextStyle(color: Colors.white70, fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── FILTER TABS ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  _buildFilterChip('Semua Transaksi', 'ALL'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Masuk (IN)', 'IN', activeColor: const Color(0xFF059669)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Retur (OUT)', 'OUT', activeColor: const Color(0xFFE11D48)),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── LIST OF MUTATIONS ────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: 4,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, _) => const SkeletonTransactionTile(),
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
                                    // IN/OUT Icon
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
                                        isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                        size: 18,
                                        color: isIn ? const Color(0xFF059669) : const Color(0xFFE11D48),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Mutation details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF1E293B),
                                            ),
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
                                            ),
                                          ],
                                          if (item.note != null && item.note!.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              'Catatan: ${item.note}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                DateHelper.formatEpochMs(item.createdAtEpochMs),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                              if (item.userName != null && item.userName!.isNotEmpty) ...[
                                                Text(' • ', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                                                Text(
                                                  'Petugas: ${item.userName}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Delta Quantity Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isIn ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                                        borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {Color activeColor = const Color(0xFF7C3AED)}) {
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
