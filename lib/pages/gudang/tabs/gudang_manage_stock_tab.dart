import 'package:flutter/material.dart';
import '../../../core/utils/category_helper.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/barcode_scanner_sheet.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../core/widgets/product_image_widget.dart';
import '../../../models/product.dart';
import '../../../services/gudang_service.dart';
import '../widgets/stock_adjust_dialog.dart';
import '../widgets/stock_in_dialog.dart';
import '../widgets/stock_out_dialog.dart';

class GudangManageStockTab extends StatefulWidget {
  const GudangManageStockTab({super.key});

  @override
  State<GudangManageStockTab> createState() => _GudangManageStockTabState();
}

class _GudangManageStockTabState extends State<GudangManageStockTab> {
  final GudangService _gudangService = GudangService();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  bool _isLoading = true;
  String _stockFilter = 'ALL'; // 'ALL', 'LOW', 'OUT'
  String _selectedCategory = 'Semua';
  List<String> _categories = ['Semua'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final prods = await _gudangService.getProducts();
    prods.sort((a, b) => b.id.compareTo(a.id));

    final catSet = <String>{'Semua'};
    for (final p in prods) {
      final cName = (p.category ?? '').trim();
      if (cName.isNotEmpty) catSet.add(cName);
    }

    if (mounted) {
      setState(() {
        _products = prods;
        _categories = catSet.toList();
        _isLoading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _products.where((p) {
      final barcode = (p.barcode ?? '').toLowerCase();
      final category = (p.category ?? '').toLowerCase();
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          barcode.contains(query) ||
          category.contains(query);

      final matchesCategory = _selectedCategory == 'Semua' ||
          category == _selectedCategory.toLowerCase();

      final matchesStock = _stockFilter == 'ALL' ||
          (_stockFilter == 'LOW' && p.isLowStock) ||
          (_stockFilter == 'OUT' && p.isOutOfStock);

      return matchesQuery && matchesCategory && matchesStock;
    }).toList();
  }

  Future<void> _openBarcodeScanner() async {
    final scannedCode = await BarcodeScannerSheet.show(
      context,
      title: 'Scan Barcode Kelola Stok',
    );

    if (scannedCode == null || !mounted) return;

    _searchController.text = scannedCode;
    setState(() {});

    final matched = _products.where((p) =>
        p.barcode?.trim().toLowerCase() == scannedCode.toLowerCase() ||
        p.id.toString() == scannedCode).firstOrNull;

    if (matched == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barang dengan barcode "$scannedCode" tidak ditemukan'),
          backgroundColor: const Color(0xFFE65100),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);
    final lowCount = _products.where((p) => p.isLowStock).length;
    final outCount = _products.where((p) => p.isOutOfStock).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // ── HEADER & TOOLBAR (PERSIS DENGAN WEB KELOLA STOK) ───────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Judul
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded, color: primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelola Stok Barang',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Atur stok masuk, keluar, dan opname fisik barang',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar + Camera Scanner
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari nama produk atau barcode...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          prefixIcon: const Icon(Icons.search_rounded, color: primaryColor, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        tooltip: 'Scan Barcode Kamera',
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
                        onPressed: _openBarcodeScanner,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Filter Status Stok Chips (Semua, Kritis, Habis)
                Row(
                  children: [
                    ChoiceChip(
                      showCheckmark: false,
                      label: Text(
                        'Semua (${_products.length})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      selected: _stockFilter == 'ALL',
                      selectedColor: const Color(0xFF334155),
                      labelStyle: TextStyle(
                        color: _stockFilter == 'ALL' ? Colors.white : const Color(0xFF333333),
                      ),
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (_) => setState(() => _stockFilter = 'ALL'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      showCheckmark: false,
                      label: Text(
                        'Kritis (< 5) ($lowCount)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      selected: _stockFilter == 'LOW',
                      selectedColor: Colors.amber.shade900,
                      labelStyle: TextStyle(
                        color: _stockFilter == 'LOW' ? Colors.white : const Color(0xFF333333),
                      ),
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (_) => setState(() => _stockFilter = 'LOW'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      showCheckmark: false,
                      label: Text(
                        'Habis ($outCount)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      selected: _stockFilter == 'OUT',
                      selectedColor: Colors.red.shade700,
                      labelStyle: TextStyle(
                        color: _stockFilter == 'OUT' ? Colors.white : const Color(0xFF333333),
                      ),
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (_) => setState(() => _stockFilter = 'OUT'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Kategori Chips Horizontal
                SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Text(cat, style: const TextStyle(fontSize: 10.5)),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF333333),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── DAFTAR PRODUK DENGAN BUTTON MASUK, KELUAR, & OPNAME DI SAMPING ──
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    itemBuilder: (_, _) => const SkeletonProductTile(),
                  )
                : _filteredProducts.isEmpty
                    ? EmptyDataView(
                        icon: Icons.inventory_2_outlined,
                        title: 'Produk Tidak Ditemukan',
                        subtitle: 'Coba ubah kata kunci atau filter status stok.',
                        actionLabel: 'Muat Ulang',
                        onAction: _loadProducts,
                      )
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: _loadProducts,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _filteredProducts.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final p = _filteredProducts[index];
                            return _buildStockManageCard(p);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Kartu Kelola Stok Produk dengan Button Masuk, Keluar, dan Opname
  Widget _buildStockManageCard(Product p) {
    final catColor = CategoryHelper.getColor(p.category);
    final isOut = p.isOutOfStock;
    final isLow = p.isLowStock;

    final Color statusBg;
    final Color statusText;
    final Color statusBorder;
    final String statusLabel;

    if (isOut) {
      statusBg = const Color(0xFFFFF1F2);
      statusText = const Color(0xFFBE123C);
      statusBorder = const Color(0xFFFECDD3);
      statusLabel = 'Habis';
    } else if (isLow) {
      statusBg = const Color(0xFFFFFBEB);
      statusText = const Color(0xFFB45309);
      statusBorder = const Color(0xFFFDE68A);
      statusLabel = 'Kritis';
    } else {
      statusBg = const Color(0xFFECFDF5);
      statusText = const Color(0xFF047857);
      statusBorder = const Color(0xFFA7F3D0);
      statusLabel = 'Aman';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOut
              ? Colors.red.shade200
              : isLow
                  ? Colors.orange.shade200
                  : Colors.grey.shade200,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── BARIS ATAS: GAMBAR, NAMA, KATEGORI, BARCODE & BADGE STOK ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Gambar Produk
              ProductImageWidget.fromProduct(
                product: p,
                size: 46,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 10),

              // 2. Info Barang
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: Color(0xFF1E293B),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (p.category ?? 'UMUM').toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: catColor,
                            ),
                          ),
                        ),
                        if (p.barcode != null && p.barcode!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p.barcode!,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade500,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 3. Badge Angka Stok & Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${p.stock}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: statusText,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: statusText,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // ── BARIS BAWAH: INFO MIN STOK & 3 BUTTON (MASUK, KELUAR, OPNAME) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min. Stok: ${p.minimumStock} unit',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),

              // 3 Button Aksi (Sama dengan Web)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. + Barang Masuk (Pasokan)
                  _buildStockButton(
                    label: 'Masuk',
                    icon: Icons.add_rounded,
                    color: const Color(0xFF059669),
                    bgColor: const Color(0xFFECFDF5),
                    borderColor: const Color(0xFFA7F3D0),
                    tooltip: 'Stok Masuk (Pasokan)',
                    onTap: () {
                      StockInDialog.show(
                        context,
                        product: p,
                        onStockUpdated: _loadProducts,
                      );
                    },
                  ),
                  const SizedBox(width: 6),

                  // 2. − Barang Keluar (Retur / Rusak)
                  _buildStockButton(
                    label: 'Keluar',
                    icon: Icons.remove_rounded,
                    color: const Color(0xFFE11D48),
                    bgColor: const Color(0xFFFFF1F2),
                    borderColor: const Color(0xFFFECDD3),
                    tooltip: 'Barang Keluar / Retur',
                    onTap: () {
                      StockOutDialog.show(
                        context,
                        product: p,
                        onStockUpdated: _loadProducts,
                      );
                    },
                  ),
                  const SizedBox(width: 6),

                  // 3. 📝 Opname Stok (Penyesuaian Fisik)
                  _buildStockButton(
                    label: 'Opname',
                    icon: Icons.tune_rounded,
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFFBEB),
                    borderColor: const Color(0xFFFDE68A),
                    tooltip: 'Stock Opname (Penyesuaian Fisik)',
                    onTap: () {
                      StockAdjustDialog.show(
                        context,
                        product: p,
                        onStockUpdated: _loadProducts,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
