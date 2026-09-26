import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/barcode_scanner_sheet.dart';
import '../../../core/widgets/product_image_widget.dart';
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

  // ── MANAJEMEN FOTO BARANG ──────────────────────────────────────
  final ImagePicker _picker = ImagePicker();
  Uint8List? _pickedImageBytes;
  String? _pickedImageBase64;
  bool _removeImage = false;

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null) {
        final length = await image.length();
        // Keamanan & Performa: Batasi foto maksimal 5MB sebelum diproses
        if (length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ukuran foto terlalu besar (maksimal 5MB). Silakan gunakan foto yang lebih kecil.'),
                backgroundColor: Color(0xFFC62828),
              ),
            );
          }
          return;
        }

        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageBase64 = base64Encode(bytes);
          _removeImage = false;
        });
      }
    } on MissingPluginException {
      if (mounted) {
        _showRestartNoticeDialog();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      final errorStr = e.toString();
      if (errorStr.contains('MissingPluginException')) {
        if (mounted) _showRestartNoticeDialog();
        return;
      }

      String message = 'Gagal memilih foto: $e';
      if (errorStr.contains('permission') || errorStr.contains('denied')) {
        message = 'Izin kamera / galeri ditolak. Harap izinkan akses kamera pada pengaturan aplikasi.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showRestartNoticeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: Color(0xFFE65100), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Perlu Restart Aplikasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Plugin kamera & galeri baru saja dipasang ke dalam kode Flutter.\n\n'
          'Karena Android memerlukan pendaftaran channel native yang baru di APK, Hot Reload tidak dapat menerapkannya saat aplikasi sedang aktif.\n\n'
          'Silakan STOP debug / tutup aplikasi sepenuhnya, lalu jalankan kembali (flutter run).',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Foto Barang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFE65100)),
                ),
                title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Foto langsung menggunakan kamera perangkat'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pilih foto barang dari galeri perangkat'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_pickedImageBytes != null ||
                  (!_removeImage &&
                      widget.product?.imagePath != null &&
                      widget.product!.imagePath!.isNotEmpty)) ...[
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: const Text('Hapus Foto', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Hapus foto dari barang ini'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedImageBytes = null;
                      _pickedImageBase64 = null;
                      _removeImage = true;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final currentUserId = AuthService().currentUser?.id;
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    final purchasePrice = int.tryParse(_purchasePriceCtrl.text.trim()) ?? 0;
    // Pada mode edit, stok dipertahankan dari data asli (tidak diubah langsung)
    final stock = _isEdit
        ? (widget.product?.stock ?? 0)
        : (int.tryParse(_stockCtrl.text.trim()) ?? 0);

    final productData = Product(
      id: widget.product?.id ?? 0,
      name: _nameCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
      category: _categoryCtrl.text.trim().isNotEmpty ? _categoryCtrl.text.trim() : 'Umum',
      price: price,
      purchasePrice: purchasePrice,
      stock: stock,
      minimumStock: widget.product?.minimumStock ?? 5,
      imagePath: widget.product?.imagePath,
    );

    final result = _isEdit
        ? await _gudangService.updateProduct(
            productData,
            userId: currentUserId,
            imageBase64: _pickedImageBase64,
            removeImage: _removeImage,
          )
        : await _gudangService.storeProduct(
            productData,
            userId: currentUserId,
            imageBase64: _pickedImageBase64,
          );

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

                // ── UPLOAD FOTO PRODUK ─────────────────────────────────
                _buildImagePickerSection(),

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
                // ── JUMLAH STOK AWAL (HANYA SAAT TAMBAH BARANG BARU) ──
                if (!_isEdit) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Stok Awal Barang *',
                      hintText: 'Masukkan jumlah stok awal...',
                      helperText: 'Hanya diisi saat awal pendaftaran master barang',
                      prefixIcon: const Icon(Icons.warehouse_rounded, color: Color(0xFFE65100), size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Isi stok awal (min 0)';
                      }
                      return null;
                    },
                  ),
                ],
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

  Widget _buildImagePickerSection() {
    final hasNewImage = _pickedImageBytes != null;
    final hasExistingImage = !_removeImage &&
        widget.product?.imagePath != null &&
        widget.product!.imagePath!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (hasNewImage || hasExistingImage)
              ? const Color(0xFFE65100).withValues(alpha: 0.4)
              : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Preview Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: hasNewImage
                  ? Image.memory(
                      _pickedImageBytes!,
                      fit: BoxFit.cover,
                    )
                  : hasExistingImage
                      ? ProductImageWidget(
                          imagePath: widget.product!.imagePath,
                          category: _categoryCtrl.text,
                          size: 64,
                          borderRadius: BorderRadius.circular(10),
                        )
                      : Container(
                          color: const Color(0xFFE65100).withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            color: Color(0xFFE65100),
                            size: 28,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 14),

          // Action Info & Buttons
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hasNewImage
                          ? 'Foto Baru Dipilih'
                          : hasExistingImage
                              ? 'Foto Barang Aktif'
                              : 'Foto Produk (Opsional)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasNewImage) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade400, width: 0.5),
                        ),
                        child: Text(
                          'BARU',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  (hasNewImage || hasExistingImage)
                      ? 'Format JPG/PNG, tampil di katalog & kasir'
                      : 'Ambil foto dari kamera atau galeri',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: _isSaving ? null : _showImagePickerOptions,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (hasNewImage || hasExistingImage)
                                  ? Icons.cameraswitch_rounded
                                  : Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (hasNewImage || hasExistingImage) ? 'Ganti Foto' : 'Pilih Foto',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (hasNewImage || hasExistingImage) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _pickedImageBytes = null;
                                  _pickedImageBase64 = null;
                                  _removeImage = true;
                                });
                              },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  color: Colors.red.shade700, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Hapus',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

