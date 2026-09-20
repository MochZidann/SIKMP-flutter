import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/pos_service.dart';

class CashPaymentBottomSheet extends StatefulWidget {
  final int finalAmount;
  final List<Map<String, dynamic>>? itemsPayload;
  final Function(Map<String, dynamic> receiptData) onSuccess;
  final Function(String message) onError;

  const CashPaymentBottomSheet({
    super.key,
    required this.finalAmount,
    required this.itemsPayload,
    required this.onSuccess,
    required this.onError,
  });

  static Future<void> show(
    BuildContext context, {
    required int finalAmount,
    required List<Map<String, dynamic>>? itemsPayload,
    required Function(Map<String, dynamic> receiptData) onSuccess,
    required Function(String message) onError,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => CashPaymentBottomSheet(
        finalAmount: finalAmount,
        itemsPayload: itemsPayload,
        onSuccess: onSuccess,
        onError: onError,
      ),
    );
  }

  @override
  State<CashPaymentBottomSheet> createState() => _CashPaymentBottomSheetState();
}

class _CashPaymentBottomSheetState extends State<CashPaymentBottomSheet> {
  late int _cashReceived;
  late final TextEditingController _cashController;
  late final List<int> _sortedSuggestions;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cashReceived = widget.finalAmount;
    _cashController = TextEditingController(text: widget.finalAmount.toString());

    // Rekomendasi pecahan uang tunai
    final suggestions = <int>{widget.finalAmount}; // Uang Pas
    const denominations = [5000, 10000, 20000, 50000, 100000];
    for (final d in denominations) {
      if (d > widget.finalAmount) suggestions.add(d);
    }
    final next5k = ((widget.finalAmount + 4999) ~/ 5000) * 5000;
    if (next5k > widget.finalAmount) suggestions.add(next5k);
    final next10k = ((widget.finalAmount + 9999) ~/ 10000) * 10000;
    if (next10k > widget.finalAmount) suggestions.add(next10k);
    final next50k = ((widget.finalAmount + 49999) ~/ 50000) * 50000;
    if (next50k > widget.finalAmount) suggestions.add(next50k);
    final next100k = ((widget.finalAmount + 99999) ~/ 100000) * 100000;
    if (next100k > widget.finalAmount) suggestions.add(next100k);

    _sortedSuggestions = suggestions.toList()..sort();
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _processCheckout() async {
    setState(() => _isProcessing = true);
    final change = _cashReceived - widget.finalAmount;

    try {
      final result = await PosService().checkoutTunai(
        items: widget.itemsPayload,
        amount: widget.itemsPayload == null ? widget.finalAmount : null,
        amountPaid: _cashReceived,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.pop(context);
        final receiptData = {
          'transactionId': result['transactionId'] ?? 'TRX-CASH',
          'total': widget.finalAmount,
          'paymentMethod': 'TUNAI',
          'amountPaid': _cashReceived,
          'change': change,
          'items': result['items'] ?? widget.itemsPayload ?? [],
        };
        widget.onSuccess(receiptData);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        widget.onError('Gagal memproses transaksi tunai: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final change = _cashReceived - widget.finalAmount;
    final isSufficient = change >= 0;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payments_rounded, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pembayaran Cash / Tunai',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                      Text(
                        'Terima uang fisik dari pelanggan',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Total Tagihan Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Tagihan',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Text(
                    formatRupiah(widget.finalAmount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input Uang Diterima
            const Text(
              'Uang Tunai Diterima (Rp)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.money_rounded, color: Color(0xFF2E7D32)),
                hintText: '0',
                filled: true,
                fillColor: Colors.green.shade50.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _cashReceived = int.tryParse(val) ?? 0;
                });
              },
            ),
            const SizedBox(height: 12),

            // Rekomendasi Pecahan Uang Cepat
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sortedSuggestions.map((amt) {
                final isExact = amt == widget.finalAmount;
                final isSelected = _cashReceived == amt;
                return ChoiceChip(
                  showCheckmark: false,
                  label: Text(
                    isExact ? 'Uang Pas (${formatRupiah(amt)})' : formatRupiah(amt),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF2B2B2B),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2E7D32),
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (_) {
                    setState(() {
                      _cashReceived = amt;
                      _cashController.text = amt.toString();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Card Kembalian
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSufficient ? Colors.green.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSufficient ? Colors.green.shade200 : Colors.amber.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSufficient ? Icons.change_circle_outlined : Icons.warning_amber_rounded,
                        color: isSufficient ? const Color(0xFF2E7D32) : Colors.amber.shade900,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSufficient ? 'Kembalian:' : 'Uang Masih Kurang:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSufficient ? const Color(0xFF2E7D32) : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formatRupiah(change.abs()),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isSufficient ? const Color(0xFF2E7D32) : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Selesaikan Transaksi Tunai
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (!isSufficient || _isProcessing) ? null : _processCheckout,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  _isProcessing ? 'Memproses Transaksi...' : 'Konfirmasi Pembayaran Cash',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
