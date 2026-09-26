import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/product_image_widget.dart';
import '../../../models/product.dart';

class PosCartBottomSheet extends StatefulWidget {
  final List<Product> products;
  final Map<int, int> cart;
  final VoidCallback onClearCart;
  final Function(Product product) onIncrement;
  final Function(Product product) onDecrement;
  final VoidCallback onCashPayment;
  final VoidCallback onQrisPayment;

  const PosCartBottomSheet({
    super.key,
    required this.products,
    required this.cart,
    required this.onClearCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onCashPayment,
    required this.onQrisPayment,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Product> products,
    required Map<int, int> cart,
    required VoidCallback onClearCart,
    required Function(Product product) onIncrement,
    required Function(Product product) onDecrement,
    required VoidCallback onCashPayment,
    required VoidCallback onQrisPayment,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => PosCartBottomSheet(
        products: products,
        cart: cart,
        onClearCart: onClearCart,
        onIncrement: onIncrement,
        onDecrement: onDecrement,
        onCashPayment: onCashPayment,
        onQrisPayment: onQrisPayment,
      ),
    );
  }

  @override
  State<PosCartBottomSheet> createState() => _PosCartBottomSheetState();
}

class _PosCartBottomSheetState extends State<PosCartBottomSheet> {
  int get _cartTotal {
    int total = 0;
    widget.cart.forEach((productId, qty) {
      final p = widget.products.firstWhere(
        (item) => item.id == productId,
        orElse: () => Product(
          id: productId,
          name: '',
          category: 'Umum',
          price: 0,
          stock: 0,
          barcode: '',
        ),
      );
      total += p.price * qty;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = widget.cart.entries.map((entry) {
      final p = widget.products.firstWhere(
        (it) => it.id == entry.key,
        orElse: () => Product(
          id: entry.key,
          name: 'Produk #${entry.key}',
          category: 'Umum',
          price: 0,
          stock: 0,
          barcode: '',
        ),
      );
      return {
        'product': p,
        'qty': entry.value,
        'lineTotal': p.price * entry.value,
      };
    }).toList();

    final total = _cartTotal;
    final totalCount = widget.cart.values.fold(0, (a, b) => a + b);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_cart_rounded, color: Color(0xFFD32F2F)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keranjang Belanja',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                      Text(
                        '$totalCount barang dalam keranjang',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.cart.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    widget.onClearCart();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                  label: const Text('Kosongkan', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
          const Divider(height: 24),

          // Daftar Item Keranjang
          Expanded(
            child: cartItems.isEmpty
                ? const Center(
                    child: Text(
                      'Keranjang belanja kosong',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: cartItems.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 12),
                    itemBuilder: (ctx, idx) {
                      final item = cartItems[idx];
                      final p = item['product'] as Product;
                      final qty = item['qty'] as int;
                      final lineTotal = item['lineTotal'] as int;

                      return Row(
                        children: [
                          // Product Image / Category Icon
                          ProductImageWidget.fromProduct(
                            product: p,
                            size: 44,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(width: 12),

                          // Name & Unit Price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${formatRupiah(p.price)} x $qty = ${formatRupiah(lineTotal)}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),

                          // Stepper Controls [-] qty [+]
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 22),
                                onPressed: () {
                                  widget.onDecrement(p);
                                  setState(() {});
                                  if (widget.cart.isEmpty) Navigator.pop(context);
                                },
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 22),
                                onPressed: () {
                                  if (qty < p.stock) {
                                    widget.onIncrement(p);
                                    setState(() {});
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Maksimal stok tercapai (${p.stock}).'),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),

          const Divider(height: 20),

          // Total Belanja Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Tagihan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: total < 1000
                      ? null
                      : () {
                          Navigator.pop(context);
                          widget.onCashPayment();
                        },
                  icon: const Icon(Icons.payments_rounded, size: 18),
                  label: const Text('Bayar Cash', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: total < 1000
                      ? null
                      : () {
                          Navigator.pop(context);
                          widget.onQrisPayment();
                        },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text('Bayar QR', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
