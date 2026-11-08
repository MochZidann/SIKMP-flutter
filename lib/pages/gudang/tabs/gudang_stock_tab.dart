import 'package:flutter/material.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/barcode_scanner_sheet.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../models/product.dart';
import '../../../services/gudang_service.dart';
import '../../../services/supabase_service.dart';
import '../widgets/category_manager_dialog.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/stock_item_card.dart';

class GudangStockTab extends StatefulWidget {
  const GudangStockTab({super.key});

  @override
  State<GudangStockTab> createState() => _GudangStockTabState();
}

class _GudangStockTabState extends State<GudangStockTab> {
  final GudangService _gudangService = GudangService();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  List<String> _categories = ['Semua'];
  String _selectedCategory = 'Semua';
  bool _isLoading = true;
  String _stockFilter = 'ALL'; // 'ALL', 'LOW', 'OUT'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prods = await _gudangService.getProducts();
    prods.sort((a, b) => b.id.compareTo(a.id));

    final catsData = await _gudangService.getCategories();
    final catList = <String>{'Semua'};
    for (final c in catsData) {
      final name = (c['name'] ?? '').toString().trim();
      if (name.isNotEmpty) catList.add(name);
    }
    for (final p in prods) {
      final cName = (p.category ?? '').trim();
      if (cName.isNotEmpty) catList.add(cName);
    }

    if (mounted) {
      setState(() {
        _products = prods;
        _categories = catList.toList();
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
      title: 'Scan Barcode Gudang',
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
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Barang dengan barcode "$scannedCode" tidak ditemukan')),
            ],
          ),
          backgroundColor: const Color(0xFFE65100),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openCategoryManager() {
    CategoryManagerDialog.show(
      context,
      onCategoriesChanged: _loadData,
    );
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Barang Ini?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${product.name}"? Data barang yang sudah memiliki riwayat transaksi penjualan akan diproteksi demi keamanan pembukuan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _gudangService.deleteProduct(product.id);
              if (mounted) {
                if (result['success'] == true) {
                  if (SupabaseService.isConfigured) {
                    if (product.imagePath != null) {
                      SupabaseService.deleteProductImage(product.imagePath);
                    }
                    SupabaseService.cleanOldProductImages(productName: product.name);
                  }
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Barang berhasil dihapus'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Gagal menghapus barang'),
                      backgroundColor: Colors.red.shade700,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
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
          // ── PENCARIAN & FILTER ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Search Bar + Scan Barcode
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari nama barang atau barcode...',
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

                // 2. Baris Filter Kategori + Tombol Kelola Kategori
                Row(
                  children: [
                    // Tombol Kelola Kategori
                    InkWell(
                      onTap: _openCategoryManager,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 14, color: primaryColor),
                            SizedBox(width: 4),
                            Text(
                              'Kelola Kategori',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Chips Kategori Horizontal
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSelected = _selectedCategory == cat;
                            return ChoiceChip(
                              showCheckmark: false,
                              label: Text(cat, style: const TextStyle(fontSize: 11)),
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
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. Status Filter Chips (Semua, Kritis, Habis)
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
                      labelStyle: TextStyle(color: _stockFilter == 'ALL' ? Colors.white : const Color(0xFF333333)),
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
                      labelStyle: TextStyle(color: _stockFilter == 'LOW' ? Colors.white : const Color(0xFF333333)),
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
                      labelStyle: TextStyle(color: _stockFilter == 'OUT' ? Colors.white : const Color(0xFF333333)),
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (_) => setState(() => _stockFilter = 'OUT'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── DAFTAR PRODUK (CRUD BARANG) ─────────────────────────────────
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: 6,
                    itemBuilder: (_, _) => const SkeletonProductTile(),
                  )
                : _filteredProducts.isEmpty
                    ? EmptyDataView(
                        icon: Icons.inventory_2_outlined,
                        title: 'Produk Tidak Ditemukan',
                        subtitle: 'Coba ubah kata kunci pencarian atau filter kategori/stok.',
                        actionLabel: 'Muat Ulang',
                        onAction: _loadData,
                      )
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return StockItemCard(
                              product: product,
                              onEdit: () {
                                ProductFormDialog.show(
                                  context,
                                  product: product,
                                  onProductSaved: _loadData,
                                );
                              },
                              onDelete: () => _confirmDeleteProduct(product),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'Tambah Barang Baru',
        onPressed: () {
          ProductFormDialog.show(
            context,
            onProductSaved: () {
              _searchController.clear();
              _loadData();
            },
          );
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
