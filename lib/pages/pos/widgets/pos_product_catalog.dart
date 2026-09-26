import 'package:flutter/material.dart';
import '../../../core/widgets/barcode_scanner_sheet.dart';
import '../../../models/product.dart';
import 'pos_product_card.dart';

class PosProductCatalog extends StatefulWidget {
  final List<Product> products;
  final bool isLoading;
  final Map<int, int> cart;
  final VoidCallback onReload;
  final Function(Product product) onAddToCart;
  final Function(Product product) onIncrement;
  final Function(Product product) onDecrement;

  const PosProductCatalog({
    super.key,
    required this.products,
    required this.isLoading,
    required this.cart,
    required this.onReload,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<PosProductCatalog> createState() => _PosProductCatalogState();
}

class _PosProductCatalogState extends State<PosProductCatalog> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final set = <String>{'Semua'};
    for (final p in widget.products) {
      final cat = p.category?.trim();
      if (cat != null && cat.isNotEmpty) {
        set.add(cat);
      }
    }
    return set.toList();
  }

  List<Product> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return widget.products.where((p) {
      final barcode = (p.barcode ?? '').toLowerCase();
      final category = (p.category ?? '').toLowerCase();
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          barcode.contains(query) ||
          category.contains(query);

      final matchesCategory = _selectedCategory == 'Semua' ||
          category == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _openBarcodeScanner() async {
    await BarcodeScannerSheet.show(
      context,
      title: 'Scan Produk Kasir',
      isContinuous: true,
      onScanned: (scannedCode) async {
        final matchedProduct = widget.products.where((p) {
          return p.barcode?.trim().toLowerCase() == scannedCode.toLowerCase() ||
              p.id.toString() == scannedCode;
        }).firstOrNull;

        if (matchedProduct != null) {
          widget.onAddToCart(matchedProduct);
          return '+1 ${matchedProduct.name} (Rp ${matchedProduct.price})';
        } else {
          _searchController.text = scannedCode;
          setState(() {});
          return null;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
      );
    }

    if (widget.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Belum ada produk aktif.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: widget.onReload,
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredProducts;

    return Column(
      children: [
        // ── PENCARIAN & FILTER KATEGORI POS ──────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          color: Colors.white,
          child: Column(
            children: [
              // Kolom Pencarian & Tombol Scan Barcode Kamera
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari produk POS atau barcode...',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD32F2F), size: 20),
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
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: 'Pindai Barcode Kamera',
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
                      onPressed: _openBarcodeScanner,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Horizontal Category Chips
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

        // ── GRID OF PRODUCT CARDS ───────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Produk tidak ditemukan.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.79,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    final qty = widget.cart[p.id] ?? 0;

                    return PosProductCard(
                      product: p,
                      quantityInCart: qty,
                      onAddToCart: () => widget.onAddToCart(p),
                      onIncrement: () => widget.onIncrement(p),
                      onDecrement: () => widget.onDecrement(p),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
