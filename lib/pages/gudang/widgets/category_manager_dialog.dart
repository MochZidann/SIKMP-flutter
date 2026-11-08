import 'package:flutter/material.dart';
import '../../../core/utils/category_helper.dart';
import '../../../services/gudang_service.dart';

class CategoryManagerDialog extends StatefulWidget {
  final VoidCallback onCategoriesChanged;

  const CategoryManagerDialog({super.key, required this.onCategoriesChanged});

  static Future<void> show(BuildContext context, {required VoidCallback onCategoriesChanged}) {
    return showDialog(
      context: context,
      builder: (ctx) => CategoryManagerDialog(onCategoriesChanged: onCategoriesChanged),
    );
  }

  @override
  State<CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends State<CategoryManagerDialog> {
  final GudangService _gudangService = GudangService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final cats = await _gudangService.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredCategories {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _categories;
    return _categories.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  void _openAddCategoryDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Kategori Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Contoh: Makanan, Minuman, ATK',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);

              final res = await _gudangService.createCategory(name);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? (res['success'] ? 'Kategori berhasil ditambahkan' : 'Gagal')),
                    backgroundColor: res['success'] ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                );
                if (res['success'] == true) {
                  _loadCategories();
                  widget.onCategoriesChanged();
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _openEditCategoryDialog(Map<String, dynamic> category) {
    final id = category['id'] as int? ?? 0;
    final currentName = category['name'] as String? ?? '';
    final textController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah Nama Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Nama Kategori Baru',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isEmpty || newName == currentName) return;
              Navigator.pop(ctx);

              final res = await _gudangService.updateCategory(id, newName);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? (res['success'] ? 'Kategori berhasil diperbarui' : 'Gagal')),
                    backgroundColor: res['success'] ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                );
                if (res['success'] == true) {
                  _loadCategories();
                  widget.onCategoriesChanged();
                }
              }
            },
            child: const Text('Perbarui'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(Map<String, dynamic> category) {
    final id = category['id'] as int? ?? 0;
    final name = category['name'] as String? ?? '';
    final productCount = category['products_count'] as int? ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Kategori "$name"?'),
        content: Text(
          productCount > 0
              ? 'Kategori ini sedang digunakan oleh $productCount produk. Ubah kategori produk terlebih dahulu sebelum menghapus.'
              : 'Apakah Anda yakin ingin menghapus kategori ini secara permanen?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          if (productCount == 0)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await _gudangService.deleteCategory(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? (res['success'] ? 'Kategori berhasil dihapus' : 'Gagal')),
                      backgroundColor: res['success'] ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  );
                  if (res['success'] == true) {
                    _loadCategories();
                    widget.onCategoriesChanged();
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.category_rounded, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelola Kategori Barang',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Daftar pengelompokan jenis barang gudang',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search & Add Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari kategori...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onPressed: _openAddCategoryDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // List of Categories
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : _filteredCategories.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada kategori yang ditemukan.',
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _filteredCategories.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _filteredCategories[index];
                              final name = item['name'] as String? ?? 'Umum';
                              final count = item['products_count'] as int? ?? 0;
                              final catColor = CategoryHelper.getColor(name);

                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(Icons.folder_rounded, size: 16, color: catColor),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                ),
                                subtitle: Text(
                                  '$count produk',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Ubah Nama Kategori',
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                                      onPressed: () => _openEditCategoryDialog(item),
                                    ),
                                    IconButton(
                                      tooltip: 'Hapus Kategori',
                                      icon: Icon(Icons.delete_outline_rounded, size: 18, color: count > 0 ? Colors.grey.shade400 : Colors.red),
                                      onPressed: () => _confirmDeleteCategory(item),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

