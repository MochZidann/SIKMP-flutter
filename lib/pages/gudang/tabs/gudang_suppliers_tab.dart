import 'package:flutter/material.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../models/supplier.dart';
import '../../../services/supplier_service.dart';
import '../gudang_supplier_mutations_page.dart';
import '../widgets/supplier_form_dialog.dart';

class GudangSuppliersTab extends StatefulWidget {
  const GudangSuppliersTab({super.key});

  @override
  State<GudangSuppliersTab> createState() => _GudangSuppliersTabState();
}

class _GudangSuppliersTabState extends State<GudangSuppliersTab> {
  final SupplierService _supplierService = SupplierService();
  final TextEditingController _searchController = TextEditingController();

  List<Supplier> _suppliers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    final suppliers = await _supplierService.getSuppliers(search: _searchController.text.trim());
    if (mounted) {
      setState(() {
        _suppliers = suppliers;
        _isLoading = false;
      });
    }
  }

  List<Supplier> get _filteredSuppliers {
    final query = _searchController.text.trim().toLowerCase();
    return _suppliers.where((s) {
      return query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.code.toLowerCase().contains(query) ||
          (s.contactPerson != null && s.contactPerson!.toLowerCase().contains(query)) ||
          (s.phone != null && s.phone!.toLowerCase().contains(query));
    }).toList();
  }

  // Ringkasan metrik supplier
  int get _totalSuppliersCount => _suppliers.length;
  int get _totalInQty => _suppliers.fold(0, (sum, s) => sum + s.totalIn);
  int get _totalOutQty => _suppliers.fold(0, (sum, s) => sum + s.totalOut);

  void _openCreateSupplier() {
    SupplierFormDialog.show(
      context,
      onSaved: _loadSuppliers,
    );
  }

  void _openEditSupplier(Supplier supplier) {
    SupplierFormDialog.show(
      context,
      supplier: supplier,
      onSaved: _loadSuppliers,
    );
  }

  void _openMutations(Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GudangSupplierMutationsPage(supplier: supplier),
      ),
    );
  }

  void _confirmDeleteSupplier(Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Hapus Supplier?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus rekanan supplier "${supplier.name}"?',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            if (supplier.totalTransactions > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peringatan: Supplier ini memiliki riwayat mutasi stok. Penghapusan akan ditolak server untuk menjaga integritas data.',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final result = await _supplierService.deleteSupplier(supplier.id);
              if (mounted) {
                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Supplier berhasil dihapus'),
                      backgroundColor: const Color(0xFFE65100),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadSuppliers();
                } else {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Gagal menghapus supplier'),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateSupplier,
        backgroundColor: primaryColor,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          // ── METRIC CARDS HEADER ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    // Total Supplier
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('SUPPLIER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor)),
                                Icon(Icons.business_rounded, size: 14, color: primaryColor),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('$_totalSuppliersCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                            const Text('Mitra terdaftar', style: TextStyle(fontSize: 10, color: Color(0xFFC2410C))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Total Pasokan Masuk
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('PASOKAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                const Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF10B981)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('+$_totalInQty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                            const Text('Barang masuk', style: TextStyle(fontSize: 10, color: Color(0xFF059669))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Total Retur Keluar
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('RETUR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
                                const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFFF43F5E)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('-$_totalOutQty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFBE123C))),
                            const Text('Retur keluar', style: TextStyle(fontSize: 10, color: Color(0xFFE11D48))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── SEARCH BAR ──────────────────────────────────────────
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari supplier, PIC, telepon, atau kode...',
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── DAFTAR SUPPLIER ───────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: 6,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, _) => const SkeletonTransactionTile(),
                  )
                : _filteredSuppliers.isEmpty
                    ? EmptyDataView(
                        icon: Icons.local_shipping_rounded,
                        title: 'Supplier Tidak Ditemukan',
                        subtitle: 'Belum ada data supplier yang cocok dengan kata kunci.',
                        actionLabel: 'Muat Ulang',
                        onAction: _loadSuppliers,
                      )
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: _loadSuppliers,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 84),
                          itemCount: _filteredSuppliers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final s = _filteredSuppliers[index];

                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _openMutations(s),
                                child: Container(
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                      // Top row: Avatar, Name, Action icons
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 19,
                                            backgroundColor: primaryColor.withValues(alpha: 0.12),
                                            child: Text(
                                              s.name.isNotEmpty ? s.name.substring(0, 1).toUpperCase() : 'S',
                                              style: const TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(Icons.person_outline, size: 13, color: Colors.grey.shade600),
                                                    const SizedBox(width: 3),
                                                    Flexible(
                                                      child: Text(
                                                        s.contactPerson != null && s.contactPerson!.isNotEmpty
                                                            ? s.contactPerson!
                                                            : '-',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(0xFF334155),
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (s.phone != null && s.phone!.isNotEmpty) ...[
                                                      const SizedBox(width: 6),
                                                      Text('•', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                                                      const SizedBox(width: 6),
                                                      Icon(Icons.phone_outlined, size: 12, color: Colors.grey.shade600),
                                                      const SizedBox(width: 3),
                                                      Flexible(
                                                        child: Text(
                                                          s.phone!,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Color(0xFF334155),
                                                            fontWeight: FontWeight.w500,
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
                                          // Edit and Delete Icon Actions
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () => _openEditSupplier(s),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(5),
                                                  child: Icon(Icons.edit_outlined, size: 18, color: Colors.blue.shade700),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () => _confirmDeleteSupplier(s),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(5),
                                                  child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade700),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (s.address != null && s.address!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                s.address!,
                                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 9),
                                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      const SizedBox(height: 8),

                                      // Bottom row: Mutation chips + Mutasi shortcut
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFECFDF5),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.arrow_downward_rounded, size: 11, color: Color(0xFF047857)),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      '+${s.totalIn}',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFF1F2),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFFECDD3)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.arrow_upward_rounded, size: 11, color: Color(0xFFBE123C)),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      '-${s.totalOut}',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBE123C)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Riwayat Pasokan',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColor,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              Icon(Icons.arrow_forward_ios_rounded, size: 11, color: primaryColor),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
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
