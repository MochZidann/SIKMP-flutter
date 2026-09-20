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
  late final TextEditingController _stockController;
  final _noteController = TextEditingController(text: 'Hasil Stock Opname Fisik');
  bool _isLoading = false;

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
    final newStock = int.tryParse(_stockController.text);
    if (newStock == null || newStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal stok fisik tidak valid')),
      );
      return;
    }

    if (newStock == widget.product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok baru sama dengan stok saat ini.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await GudangService().adjustStock(
      product: widget.product,
      newStock: newStock,
      note: _noteController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        widget.onStockUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stok ${widget.product.name} disesuaikan menjadi $newStock unit!'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal menyesuaikan stok.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStock = widget.product.stock;
    final enteredStock = int.tryParse(_stockController.text) ?? currentStock;
    final delta = enteredStock - currentStock;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.tune_rounded, color: Colors.blueGrey.shade700),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Stock Opname / Penyesuaian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              'Stok tercatat sistem: $currentStock unit',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            const Text('Jumlah Stok Fisik Riil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Stok aktual di gudang',
                prefixIcon: const Icon(Icons.inventory_rounded, size: 20),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),

            // Selisih Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: delta == 0
                    ? Colors.grey.shade100
                    : delta > 0
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Selisih Stok:', style: TextStyle(fontSize: 11)),
                  Text(
                    delta > 0 ? '+$delta unit (Surplus)' : delta < 0 ? '$delta unit (Selisih Kurang)' : '0 (Cocok)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: delta > 0 ? Colors.green.shade800 : delta < 0 ? Colors.red.shade800 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Text('Alasan Penyesuaian', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Misal: Barang rusak / selisih hitung fisik',
                prefixIcon: const Icon(Icons.description_outlined, size: 20),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade800,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan Opname'),
        ),
      ],
    );
  }
}
