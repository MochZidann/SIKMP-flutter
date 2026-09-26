import 'package:flutter/material.dart';
import '../../../core/utils/category_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/product_image_widget.dart';
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

  void _showQuickActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header Ringkasan Produk
              Row(
                children: [
                  ProductImageWidget.fromProduct(
                    product: product,
                    size: 48,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              formatRupiah(product.price),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE65100),
                              ),
                            ),
                            const Text(' • ', style: TextStyle(color: Colors.grey)),
                            Text(
                              'Stok: ${product.stock} unit',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: product.isOutOfStock
                                    ? Colors.red
                                    : product.isLowStock
                                        ? Colors.orange.shade800
                                        : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Action List Tiles
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF2E7D32), size: 20),
                ),
                title: const Text('Barang Masuk (Restock)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Catat stok masuk resmi dari pengiriman supplier', style: TextStyle(fontSize: 11.5)),
                onTap: () {
                  Navigator.pop(ctx);
                  onStockIn();
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF1976D2), size: 20),
                ),
                title: const Text('Stock Opname (Penyesuaian)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Koreksi jumlah stok sesuai hitungan fisik rak', style: TextStyle(fontSize: 11.5)),
                onTap: () {
                  Navigator.pop(ctx);
                  onStockAdjust();
                },
              ),
              if (onEdit != null)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_outlined, color: Color(0xFFE65100), size: 20),
                  ),
                  title: const Text('Edit Data Barang', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Ubah nama, foto, barcode, kategori, dan harga', style: TextStyle(fontSize: 11.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit?.call();
                  },
                ),
              if (onDelete != null)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  ),
                  title: const Text('Hapus Barang', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Hapus master produk dari daftar', style: TextStyle(fontSize: 11.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete?.call();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.isOutOfStock;
    final isLowStock = product.isLowStock;
    final catColor = CategoryHelper.getColor(product.category);

    final statusBgColor = isOutOfStock
        ? Colors.red.shade50
        : isLowStock
            ? Colors.orange.shade50
            : Colors.green.shade50;

    final statusTextColor = isOutOfStock
        ? Colors.red.shade700
        : isLowStock
            ? Colors.orange.shade900
            : Colors.green.shade700;

    final statusBorderColor = isOutOfStock
        ? Colors.red.shade200
        : isLowStock
            ? Colors.orange.shade200
            : Colors.green.shade200;

    final statusLabel = isOutOfStock
        ? 'Habis'
        : isLowStock
            ? 'Kritis'
            : 'Aman';

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOutOfStock
                ? Colors.red.shade200
                : isLowStock
                    ? Colors.orange.shade200
                    : Colors.grey.shade200,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showQuickActionSheet(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  // 1. FOTO PRODUK / IKON KATEGORI
                  ProductImageWidget.fromProduct(
                    product: product,
                    size: 46,
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
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Color(0xFF2B2B2B),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),

                        // Kategori & Barcode dalam 1 baris rapi
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (product.category ?? 'UMUM').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8.5,
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

                        // Harga Jual & Modal
                        Row(
                          children: [
                            Text(
                              formatRupiah(product.price),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE65100),
                              ),
                            ),
                            if (product.purchasePrice > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '• Modal: ${formatRupiah(product.purchasePrice)}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 3. BADGE STOK & STATUS
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusBorderColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${product.stock}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: statusTextColor,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: statusTextColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. MENU AKSI POPUP (⋮)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.black45),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 160),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'stock_in') onStockIn();
                      if (val == 'stock_adjust') onStockAdjust();
                      if (val == 'edit') onEdit?.call();
                      if (val == 'delete') onDelete?.call();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'stock_in',
                        child: Row(
                          children: [
                            Icon(Icons.add_shopping_cart_rounded, size: 18, color: Color(0xFF2E7D32)),
                            SizedBox(width: 10),
                            Text('Barang Masuk', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'stock_adjust',
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 18, color: Color(0xFF1976D2)),
                            SizedBox(width: 10),
                            Text('Stock Opname', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 8),
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: Color(0xFFE65100)),
                              SizedBox(width: 10),
                              Text('Edit Barang', style: TextStyle(fontSize: 12.5)),
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
      ),
    );
  }
}
