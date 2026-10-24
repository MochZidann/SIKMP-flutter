import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/product.dart';
import '../../../models/supplier.dart';
import '../../../services/gudang_service.dart';
import '../../../services/supplier_service.dart';

class StockInDialog extends StatefulWidget {
  final Product product;
  final VoidCallback onStockUpdated;

  const StockInDialog({
    super.key,
    required this.product,
    required this.onStockUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    required VoidCallback onStockUpdated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StockInDialog(
        product: product,
        onStockUpdated: onStockUpdated,
      ),
    );
  }

  @override
  State<StockInDialog> createState() => _StockInDialogState();
}

class _StockInDialogState extends State<StockInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController(text: '');
  final _refController = TextEditingController();
  final _noteController = TextEditingController();

  int? _selectedSupplierId;
  List<Supplier> _suppliers = [];
  bool _isLoadingSuppliers = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _refController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      final list = await SupplierService().getSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = list;
          _isLoadingSuppliers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSuppliers = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah barang masuk minimal 1 unit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await GudangService().recordStockIn(
      product: widget.product,
      quantity: qty,
      supplierId: _selectedSupplierId,
      referenceNo: _refController.text.trim().isEmpty ? null : _refController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res['success'] == true) {
        Navigator.pop(context);
        widget.onStockUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Stok masuk berhasil dicatat'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal mencatat stok masuk'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF059669);
    const lightMint = Color(0xFFD1FAE5);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER MODAL ─────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: lightMint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: primaryGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stok Masuk (Pasokan)',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 3),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF4B5563),
                                ),
                                children: [
                                  TextSpan(
                                    text: widget.product.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const TextSpan(text: '  •  Stok saat ini: '),
                                  TextSpan(
                                    text: '${widget.product.stock} unit',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 22),
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 16),

                  // ── SUPPLIER / PEMASOK (OPSIONAL) ─────────────────────
                  const Text(
                    'Supplier / Pemasok (Opsional)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedSupplierId,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF1F2937)),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          '-- Tanpa Supplier / Sumber Lain --',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13.5),
                        ),
                      ),
                      if (!_isLoadingSuppliers)
                        ..._suppliers.map(
                          (s) => DropdownMenuItem<int?>(
                            value: s.id,
                            child: Text(
                              s.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedSupplierId = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── ROW: JUMLAH MASUK & NO. REFERENSI ─────────────────
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 340;
                      final leftField = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4B5563),
                              ),
                              children: [
                                TextSpan(text: 'Jumlah Masuk '),
                                TextSpan(
                                  text: '*',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              hintText: '0',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                              final n = int.tryParse(v.trim());
                              if (n == null || n <= 0) return 'Min 1';
                              return null;
                            },
                          ),
                        ],
                      );

                      final rightField = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No. Referensi / Surat Jalan',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _refController,
                            decoration: InputDecoration(
                              hintText: 'Contoh:  SJ-2026/089',
                              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            leftField,
                            const SizedBox(height: 14),
                            rightField,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: leftField),
                          const SizedBox(width: 12),
                          Expanded(child: rightField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── CATATAN (OPSIONAL) ───────────────────────────────
                  const Text(
                    'Catatan (Opsional)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Keterangan pasokan masuk...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── ACTION BUTTONS ───────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          foregroundColor: const Color(0xFF374151),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Simpan Stok Masuk',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
