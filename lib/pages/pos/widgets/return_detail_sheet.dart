import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/sale_return.dart';

class ReturnDetailSheet extends StatelessWidget {
  final SaleReturnModel returnItem;

  const ReturnDetailSheet({super.key, required this.returnItem});

  static Future<void> show(BuildContext context, {required SaleReturnModel returnItem}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReturnDetailSheet(returnItem: returnItem),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryKasir = Color(0xFFD32F2F);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                child: const Icon(Icons.receipt_long_rounded, color: primaryKasir, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      returnItem.returnNo,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    Text(
                      'Ref Transaksi: ${returnItem.transactionId}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
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
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 14),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Box Kasir & Pembeli
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Tanggal & Jam Retur', returnItem.createdAtFormatted ?? '-'),
                        const SizedBox(height: 6),
                        _buildRow('Kasir Bertugas', returnItem.cashierName),
                        const SizedBox(height: 6),
                        _buildRow('Nama Pelanggan', returnItem.customerName),
                        const SizedBox(height: 6),
                        _buildRow('Alasan Retur', returnItem.reasonLabel),
                        const SizedBox(height: 6),
                        _buildRow('Penyelesaian', returnItem.actionTypeLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Daftar Produk Diretur
                  const Text(
                    'Rincian Produk Diretur',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 8),

                  ...returnItem.items.map((item) {
                    final isRusak = item.condition == 'RUSAK';
                    final isExpired = item.condition == 'KADALUARSA';

                    final badgeColor = isRusak
                        ? const Color(0xFFFEF2F2)
                        : isExpired
                            ? const Color(0xFFFFFBEB)
                            : const Color(0xFFECFDF5);
                    final badgeTextColor = isRusak
                        ? const Color(0xFF991B1B)
                        : isExpired
                            ? const Color(0xFF92400E)
                            : const Color(0xFF065F46);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                                ),
                              ),
                              Text(
                                CurrencyHelper.formatRupiah(item.subtotal),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryKasir),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${item.quantity} unit x ${CurrencyHelper.formatRupiah(item.unitPrice)}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.conditionLabel,
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: badgeTextColor),
                                ),
                              ),
                            ],
                          ),
                          if (item.supplierName != null && item.supplierName!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Mitra Supplier: ${item.supplierName}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  if (returnItem.note != null && returnItem.note!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Catatan / Alasan Khusus Supervisor',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        returnItem.note!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Total Refund Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pengembalian (Refund):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF881337)),
                ),
                Text(
                  returnItem.actionType == 'REFUND_CASH'
                      ? CurrencyHelper.formatRupiah(returnItem.totalRefund)
                      : 'Tukar Barang',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: primaryKasir),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
      ],
    );
  }
}
