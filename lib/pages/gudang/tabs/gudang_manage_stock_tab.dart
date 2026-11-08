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

  int _getCategoryCount(String cat) {
    if (cat == 'Semua') return _products.length;
    return _products.where((p) => (p.category ?? '').toLowerCase() == cat.toLowerCase()).length;
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
          // ── SEARCH BAR & COMPACT UNIFIED FILTER TOOLBAR ───────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Search Bar + Camera Scanner
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

                // 2. Baris Filter Terpadu: Kategori Dropdown & Filter Status Stok
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Dropdown Pilihan Kategori
                      PopupMenuButton<String>(
                        tooltip: 'Filter Kategori',
                        onSelected: (cat) => setState(() => _selectedCategory = cat),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (ctx) => _categories.map((cat) {
                          final count = _getCategoryCount(cat);
                          final isSelected = _selectedCategory == cat;
                          return PopupMenuItem<String>(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.folder_outlined,
                                  size: 16,
                                  color: isSelected ? primaryColor : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cat == 'Semua' ? 'Semua Kategori' : cat,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? primaryColor : Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? primaryColor : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedCategory != 'Semua' ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedCategory != 'Semua' ? primaryColor : Colors.grey.shade300,
                              width: _selectedCategory != 'Semua' ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list_rounded,
                                size: 14,
                                color: _selectedCategory != 'Semua' ? primaryColor : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _selectedCategory == 'Semua' ? 'Kategori: Semua' : 'Kategori: $_selectedCategory',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedCategory != 'Semua' ? primaryColor : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 18,
                                color: _selectedCategory != 'Semua' ? primaryColor : Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedCategory != 'Semua') ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => setState(() => _selectedCategory = 'Semua'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 12, color: Colors.black54),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),

                      // Separator Vertikal
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      const SizedBox(width: 8),

                      // Filter Status Stok Chips
                      _buildStatusFilterChip(
                        label: 'Semua',
                        value: 'ALL',
                        count: _products.length,
                        activeColor: primaryColor,
                      ),
                      const SizedBox(width: 6),
                      _buildStatusFilterChip(
                        label: 'Kritis (< 5)',
                        value: 'LOW',
                        count: lowCount,
                        activeColor: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 6),
                      _buildStatusFilterChip(
                        label: 'Habis',
                        value: 'OUT',
                        count: outCount,
                        activeColor: Colors.red.shade700,
                      ),
                    ],
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

    final Color statusText;
    final String statusLabel;

    if (isOut) {
      statusText = const Color(0xFFBE123C);
      statusLabel = 'Habis';
    } else if (isLow) {
      statusText = const Color(0xFFB45309);
      statusLabel = 'Kritis';
    } else {
      statusText = const Color(0xFF047857);
      statusLabel = 'Aman';
    }

    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── BARIS ATAS: GAMBAR, NAMA, KATEGORI, BARCODE & ANGKA STOK ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Gambar Produk
              ProductImageWidget.fromProduct(
                product: p,
                size: 44,
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
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
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
                        if (p.barcode != null && p.barcode!.isNotEmpty)
                          Text(
                            p.barcode!,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        Text(
                          '• Min: ${p.minimumStock}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 3. Angka Stok & Status (Di Tengah)
              SizedBox(
                width: 48,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${p.stock}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: statusText,
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
                        color: statusText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // ── BARIS AKSI: 3 BUTTON SIMETRIS (MASUK, KELUAR, OPNAME) ──
          Row(
            children: [
              // 1. + Barang Masuk (Pasokan)
              Expanded(
                child: _buildStockButton(
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
              ),
              const SizedBox(width: 8),

              // 2. − Barang Keluar (Retur / Rusak)
              Expanded(
                child: _buildStockButton(
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
              ),
              const SizedBox(width: 8),

              // 3. 📝 Opname Stok (Penyesuaian Fisik)
              Expanded(
                child: _buildStockButton(
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
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

  Widget _buildStatusFilterChip({
    required String label,
    required String value,
    required int count,
    required Color activeColor,
  }) {
    final isSelected = _stockFilter == value;

    return InkWell(
      onTap: () => setState(() => _stockFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
