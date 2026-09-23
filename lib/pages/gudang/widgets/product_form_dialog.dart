import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/barcode_scanner_sheet.dart';
import '../../../models/product.dart';
import '../../../services/auth_service.dart';
import '../../../services/gudang_service.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final VoidCallback? onProductSaved;

  const ProductFormDialog({
    super.key,
    this.product,
    this.onProductSaved,
  });

  static Future<void> show(
    BuildContext context, {
    Product? product,
    VoidCallback? onProductSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProductFormDialog(
        product: product,
        onProductSaved: onProductSaved,
      ),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final GudangService _gudangService = GudangService();

  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _stockCtrl;

  bool _isSaving = false;
  List<String> _categorySuggestions = [];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? 'Umum');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toString() : '');
    _purchasePriceCtrl = TextEditingController(text: p != null ? p.purchasePrice.toString() : '');
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toString() : '0');

    _fetchCategories();
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    final cats = await _gudangService.getCategories();
    if (mounted) {
      setState(() {
        _categorySuggestions = cats
            .map((c) => c['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();
      });
    }
  }

  Future<void> _scanBarcode() async {
    final scanned = await BarcodeScannerSheet.show(
      context,
      title: 'Pindai Barcode Barang',
    );

    if (scanned != null && scanned.isNotEmpty && mounted) {
      setState(() {
        _barcodeCtrl.text = scanned;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode terbaca: $scanned'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFFE65100),
        ),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final currentUserId = AuthService().currentUser?.id;
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    final purchasePrice = int.tryParse(_purchasePriceCtrl.text.trim()) ?? 0;
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;

    final productData = Product(
      id: widget.product?.id ?? 0,
      name: _nameCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
      category: _categoryCtrl.text.trim().isNotEmpty ? _categoryCtrl.text.trim() : 'Umum',
      price: price,
      purchasePrice: purchasePrice,
      stock: stock,
      minimumStock: 5,
      imagePath: widget.product?.imagePath,
    );

    final result = _isEdit
        ? await _gudangService.updateProduct(productData, userId: currentUserId)
        : await _gudangService.storeProduct(productData, userId: currentUserId);

    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Berhasil disimpan'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        widget.onProductSaved?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan barang'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER DIALOG ──────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isEdit ? Icons.edit_note_rounded : Icons.add_box_rounded,
                        color: const Color(0xFFE65100),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEdit ? 'Edit Data Barang' : 'Tambah Barang Baru',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _isEdit ? 'Ubah informasi katalog barang' : 'Registrasi barang baru ke sistem',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // ── INPUT BARCODE DENGAN SCANNER KAMERA ─────────────────
                TextFormField(
                  controller: _barcodeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Barcode / Kode EAN-13',
                    hintText: 'Pindai atau ketik barcode...',
                    prefixIcon: const Icon(Icons.qr_code_rounded, color: Color(0xFFE65100), size: 20),
                    suffixIcon: Tooltip(
                      message: 'Scan Barcode Kamera',
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFE65100)),
                        onPressed: _isSaving ? null : _scanBarcode,
                      ),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // ── INPUT NAMA BARANG ──────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nama Barang *',
                    hintText: 'Contoh: Minyak Goreng 1L',
                    prefixIcon: const Icon(Icons.inventory_2_outlined, color: Color(0xFFE65100), size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama barang wajib diisi';
                    }
                    if (v.trim().length < 2) {
                      return 'Nama barang minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── INPUT KATEGORI ─────────────────────────────────────
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _categoryCtrl.text),
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _categorySuggestions;
                    }
                    return _categorySuggestions.where((cat) =>
                        cat.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (val) {
                    _categoryCtrl.text = val;
                  },
                  fieldViewBuilder: (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
                    // Sync controller
                    fieldTextEditingController.addListener(() {
                      _categoryCtrl.text = fieldTextEditingController.text;
                    });
                    return TextFormField(
                      controller: fieldTextEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Kategori Barang',
                        hintText: 'Pilih atau ketik kategori baru',
                        prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFFE65100), size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // ── HARGA JUAL & HARGA BELI / MODAL ────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Harga Jual (Rp) *',
                          prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFFE65100), size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          final p = int.tryParse(v.trim());
                          if (p == null || p < 0) {
                            return 'Format salah';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _purchasePriceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Harga Modal (Rp)',
                          prefixIcon: const Icon(Icons.price_change_outlined, color: Color(0xFFE65100), size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── JUMLAH STOK BARANG ────────────────────────────────
                TextFormField(
                  controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _isEdit ? 'Stok Barang' : 'Stok Awal',
                    hintText: 'Masukkan jumlah stok...',
                    prefixIcon: const Icon(Icons.warehouse_rounded, color: Color(0xFFE65100), size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Isi stok (min 0)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                // ── ACTION BUTTONS ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _saveProduct,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(_isSaving ? 'Menyimpan...' : (_isEdit ? 'Simpan Perubahan' : 'Simpan Barang')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
