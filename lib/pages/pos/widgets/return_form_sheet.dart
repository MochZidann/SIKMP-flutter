import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/barcode_scanner_sheet.dart';
import '../../../services/return_service.dart';

class ReturnFormSheet extends StatefulWidget {
  final VoidCallback onReturnSuccess;

  const ReturnFormSheet({super.key, required this.onReturnSuccess});

  static Future<void> show(BuildContext context, {required VoidCallback onReturnSuccess}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReturnFormSheet(onReturnSuccess: onReturnSuccess),
    );
  }

  @override
  State<ReturnFormSheet> createState() => _ReturnFormSheetState();
}

class _ReturnFormSheetState extends State<ReturnFormSheet> {
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isSearching = false;
  bool _isSubmitting = false;
  String? _searchError;

  Map<String, dynamic>? _saleData;
  Map<String, dynamic>? _policyInfo;
  List<dynamic> _itemsData = [];

  // State retur per item
  final Map<int, bool> _selectedItems = {};
  final Map<int, int> _itemQuantities = {};
  final Map<int, String> _itemConditions = {}; // 'RUSAK', 'KADALUARSA', 'LAYAK_JUAL'
  final Map<int, String> _itemNotes = {};

  String _reason = 'RUSAK'; // 'RUSAK', 'KADALUARSA', 'SALAH_BELI', 'LAINNYA'
  String _actionType = 'REFUND_CASH'; // 'REFUND_CASH', 'REPLACE_ITEM'

  @override
  void dispose() {
    _queryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _saleData = null;
      _policyInfo = null;
      _itemsData = [];
      _selectedItems.clear();
      _itemQuantities.clear();
      _itemConditions.clear();
      _itemNotes.clear();
    });

    final res = await ReturnService().searchSale(q);

    if (mounted) {
      setState(() {
        _isSearching = false;
        if (res['success'] == true) {
          _saleData = res['sale'];
          _policyInfo = res['policy_info'];
          _itemsData = res['items'] as List? ?? [];

          // Pre-populate items
          for (final item in _itemsData) {
            final saleItemId = item['sale_item_id'] as int;
            final returnableQty = item['returnable_quantity'] as int? ?? 0;
            _selectedItems[saleItemId] = false;
            _itemQuantities[saleItemId] = returnableQty > 0 ? 1 : 0;
            _itemConditions[saleItemId] = 'RUSAK';
          }
        } else {
          _searchError = res['message'] ?? 'Nota belanja tidak ditemukan.';
        }
      });
    }
  }

  Future<void> _scanBarcode() async {
    HapticFeedback.mediumImpact();
    await BarcodeScannerSheet.show(
      context,
      title: 'Scan Barcode Struk Nota',
      isContinuous: false,
      onScanned: (scannedCode) async {
        _queryController.text = scannedCode;
        await _doSearch(scannedCode);
        return 'Nota ditemukan: $scannedCode';
      },
    );
  }

  int get _calculatedRefund {
    int total = 0;
    for (final item in _itemsData) {
      final id = item['sale_item_id'] as int;
      if (_selectedItems[id] == true) {
        final qty = _itemQuantities[id] ?? 1;
        final unitPrice = item['unit_price'] as int? ?? 0;
        total += unitPrice * qty;
      }
    }
    return total;
  }

  int get _selectedItemCount {
    return _selectedItems.values.where((v) => v).length;
  }

  Future<void> _submitReturn() async {
    if (_saleData == null) return;

    if (_policyInfo?['is_strict_blocked'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi sudah lebih dari 30 hari, retur ditolak oleh sistem.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedItemCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu barang yang ingin diretur.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Cek catatan jika lewat batas normal
    if (_policyInfo?['is_over_normal_policy'] == true && _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi > 3 hari lalu. Alasan / Catatan pengawas wajib diisi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final returnItems = <Map<String, dynamic>>[];
    for (final item in _itemsData) {
      final id = item['sale_item_id'] as int;
      if (_selectedItems[id] == true) {
        final qty = _itemQuantities[id] ?? 1;
        final condition = _itemConditions[id] ?? 'RUSAK';
        final note = _itemNotes[id];

        returnItems.add({
          'sale_item_id': id,
          'quantity': qty,
          'condition': condition,
          'note': note,
        });
      }
    }

    setState(() => _isSubmitting = true);

    final res = await ReturnService().createReturn(
      saleId: _saleData!['id'] as int,
      reason: _reason,
      actionType: _actionType,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      items: returnItems,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res['success'] == true) {
        Navigator.pop(context);
        widget.onReturnSuccess();

        final returnNo = res['data']?['return_no'] ?? '';
        final pointsDeducted = res['points_deducted'] ?? 0;
        var msg = 'Retur $returnNo berhasil diproses.';
        if (pointsDeducted > 0) {
          msg += ' Poin member disesuaikan (-$pointsDeducted poin).';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFF047857),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal memproses retur.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryKasir = Color(0xFFD32F2F);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryKasir.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_return_rounded, color: primaryKasir, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retur Penjualan Kasir',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    Text(
                      'Pengembalian barang atau komplain dari pembeli',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── STEP 1: PENCARIAN NOTA ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _doSearch,
                  decoration: InputDecoration(
                    hintText: 'No. Transaksi (contoh: TRX-2026...)',
                    hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.receipt_long_rounded, size: 20, color: Color(0xFF9E9E9E)),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: 'Scan Barcode Struk Nota',
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                onPressed: _isSearching ? null : _scanBarcode,
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryKasir,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSearching ? null : () => _doSearch(_queryController.text),
                child: _isSearching
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Cari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),

          if (_searchError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _searchError!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── ISI DATA TRANSAKSI & PILIH ITEM ────────────────────────────
          Expanded(
            child: _saleData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'Cari nomor transaksi nota atau scan barcode struk\nuntuk memulai retur barang.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),

                        // Card Nota & Customer
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _saleData!['transactionId'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF111827)),
                                  ),
                                  Text(
                                    _saleData!['created_at'] ?? '-',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF6B7280)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_saleData!['customer_name']}  •  Kasir: ${_saleData!['cashier_name']}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                                  ),
                                ],
                              ),
                              if ((_saleData!['points_earned'] ?? 0) > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFD97706)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Mendapat ${_saleData!['points_earned']} Poin Member (akan disesuaikan proporsional saat refund)',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Kebijakan Garansi Alert
                        _buildPolicyBanner(),
                        const SizedBox(height: 14),

                        // Pilih Item Diretur
                        const Text(
                          'Pilih Produk yang Diretur',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 8),

                        ..._itemsData.map((item) {
                          final saleItemId = item['sale_item_id'] as int;
                          final productName = item['product_name']?.toString() ?? 'Barang';
                          final unitPrice = item['unit_price'] as int? ?? 0;
                          final returnableQty = item['returnable_quantity'] as int? ?? 0;
                          final isSelected = _selectedItems[saleItemId] == true;
                          final currentQty = _itemQuantities[saleItemId] ?? 1;

                          if (returnableQty <= 0) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF9CA3AF)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$productName (Seluruh kuantiti telah diretur sebelumnya)',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF), decoration: TextDecoration.lineThrough),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primaryKasir : const Color(0xFFE5E7EB),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      activeColor: primaryKasir,
                                      onChanged: (v) {
                                        setState(() => _selectedItems[saleItemId] = v ?? false);
                                      },
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            productName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                                          ),
                                          Text(
                                            '${CurrencyHelper.formatRupiah(unitPrice)}  •  Bisa diretur: $returnableQty unit',
                                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 8),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      // Kuantiti Counter
                                      const Text('Jumlah: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFFE5E7EB)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: currentQty > 1
                                                  ? () => setState(() => _itemQuantities[saleItemId] = currentQty - 1)
                                                  : null,
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.remove, size: 16),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$currentQty',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: currentQty < returnableQty
                                                  ? () => setState(() => _itemQuantities[saleItemId] = currentQty + 1)
                                                  : null,
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.add, size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Subtotal: ${CurrencyHelper.formatRupiah(unitPrice * currentQty)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: primaryKasir),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Kondisi Produk
                                  Row(
                                    children: [
                                      const Text('Kondisi: ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _itemConditions[saleItemId] ?? 'RUSAK',
                                          isDense: true,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'RUSAK', child: Text('Barang Rusak / Cacat', style: TextStyle(fontSize: 11.5))),
                                            DropdownMenuItem(value: 'KADALUARSA', child: Text('Kadaluarsa', style: TextStyle(fontSize: 11.5))),
                                            DropdownMenuItem(value: 'LAYAK_JUAL', child: Text('Layak Jual (Bagus)', style: TextStyle(fontSize: 11.5))),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) setState(() => _itemConditions[saleItemId] = val);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 12),

                        // Form Opsi Retur Global
                        const Text(
                          'Pilihan Penyelesaian Retur',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildChoiceRadio(
                                title: 'Refund Uang Tunai',
                                value: 'REFUND_CASH',
                                groupValue: _actionType,
                                onChanged: (v) => setState(() => _actionType = v!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildChoiceRadio(
                                title: 'Tukar Barang',
                                value: 'REPLACE_ITEM',
                                groupValue: _actionType,
                                onChanged: (v) => setState(() => _actionType = v!),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Text(
                          'Alasan Retur',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _reason,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'RUSAK', child: Text('Barang Rusak / Cacat Fisik')),
                            DropdownMenuItem(value: 'KADALUARSA', child: Text('Kadaluarsa / Expired')),
                            DropdownMenuItem(value: 'SALAH_BELI', child: Text('Salah Beli Pelanggan')),
                            DropdownMenuItem(value: 'LAINNYA', child: Text('Alasan Lainnya')),
                          ],
                          onChanged: (v) => setState(() => _reason = v ?? 'RUSAK'),
                        ),

                        const SizedBox(height: 10),
                        const Text(
                          'Catatan Retur / Persetujuan Supervisor',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _noteController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Kemasan bocor saat dibuka pelanggan, disetujui kasir...',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),

          // ── BOTTOM SUMMARY & SUBMIT ───────────────────────────────────
          if (_saleData != null) ...[
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_selectedItemCount Item Dipilih',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                    ),
                    Text(
                      _actionType == 'REFUND_CASH'
                          ? CurrencyHelper.formatRupiah(_calculatedRefund)
                          : 'Tukar Barang',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryKasir),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryKasir,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: (_isSubmitting || _selectedItemCount == 0 || _policyInfo?['is_strict_blocked'] == true)
                      ? null
                      : _submitReturn,
                  child: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Proses Retur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPolicyBanner() {
    final info = _policyInfo;
    if (info == null) return const SizedBox.shrink();

    final isStrict = info['is_strict_blocked'] == true;
    final isOver = info['is_over_normal_policy'] == true;
    final msg = info['policy_message']?.toString() ?? '';

    Color bgColor = const Color(0xFFECFDF5);
    Color borderColor = const Color(0xFFA7F3D0);
    Color textColor = const Color(0xFF065F46);
    IconData icon = Icons.verified_rounded;

    if (isStrict) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      textColor = const Color(0xFF991B1B);
      icon = Icons.block_rounded;
    } else if (isOver) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      textColor = const Color(0xFF92400E);
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(fontSize: 11.5, color: textColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceRadio({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFD32F2F) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: const Color(0xFFD32F2F),
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFFD32F2F) : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
