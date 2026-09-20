import 'package:flutter/material.dart';
import '../../../core/utils/date_helper.dart';
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
  String _selectedType = 'ALL'; // 'ALL', 'IN', 'ADJUST', 'OUT'

  @override
  void initState() {
    super.initState();
    _loadMovements();
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
    if (_selectedType == 'ALL') return _movements;
    return _movements.where((m) => m.type.toUpperCase() == _selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // ── FILTER TIPE MUTASI ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                ChoiceChip(
                  showCheckmark: false,
                  label: const Text('Semua Mutasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _selectedType == 'ALL',
                  selectedColor: const Color(0xFFE65100),
                  labelStyle: TextStyle(color: _selectedType == 'ALL' ? Colors.white : const Color(0xFF333333)),
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (_) => setState(() => _selectedType = 'ALL'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  showCheckmark: false,
                  label: const Text('Masuk (IN)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _selectedType == 'IN',
                  selectedColor: Colors.green.shade700,
                  labelStyle: TextStyle(color: _selectedType == 'IN' ? Colors.white : const Color(0xFF333333)),
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (_) => setState(() => _selectedType = 'IN'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  showCheckmark: false,
                  label: const Text('Opname (ADJUST)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _selectedType == 'ADJUST',
                  selectedColor: Colors.blueGrey.shade700,
                  labelStyle: TextStyle(color: _selectedType == 'ADJUST' ? Colors.white : const Color(0xFF333333)),
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (_) => setState(() => _selectedType = 'ADJUST'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── DAFTAR MUTASI ──────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
                : _filteredMovements.isEmpty
                    ? EmptyDataView(
                        icon: Icons.swap_vert_rounded,
                        title: 'Riwayat Mutasi Kosong',
                        subtitle: 'Pencatatan barang masuk atau penyesuaian stok akan muncul di sini.',
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
                                            Text(
                                              'Produk ID #${move.productId}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                                        const SizedBox(height: 2),
                                        Text(
                                          move.note ?? (isIn ? 'Pemasukan stok' : 'Koreksi stok opname'),
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 4),
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
}
