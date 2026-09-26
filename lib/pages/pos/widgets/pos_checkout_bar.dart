import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';

class PosCheckoutBar extends StatelessWidget {
  final int total;
  final int totalItems;
  final int productCount;
  final bool isBusy;
  final bool isProcessingCash;
  final bool isGeneratingQris;
  final bool isEmbedded;
  final VoidCallback onOpenCart;
  final VoidCallback onCashPayment;
  final VoidCallback onQrisPayment;

  const PosCheckoutBar({
    super.key,
    required this.total,
    required this.totalItems,
    required this.productCount,
    required this.isBusy,
    required this.isProcessingCash,
    required this.isGeneratingQris,
    this.isEmbedded = false,
    required this.onOpenCart,
    required this.onCashPayment,
    required this.onQrisPayment,
  });

  @override
  Widget build(BuildContext context) {
    final isValid = total >= 1000;

    // Tampilan bila keranjang masih kosong
    if (totalItems <= 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: isEmbedded ? 14 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Keranjang Masih Kosong',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF444444)),
                      ),
                      Text(
                        'Sentuh produk di atas untuk memilih item',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Rp 0',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Tampilan bila keranjang ada isinya
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, isEmbedded ? 22 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Baris Info Ringkasan Total & Tombol Buka Keranjang
            InkWell(
              onTap: onOpenCart,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD32F2F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_cart_rounded, size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalItems Item ($productCount Produk)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD32F2F),
                              ),
                            ),
                            const Row(
                              children: [
                                Text(
                                  'Sentuh untuk rincian',
                                  style: TextStyle(fontSize: 10, color: Color(0xFFD32F2F)),
                                ),
                                Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: Color(0xFFD32F2F)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      formatRupiah(total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Baris Tombol Pembayaran: CASH & QR
            Row(
              children: [
                // Tombol 1: Bayar Cash (Tunai)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (!isValid || isBusy) ? null : onCashPayment,
                    icon: isProcessingCash
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.payments_rounded, size: 18),
                    label: Text(
                      isProcessingCash ? 'Memproses...' : 'Bayar Cash',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Tombol 2: Bayar QR (QRIS Midtrans)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (!isValid || isBusy) ? null : onQrisPayment,
                    icon: isGeneratingQris
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: Text(
                      isGeneratingQris ? 'Membuat QR...' : 'Bayar QR',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
