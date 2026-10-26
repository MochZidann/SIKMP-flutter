import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/sale_record.dart';
import '../../../services/return_service.dart';

class PosReturnDialog extends StatefulWidget {
  final SaleRecord sale;
  final VoidCallback? onReturnSuccess;

  const PosReturnDialog({super.key, required this.sale, this.onReturnSuccess});

  static Future<void> show(
    BuildContext context, {
    required SaleRecord sale,
    VoidCallback? onReturnSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          PosReturnDialog(sale: sale, onReturnSuccess: onReturnSuccess),
    );
  }

  @override
  State<PosReturnDialog> createState() => _PosReturnDialogState();
}

class _PosReturnDialogState extends State<PosReturnDialog> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _summary;

  // Key: sale_item_id, Value: return quantity
  final Map<int, int> _returnQuantities = {};
  // Key: sale_item_id, Value: condition ('GOOD' or 'DAMAGED')
  final Map<int, String> _itemConditions = {};

  final _reasonController = TextEditingController(
    text: 'Barang rusak / salah beli',
  );
  final _noteController = TextEditingController();
  final String _refundMethod = 'CASH';

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    setState(() => _isLoading = true);
    final data = await ReturnService().getSaleReturnableSummary(widget.sale.id);
    if (mounted) {
      setState(() {
        _summary = data;
        _isLoading = false;

        if (data != null && data['items'] is List) {
          for (final item in data['items']) {
            final id = item['sale_item_id'] as int? ?? 0;
            _returnQuantities[id] = 0;
            _itemConditions[id] = 'GOOD';
          }
        }
      });
    }
  }

  int get _totalReturnItems {
    return _returnQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  int get _totalRefundAmount {
    if (_summary == null || _summary!['items'] is! List) return 0;
    int total = 0;
    for (final item in _summary!['items']) {
      final id = item['sale_item_id'] as int? ?? 0;
      final qty = _returnQuantities[id] ?? 0;
      final budget = (item['refund_budget'] as num?)?.toInt() ?? 0;
      final sold = (item['quantity_sold'] as num?)?.toInt() ?? 0;
      final returned = (item['quantity_returned'] as num?)?.toInt() ?? 0;
      if (sold > 0) {
        total += budget * (returned + qty) ~/ sold - budget * returned ~/ sold;
      }
    }
    return total;
  }

  Future<void> _submitReturn() async {
    if (_isSubmitting) return;
    if (_totalReturnItems <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 barang untuk diretur'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final itemsToReturn = <Map<String, dynamic>>[];
    for (final entry in _returnQuantities.entries) {
      if (entry.value > 0) {
        itemsToReturn.add({
          'sale_item_id': entry.key,
          'quantity': entry.value,
          'condition': _itemConditions[entry.key] ?? 'GOOD',
        });
      }
    }

    setState(() => _isSubmitting = true);

    final res = await ReturnService().createSaleReturn(
      saleId: widget.sale.id,
      items: itemsToReturn,
      refundMethod: _refundMethod,
      reason: _reasonController.text.trim().isEmpty
          ? 'Retur Penjualan'
          : _reasonController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res['success'] == true) {
        Navigator.pop(context);
        widget.onReturnSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ?? 'Retur penjualan berhasil diproses',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal memproses retur'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.assignment_return_rounded,
                          color: Colors.orange.shade800,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Formulir Retur Penjualan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            widget.sale.transactionId,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Content Body
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _summary == null || (_summary!['items'] as List).isEmpty
                    ? const Center(
                        child: Text(
                          'Informasi retur transaksi tidak ditemukan',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
                        children: [
                          // Member Info Banner (if applicable)
                          if (_summary!['member'] != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.card_membership_rounded,
                                    size: 18,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Anggota: ${_summary!['member']['name']} (${_summary!['member']['member_no']}) â€” Poin akan disesuaikan otomatis.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const Text(
                            'Pilih Barang yang Diretur:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          ...((_summary!['items'] as List).map((item) {
                            final itemId = item['sale_item_id'] as int? ?? 0;
                            final productName =
                                item['product_name'] ?? 'Produk';
                            final unitPrice =
                                (item['unit_price'] as num?)?.toInt() ?? 0;
                            final soldQty =
                                (item['quantity_sold'] as num?)?.toInt() ?? 0;
                            final returnedQty =
                                (item['quantity_returned'] as num?)?.toInt() ??
                                0;
                            final maxReturnable =
                                (item['quantity_returnable'] as num?)
                                    ?.toInt() ??
                                0;
                            final selectedQty = _returnQuantities[itemId] ?? 0;
                            final condition = _itemConditions[itemId] ?? 'GOOD';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedQty > 0
                                    ? Colors.orange.shade50.withValues(
                                        alpha: 0.5,
                                      )
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedQty > 0
                                      ? Colors.orange.shade300
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              productName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${formatRupiah(unitPrice)} | Terjual: $soldQty (Diretur: $returnedQty, Sisa: $maxReturnable)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Counter Qty
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 22,
                                            ),
                                            color: selectedQty > 0
                                                ? Colors.orange.shade800
                                                : Colors.grey.shade400,
                                            onPressed: selectedQty > 0
                                                ? () {
                                                    setState(() {
                                                      _returnQuantities[itemId] =
                                                          selectedQty - 1;
                                                    });
                                                  }
                                                : null,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Text(
                                              '$selectedQty',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 22,
                                            ),
                                            color: selectedQty < maxReturnable
                                                ? Colors.orange.shade800
                                                : Colors.grey.shade400,
                                            onPressed:
                                                selectedQty < maxReturnable
                                                ? () {
                                                    setState(() {
                                                      _returnQuantities[itemId] =
                                                          selectedQty + 1;
                                                    });
                                                  }
                                                : null,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Condition Selector when Qty > 0
                                  if (selectedQty > 0) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Text(
                                          'Kondisi: ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ChoiceChip(
                                          label: const Text('Bagus (Restock)'),
                                          selected: condition == 'GOOD',
                                          labelStyle: TextStyle(
                                            fontSize: 11,
                                            color: condition == 'GOOD'
                                                ? Colors.green.shade800
                                                : Colors.grey.shade700,
                                          ),
                                          selectedColor: Colors.green.shade100,
                                          backgroundColor: Colors.white,
                                          onSelected: (val) {
                                            if (val) {
                                              setState(
                                                () => _itemConditions[itemId] =
                                                    'GOOD',
                                              );
                                            }
                                          },
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        const SizedBox(width: 6),
                                        ChoiceChip(
                                          label: const Text(
                                            'Rusak (Karantina)',
                                          ),
                                          selected: condition == 'DAMAGED',
                                          labelStyle: TextStyle(
                                            fontSize: 11,
                                            color: condition == 'DAMAGED'
                                                ? Colors.red.shade800
                                                : Colors.grey.shade700,
                                          ),
                                          selectedColor: Colors.red.shade100,
                                          backgroundColor: Colors.white,
                                          onSelected: (val) {
                                            if (val) {
                                              setState(
                                                () => _itemConditions[itemId] =
                                                    'DAMAGED',
                                              );
                                            }
                                          },
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          })),

                          const SizedBox(height: 12),
                          // Reason & Notes
                          TextField(
                            controller: _reasonController,
                            decoration: InputDecoration(
                              labelText: 'Alasan Retur',
                              labelStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              labelText: 'Catatan Tambahan (Opsional)',
                              labelStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Footer: Total Refund & Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refund tunai setelah diskon ($_totalReturnItems item)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        formatRupiah(_totalRefundAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isSubmitting || _totalReturnItems <= 0
                        ? null
                        : _submitReturn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Proses Retur',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
