import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/product.dart';
import '../../../services/gudang_service.dart';

class StockAdjustDialog extends StatefulWidget {
  final Product product;
  final VoidCallback onStockUpdated;

  const StockAdjustDialog({
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
      builder: (ctx) => StockAdjustDialog(
        product: product,
        onStockUpdated: onStockUpdated,
      ),
    );
  }

  @override
  State<StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends State<StockAdjustDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stockController;
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(text: widget.product.stock.toString());
  }

  @override
  void dispose() {
    _stockController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final newStock = int.tryParse(_stockController.text.trim());
    if (newStock == null || newStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal stok fisik tidak valid (minimal 0)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await GudangService().adjustStock(
      product: widget.product,
      newStock: newStock,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res['success'] == true) {
        Navigator.pop(context);
        widget.onStockUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Penyesuaian stok berhasil disimpan'),
            backgroundColor: const Color(0xFF2563EB),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal menyesuaikan stok'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const lightBlue = Color(0xFFDBEAFE);

    final enteredStock = int.tryParse(_stockController.text.trim()) ?? widget.product.stock;
    final delta = enteredStock - widget.product.stock;

    final selisihText = delta > 0
        ? 'Selisih: +$delta unit'
        : delta < 0
            ? 'Selisih: $delta unit'
            : 'Selisih: +0 unit';

    final selisihColor = delta >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626);

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
                          color: lightBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sync_rounded,
                          color: primaryBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Penyesuaian Stok (Opname)',
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
                                      color: primaryBlue,
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

                  // ── STOK FISIK SEBENARNYA ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                          children: [
                            TextSpan(text: 'Stok Fisik Sebenarnya '),
                            TextSpan(
                              text: '*',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        selisihText,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: selisihColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
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
                        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 0) return 'Stok minimal 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── CATATAN / ALASAN PENYESUAIAN (OPSIONAL) ────────────
                  const Text(
                    'Catatan / Alasan Penyesuaian (Opsional)',
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
                      hintText: 'Hasil stock opname bulanan...',
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
                        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
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
                          backgroundColor: primaryBlue,
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
                                'Simpan Penyesuaian',
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
