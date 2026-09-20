import 'package:flutter/material.dart';
import '../../../core/utils/category_helper.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../services/gudang_service.dart';

class GudangCategoryTab extends StatefulWidget {
  const GudangCategoryTab({super.key});

  @override
  State<GudangCategoryTab> createState() => _GudangCategoryTabState();
}

class _GudangCategoryTabState extends State<GudangCategoryTab> {
  final GudangService _gudangService = GudangService();
  List<Map<String, dynamic>> _categorySummaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final prods = await _gudangService.getProducts();

    // Group products by category
    final Map<String, int> counts = {};
    final Map<String, int> stockSums = {};

    for (final p in prods) {
      final cat = (p.category ?? 'Umum').trim();
      counts[cat] = (counts[cat] ?? 0) + 1;
      stockSums[cat] = (stockSums[cat] ?? 0) + p.stock;
    }

    final summaries = counts.entries.map((entry) {
      return {
        'name': entry.key,
        'count': entry.value,
        'totalStock': stockSums[entry.key] ?? 0,
      };
    }).toList();

    summaries.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    if (mounted) {
      setState(() {
        _categorySummaries = summaries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
          : _categorySummaries.isEmpty
              ? EmptyDataView(
                  icon: Icons.category_rounded,
                  title: 'Kategori Kosong',
                  subtitle: 'Belum ada data kategori produk yang terdaftar.',
                  actionLabel: 'Muat Ulang',
                  onAction: _loadCategories,
                )
              : RefreshIndicator(
                  color: const Color(0xFFE65100),
                  onRefresh: _loadCategories,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categorySummaries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _categorySummaries[index];
                      final name = item['name'] as String;
                      final count = item['count'] as int;
                      final totalStock = item['totalStock'] as int;
                      final catColor = CategoryHelper.getColor(name);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                CategoryHelper.getIcon(name),
                                color: catColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$count Varian Barang • Total Fisik: $totalStock unit',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count SKU',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
