import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/product_image_widget.dart';
import '../../models/product.dart';
import '../../services/pos_service.dart';

class ProdukTab extends StatefulWidget {
  final Function(Product)? onAddToCart;

  const ProdukTab({super.key, this.onAddToCart});

  @override
  State<ProdukTab> createState() => _ProdukTabState();
}

class _ProdukTabState extends State<ProdukTab> {
  final PosService _posService = PosService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedCategory = 'Semua';

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
    final prods = await _posService.getProducts();
    if (mounted) {
      setState(() {
        _allProducts = prods;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesQuery = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            (p.barcode != null && p.barcode!.toLowerCase().contains(query)) ||
            (p.category != null && p.category!.toLowerCase().contains(query));

        final matchesCat = _selectedCategory == 'Semua' ||
            p.category?.toLowerCase() == _selectedCategory.toLowerCase();

        return matchesQuery && matchesCat;
      }).toList();
    });
  }

  List<String> get _categories {
    final cats = _allProducts
        .map((p) => p.category ?? 'Lainnya')
        .toSet()
        .where((c) => c.isNotEmpty)
        .toList();
    cats.sort();
    return ['Semua', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 0,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Color(0xFFD32F2F),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Katalog & Stok Produk',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
      children: [
        // ── BAR PENCARIAN & FILTER KATEGORI ──────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Column(
            children: [
              // Search Input
              TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Cari produk, barcode, atau kategori...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: Color(0xFFD32F2F), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Filter Chips Kategori Horizontal
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        showCheckmark: false,
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF333333),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFFD32F2F),
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        onSelected: (val) {
                          setState(() {
                            _selectedCategory = cat;
                            _applyFilters();
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── DAFTAR PRODUK (LIST VIEW) ────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                )
              : _filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Produk tidak ditemukan.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFD32F2F),
                      onRefresh: _loadProducts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final p = _filteredProducts[index];

                          // Status warna stok
                          Color stockBadgeColor;
                          Color stockTextColor;
                          String stockText;

                          if (p.stock > 10) {
                            stockBadgeColor = Colors.green.shade50;
                            stockTextColor = const Color(0xFF2E7D32);
                            stockText = 'Stok: ${p.stock}';
                          } else if (p.stock > 0) {
                            stockBadgeColor = Colors.orange.shade50;
                            stockTextColor = Colors.orange.shade800;
                            stockText = 'Sisa: ${p.stock}';
                          } else {
                            stockBadgeColor = Colors.red.shade50;
                            stockTextColor = Colors.red.shade700;
                            stockText = 'Habis';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              leading: ProductImageWidget.fromProduct(
                                product: p,
                                size: 44,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              title: Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF2B2B2B),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 3),
                                  Text(
                                    '${p.category ?? 'Tanpa Kategori'} ${p.barcode != null ? '• ${p.barcode}' : ''}',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currencyFormat.format(p.price),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFD32F2F),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: stockBadgeColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: stockTextColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  stockText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: stockTextColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    ),
  );
}
}
