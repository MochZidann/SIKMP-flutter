import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/barcode_scanner_sheet.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../core/widgets/header_curve_clipper.dart';
import '../../../models/stock_movement.dart';
import '../../../services/gudang_service.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/stock_adjust_dialog.dart';
import '../widgets/stock_in_dialog.dart';

class GudangDashboardTab extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const GudangDashboardTab({super.key, this.onNavigateTab});

  @override
  State<GudangDashboardTab> createState() => _GudangDashboardTabState();
}

class _GudangDashboardTabState extends State<GudangDashboardTab> {
  final GudangService _gudangService = GudangService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final stats = await _gudangService.getInventoryStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _quickScanBarcode() async {
    final scannedCode = await BarcodeScannerSheet.show(
      context,
      title: 'Scan Cepat Barang Gudang',
    );

    if (scannedCode == null || !mounted) return;

    final products = await _gudangService.getProducts();
    final matched = products.where((p) =>
        p.barcode?.trim().toLowerCase() == scannedCode.toLowerCase() ||
        p.id.toString() == scannedCode).firstOrNull;

    if (!mounted) return;

    if (matched != null) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matched.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Barcode: ${matched.barcode ?? '-'} | Stok Saat Ini: ${matched.stock} unit',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('+ Restock Masuk'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        StockInDialog.show(
                          context,
                          product: matched,
                          onStockUpdated: _loadDashboardData,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE65100),
                        side: const BorderSide(color: Color(0xFFE65100)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Stock Opname'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        StockAdjustDialog.show(
                          context,
                          product: matched,
                          onStockUpdated: _loadDashboardData,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)));
    }

    final totalProducts = _stats['totalProducts'] ?? 0;
    final lowStockCount = _stats['lowStockCount'] ?? 0;
    final outOfStockCount = _stats['outOfStockCount'] ?? 0;
    final totalValuation = _stats['totalValuation'] ?? 0;
    final todayMovements = _stats['todayMovements'] ?? 0;
    final recentMovements = _stats['recentMovements'] as List<StockMovement>? ?? [];
    final displayedMovements = recentMovements.take(5).toList();

    return RefreshIndicator(
      color: const Color(0xFFE65100),
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── BANNER HEADER GUDANG DENGAN BACKGROUND MELENGKUNG ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Background Oranye Melengkung di Tengah ke Bawah
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 35,
                  child: ClipPath(
                    clipper: const HeaderCurveClipper(),
                    child: Container(
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ),

                // Card 2 Layer (Layer 1: Putih, Layer 2: Oranye Solid)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── LAYER KEDUA (BERWARNA ORANYE SOLID) ───────────
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE65100),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE65100).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 22),
                                      ),
                                      const SizedBox(width: 10),
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ADMIN GUDANG',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14.5,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Manajemen Logistik & Stok Toko',
                                            style: TextStyle(color: Colors.white70, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$todayMovements Mutasi Hari Ini',
                                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Estimasi Nilai Aset Inventaris',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formatRupiah(totalValuation),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── LAYER PERTAMA WARNA PUTIH (DI BAWAH LAYER ORANYE): AKSI CEPAT ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 3.5,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE65100),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Aksi Gudang Cepat',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2B2B2B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildQuickActionBtn(
                                    title: 'Tambah Stok',
                                    icon: Icons.add_box_rounded,
                                    color: const Color(0xFFE65100),
                                    onTap: () {
                                      ProductFormDialog.show(context, onProductSaved: _loadDashboardData);
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  _buildQuickActionBtn(
                                    title: 'Scan Barcode',
                                    icon: Icons.qr_code_scanner_rounded,
                                    color: const Color(0xFFD84315),
                                    onTap: _quickScanBarcode,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildQuickActionBtn(
                                    title: 'Katalog',
                                    icon: Icons.inventory_2_outlined,
                                    color: const Color(0xFF00897B),
                                    onTap: () => widget.onNavigateTab?.call(1),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildQuickActionBtn(
                                    title: 'Mutasi',
                                    icon: Icons.swap_vert_rounded,
                                    color: const Color(0xFF5D4037),
                                    onTap: () => widget.onNavigateTab?.call(2),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

            // ── METRIK STATUS INVENTARIS (KOMPAK SEPERTI KASIR) ─────────
            const Text(
              'Status Inventaris',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 10),

            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Total Varian Barang',
                      value: '$totalProducts SKU',
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFFE65100),
                      subtitle: 'Katalog Aktif',
                      onTap: () => widget.onNavigateTab?.call(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Stok Kritis (< 5)',
                      value: '$lowStockCount Item',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.amber.shade900,
                      subtitle: lowStockCount > 0 ? 'Perlu Restock' : 'Aman',
                      onTap: () => widget.onNavigateTab?.call(1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Stok Habis (0)',
                      value: '$outOfStockCount Item',
                      icon: Icons.remove_shopping_cart_rounded,
                      color: Colors.red.shade700,
                      subtitle: outOfStockCount > 0 ? 'Segera Pesan' : 'Nihil',
                      onTap: () => widget.onNavigateTab?.call(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Mutasi Stok',
                      value: '$todayMovements Kali',
                      icon: Icons.swap_vert_rounded,
                      color: const Color(0xFF00897B),
                      subtitle: 'Hari Ini',
                      onTap: () => widget.onNavigateTab?.call(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),


            // ── RECENT MUTATIONS LIST ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pergerakan Stok Terkini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2B2B2B)),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab?.call(2),
                  child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFFE65100))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (displayedMovements.isEmpty)
              const EmptyDataView(
                icon: Icons.swap_vert_rounded,
                title: 'Belum Ada Mutasi Stok',
                subtitle: 'Pencatatan barang masuk atau opname akan tampil di sini.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedMovements.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final move = displayedMovements[index];
                  final isIn = move.isIn;
                  final isAdjust = move.isAdjust;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isIn
                              ? Colors.green.shade50
                              : isAdjust
                                  ? Colors.blueGrey.shade50
                                  : Colors.red.shade50,
                          child: Icon(
                            isIn
                                ? Icons.arrow_downward_rounded
                                : isAdjust
                                    ? Icons.tune_rounded
                                    : Icons.arrow_upward_rounded,
                            color: isIn
                                ? Colors.green.shade700
                                : isAdjust
                                    ? Colors.blueGrey.shade700
                                    : Colors.red.shade700,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                move.type == 'IN'
                                    ? 'BARANG MASUK (+${move.quantityDelta})'
                                    : move.type == 'ADJUST'
                                        ? 'STOCK OPNAME (${move.quantityDelta >= 0 ? '+' : ''}${move.quantityDelta})'
                                        : 'BARANG KELUAR (${move.quantityDelta})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isIn
                                      ? Colors.green.shade800
                                      : isAdjust
                                          ? Colors.blueGrey.shade800
                                          : Colors.red.shade800,
                                ),
                              ),
                              if (move.note != null && move.note!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  move.note!,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          DateHelper.formatEpochMs(move.createdAtEpochMs),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (subtitle != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B2B2B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required String title,
    String? assetPath,
    IconData? icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: assetPath != null
                      ? Image.asset(
                          assetPath,
                          width: 24,
                          height: 24,
                          color: color,
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(icon ?? Icons.circle, color: color, size: 24),
                        )
                      : Icon(icon ?? Icons.circle, color: color, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
