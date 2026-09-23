import 'package:flutter/material.dart';
import '../../../core/utils/category_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/product.dart';

class StockItemCard extends StatelessWidget {
  final Product product;
  final VoidCallback onStockIn;
  final VoidCallback onStockAdjust;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StockItemCard({
    super.key,
    required this.product,
    required this.onStockIn,
    required this.onStockAdjust,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.isOutOfStock;
    final isLowStock = product.isLowStock;
    final catColor = CategoryHelper.getColor(product.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOutOfStock
              ? Colors.red.shade300
              : isLowStock
                  ? Colors.amber.shade300
                  : Colors.grey.shade200,
          width: isOutOfStock || isLowStock ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Category Icon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CategoryHelper.getIcon(product.category),
                    color: catColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Barcode
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (product.category ?? 'UMUM').toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: catColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (product.purchasePrice > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              'Modal: ${formatRupiah(product.purchasePrice)}',
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (product.barcode != null && product.barcode!.isNotEmpty) ...[
                            Text(
                              product.barcode!,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'monospace'),
                            ),
                            const Text(' • ', style: TextStyle(color: Colors.grey)),
                          ],
                          Text(
                            formatRupiah(product.price),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2B2B2B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Stock Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? Colors.red.shade50
                        : isLowStock
                            ? Colors.amber.shade50
                            : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOutOfStock
                          ? Colors.red.shade200
                          : isLowStock
                              ? Colors.amber.shade200
                              : Colors.green.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${product.stock}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isOutOfStock
                              ? Colors.red.shade700
                              : isLowStock
                                  ? Colors.amber.shade900
                                  : Colors.green.shade700,
                        ),
                      ),
                      Text(
                        isOutOfStock
                            ? 'HABIS'
                            : isLowStock
                                ? 'KRITIS'
                                : 'AMAN',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isOutOfStock
                              ? Colors.red.shade700
                              : isLowStock
                                  ? Colors.amber.shade900
                                  : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // More Menu Button (Edit & Hapus)
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'edit') onEdit?.call();
                      if (val == 'delete') onDelete?.call();
                    },
                    itemBuilder: (ctx) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: Color(0xFFE65100)),
                              SizedBox(width: 10),
                              Text('Edit Barang', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Hapus Barang', style: TextStyle(fontSize: 13, color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onStockIn,
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                    label: const Text('Barang Masuk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE65100),
                      side: const BorderSide(color: Color(0xFFE65100)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onStockAdjust,
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Stock Opname', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
