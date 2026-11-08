import 'package:flutter/material.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../models/stock_movement.dart';
import '../../../services/gudang_service.dart';

class GudangInboundTab extends StatefulWidget {
  const GudangInboundTab({super.key});

  @override
  State<GudangInboundTab> createState() => _GudangInboundTabState();
}

class _GudangInboundTabState extends State<GudangInboundTab> {
  final GudangService _gudangService = GudangService();
  List<StockMovement> _movements = [];
  bool _isLoading = true;
  String _selectedType = 'ALL'; // 'ALL', 'IN', 'OUT', 'ADJUST'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    setState(() => _isLoading = true);
    final moves = await _gudangService.getStockMovements();
    if (mounted) {
      setState(() {
        _movements = moves;
        _isLoading = false;
      });
    }
  }

  List<StockMovement> get _filteredMovements {
    return _movements.where((m) {
      final matchesType = _selectedType == 'ALL' || m.type.toUpperCase() == _selectedType;
      if (!matchesType) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final pName = (m.productName ?? '').toLowerCase();
      final sName = (m.supplierName ?? '').toLowerCase();
      final note = (m.note ?? '').toLowerCase();
      final ref = (m.referenceNo ?? '').toLowerCase();

      return pName.contains(q) || sName.contains(q) || note.contains(q) || ref.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // ── SEARCH BAR & FILTER MUTASI ────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Cari produk, supplier, atau nomor dokumen...',
                    hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9E9E9E)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua Mutasi', 'ALL', const Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Masuk (IN)', 'IN', Colors.green.shade700),
                      const SizedBox(width: 8),
                      _buildFilterChip('Keluar / Retur (OUT)', 'OUT', Colors.red.shade700),
                      const SizedBox(width: 8),
                      _buildFilterChip('Opname (ADJUST)', 'ADJUST', Colors.blueGrey.shade700),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── DAFTAR MUTASI STOK ─────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    itemBuilder: (_, _) => const SkeletonTransactionTile(),
                  )
                : _filteredMovements.isEmpty
                    ? EmptyDataView(
                        icon: Icons.swap_vert_rounded,
                        title: 'Riwayat Mutasi Kosong',
                        subtitle: 'Pencatatan barang masuk, keluar, atau penyesuaian stok akan muncul di sini.',
                        actionLabel: 'Muat Ulang',
                        onAction: _loadMovements,
                      )
                    : RefreshIndicator(
                        color: const Color(0xFFE65100),
                        onRefresh: _loadMovements,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredMovements.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final move = _filteredMovements[index];
                            final isIn = move.isIn;
                            final isAdjust = move.isAdjust;

                            return Container(
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
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isIn
                                        ? Colors.green.shade50
                                        : isAdjust
                                            ? Colors.blueGrey.shade50
                                            : Colors.red.shade50,
                                    child: Icon(
                                      isIn
                                          ? Icons.arrow_downward_rounded
                                          : isAdjust
                                              ? Icons.tune_rounded
                                              : Icons.arrow_upward_rounded,
                                      color: isIn
                                          ? Colors.green.shade700
                                          : isAdjust
                                              ? Colors.blueGrey.shade700
                                              : Colors.red.shade700,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                move.productName ?? 'Produk ID #${move.productId}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              move.quantityDelta >= 0 ? '+${move.quantityDelta}' : '${move.quantityDelta}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                                color: isIn
                                                    ? Colors.green.shade800
                                                    : isAdjust
                                                        ? Colors.blueGrey.shade800
                                                        : Colors.red.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          move.note ?? (isIn ? 'Pemasukan stok' : 'Koreksi stok opname'),
                                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                        ),
                                        if (move.supplierName != null && move.supplierName!.isNotEmpty) ...[
                                          const SizedBox(height: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F4F6),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFE5E7EB)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.business_outlined, size: 11, color: Color(0xFF4B5563)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  move.supplierName!,
                                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (move.referenceNo != null && move.referenceNo!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Ref: ${move.referenceNo}',
                                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                        const SizedBox(height: 5),
                                        Text(
                                          DateHelper.formatEpochMs(move.createdAtEpochMs),
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                        ),
                                      ],
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

  Widget _buildFilterChip(String label, String value, Color activeColor) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: activeColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF333333)),
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) => setState(() => _selectedType = value),
    );
  }
}
