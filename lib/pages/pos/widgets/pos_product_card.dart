import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/category_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/product_image_widget.dart';
import '../../../models/product.dart';

class PosProductCard extends StatelessWidget {
  final Product product;
  final int quantityInCart;
  final VoidCallback onAddToCart;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const PosProductCard({
    super.key,
    required this.product,
    required this.quantityInCart,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
  });

  Widget _buildCategoryPlaceholder(Product p, Color catColor) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: catColor.withValues(alpha: 0.18),
              blurRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          CategoryHelper.getIcon(p.category),
          color: catColor,
          size: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qty = quantityInCart;
    final isInCart = qty > 0;
    final isOutOfStock = product.stock <= 0;
    final catColor = CategoryHelper.getColor(product.category);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isOutOfStock ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInCart ? const Color(0xFFD32F2F) : Colors.grey.shade200,
          width: isInCart ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isInCart
                ? const Color(0xFFD32F2F).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isOutOfStock
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stok produk ${product.name} habis'),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              : () {
                  if (qty < product.stock) {
                    onAddToCart();
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${product.name} (+1) masuk keranjang',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 650),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Maksimal stok tercapai (${product.stock}).'),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── AREA GAMBAR (FLEX: 54) ────────────────
              Expanded(
                flex: 54,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.09),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProductImageWidget.fromProduct(
                        product: product,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                        fallbackColor: catColor,
                        placeholder: _buildCategoryPlaceholder(product, catColor),
                      ),

                      // Badge Stok di Kiri Atas
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? Colors.red.shade700
                                : product.stock <= 5
                                    ? Colors.amber.shade800
                                    : Colors.black.withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            isOutOfStock
                                ? 'HABIS'
                                : product.stock <= 5
                                    ? 'Sisa ${product.stock}'
                                    : 'Stok: ${product.stock}',
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Badge Jumlah di Keranjang di Kanan Atas
                      if (isInCart)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD32F2F).withValues(alpha: 0.45),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shopping_cart_rounded, size: 9, color: Colors.white),
                                const SizedBox(width: 2),
                                Text(
                                  '$qty',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── BAGIAN INFO PRODUK & AKSI (FLEX: 46) ─
              Expanded(
                flex: 46,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (product.category ?? 'UMUM').toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: catColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: isOutOfStock ? Colors.grey : const Color(0xFF222222),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatRupiah(product.price),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: isOutOfStock ? Colors.grey : const Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ),

                      // Tombol Aksi: Tambah atau Stepper
                      if (isInCart)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: onDecrement,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.remove_rounded, size: 13, color: Color(0xFFD32F2F)),
                                ),
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                              InkWell(
                                onTap: () {
                                  if (qty < product.stock) {
                                    onIncrement();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Maksimal stok tercapai (${product.stock}).'),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_rounded, size: 13, color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isOutOfStock ? Colors.grey.shade100 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isOutOfStock ? Colors.grey.shade300 : Colors.red.shade100,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isOutOfStock ? Icons.block_rounded : Icons.add_shopping_cart_rounded,
                                size: 11,
                                color: isOutOfStock ? Colors.grey : const Color(0xFFD32F2F),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOutOfStock ? 'Habis' : '+ Keranjang',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isOutOfStock ? Colors.grey : const Color(0xFFD32F2F),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
