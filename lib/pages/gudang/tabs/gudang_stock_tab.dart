import 'package:flutter/material.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../models/product.dart';
import '../../../services/gudang_service.dart';
import '../widgets/stock_adjust_dialog.dart';
import '../widgets/stock_in_dialog.dart';
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
  bool _isLoading = true;
  String _stockFilter = 'ALL'; // 'ALL', 'LOW', 'OUT'

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
    if (mounted) {
      setState(() {
        _products = prods;
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

      final matchesStock = _stockFilter == 'ALL' ||
          (_stockFilter == 'LOW' && p.stock > 0 && p.stock <= 5) ||
          (_stockFilter == 'OUT' && p.stock <= 0);

      return matchesQuery && matchesStock;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // ── PENCARIAN & FILTER CEPAT STOK ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari nama barang atau barcode...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE65100), size: 20),
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
                const SizedBox(height: 10),

                // Status Filter Chips
                Row(
                  children: [
                    ChoiceChip(
                      showCheckmark: false,
                      label: const Text('Semua Stok', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      selected: _stockFilter == 'ALL',
                      selectedColor: const Color(0xFFE65100),
                      labelStyle: TextStyle(color: _stockFilter == 'ALL' ? Colors.white : const Color(0xFF333333)),
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (_) => setState(() => _stockFilter = 'ALL'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      showCheckmark: false,
                      label: const Text('Kritis (≤ 5)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      selected: _stockFilter == 'LOW',
                      selectedColor: Colors.amber.shade900,
                      labelStyle: TextStyle(color: _stockFilter == 'LOW' ? Colors.white : const Color(0xFF333333)),
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (_) => setState(() => _stockFilter = 'LOW'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      showCheckmark: false,
                      label: const Text('Habis (0)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

          // ── DAFTAR PRODUK & STOK ───────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
                : _filteredProducts.isEmpty
                    ? EmptyDataView(
                        icon: Icons.inventory_2_outlined,
                        title: 'Produk Tidak Ditemukan',
                        subtitle: 'Coba ubah kata kunci atau filter status stok.',
                        actionLabel: 'Muat Ulang',
                        onAction: _loadProducts,
                      )
                    : RefreshIndicator(
                        color: const Color(0xFFE65100),
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return StockItemCard(
                              product: product,
                              onStockIn: () {
                                StockInDialog.show(
                                  context,
                                  product: product,
                                  onStockUpdated: _loadProducts,
                                );
                              },
                              onStockAdjust: () {
                                StockAdjustDialog.show(
                                  context,
                                  product: product,
                                  onStockUpdated: _loadProducts,
                                );
                              },
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
