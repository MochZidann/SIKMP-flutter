import 'package:flutter/material.dart';
import '../../../core/utils/category_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/product_image_widget.dart';
import '../../../models/product.dart';

class StockItemCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onStockIn;
  final VoidCallback? onStockOut;
  final VoidCallback? onStockAdjust;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StockItemCard({
    super.key,
    required this.product,
    this.onStockIn,
    this.onStockOut,
    this.onStockAdjust,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryHelper.getColor(product.category);

    final isOutOfStock = product.isOutOfStock;
    final isLowStock = product.isLowStock;

    final Color statusTextColor;
    final String statusLabel;

    if (isOutOfStock) {
      statusTextColor = const Color(0xFFBE123C);
      statusLabel = 'Habis';
    } else if (isLowStock) {
      statusTextColor = const Color(0xFFB45309);
      statusLabel = 'Kritis';
    } else {
      statusTextColor = const Color(0xFF047857);
      statusLabel = 'Aman';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // 1. FOTO PRODUK
                ProductImageWidget.fromProduct(
                  product: product,
                  size: 48,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 12),

                // 2. INFORMASI BARANG (NAMA, KATEGORI, HARGA, BARCODE)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Produk
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Kategori & Barcode
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
                                fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                          ),
                          if (product.barcode != null && product.barcode!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                product.barcode!,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Harga Jual & Modal & Member
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            formatRupiah(product.price),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE65100),
                            ),
                          ),
                          if (product.memberPrice != null &&
                              product.memberPrice! > 0 &&
                              product.memberPrice! < product.price)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFDDD6FE)),
                              ),
                              child: Text(
                                'Mbr: ${formatRupiah(product.memberPrice!)}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ),
                          if (product.purchasePrice > 0)
                            Text(
                              '• Mdl: ${formatRupiah(product.purchasePrice)}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 3. ANGKA STOK & STATUS (DI TENGAH)
                SizedBox(
                  width: 48,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${product.stock}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: statusTextColor,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        statusLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: statusTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // 4. MENU AKSI CRUD (EDIT & HAPUS)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.black45),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 140),
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
                            Icon(Icons.edit_outlined, size: 16, color: Color(0xFFE65100)),
                            SizedBox(width: 8),
                            Text('Edit Barang', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus Barang', style: TextStyle(fontSize: 12.5, color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
