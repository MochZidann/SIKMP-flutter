import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';

class PosReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(dynamic productId)? getProductName;

  const PosReceiptDialog({
    super.key,
    required this.data,
    this.getProductName,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> data,
    String Function(dynamic productId)? getProductName,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PosReceiptDialog(
        data: data,
        getProductName: getProductName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txId = data['transactionId'] ?? 'TRX-SUCCESS';
    final total = data['total'] ?? 0;
    final items = data['items'] as List? ?? [];
    final paymentMethod = data['paymentMethod'] ?? 'QRIS';
    final amountPaid = data['amountPaid'] ?? total;
    final change = data['change'] ?? 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Centang Hijau Besar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2E7D32),
              size: 54,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pembayaran Berhasil!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            paymentMethod == 'TUNAI'
                ? 'Uang Tunai Telah Diterima Kasir'
                : 'Status Settlement Dikonfirmasi Midtrans',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Rincian Struk Singkat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildReceiptRow('No. Transaksi', txId.toString()),
                const Divider(height: 14),
                _buildReceiptRow(
                  'Metode Bayar',
                  paymentMethod == 'TUNAI' ? 'Tunai (Cash)' : 'QRIS Dynamic',
                ),
                const Divider(height: 14),
                if (items.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Item Belanja (${items.length}):',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...items.take(3).map((it) {
                    final pName = it['productName'] ??
                        (getProductName != null
                            ? getProductName!(it['productId'])
                            : 'Produk #${it['productId']}');
                    final pQty = it['quantity'] ?? it['qty'] ?? 1;
                    final pTotal = it['lineTotal'] ?? ((it['price'] ?? 0) * pQty);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$pName x$pQty',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formatRupiah(pTotal),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (items.length > 3)
                    Text(
                      '+ ${items.length - 3} item lainnya',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  const Divider(height: 14),
                ],
                _buildReceiptRow(
                  'Total Tagihan',
                  formatRupiah(total),
                  isBold: true,
                  color: const Color(0xFF2B2B2B),
                ),
                if (paymentMethod == 'TUNAI') ...[
                  const Divider(height: 14),
                  _buildReceiptRow(
                    'Uang Diterima',
                    formatRupiah(amountPaid),
                  ),
                  const Divider(height: 14),
                  _buildReceiptRow(
                    'Kembalian',
                    formatRupiah(change),
                    isBold: true,
                    color: const Color(0xFF2E7D32),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Tindakan
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menghubungkan ke Printer Bluetooth...'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text('Cetak'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? const Color(0xFF2B2B2B),
          ),
        ),
      ],
    );
  }
}
