import 'package:flutter/material.dart';
import '../../../models/supplier.dart';
import '../../../services/supplier_service.dart';

class SupplierFormDialog extends StatefulWidget {
  final Supplier? supplier; // Jika null -> Tambah Baru, Jika tidak null -> Edit
  final VoidCallback onSaved;

  const SupplierFormDialog({
    super.key,
    this.supplier,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    Supplier? supplier,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SupplierFormDialog(
        supplier: supplier,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _picController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _noteController;

  bool _isLoading = false;
  bool get _isEdit => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _picController = TextEditingController(text: widget.supplier?.contactPerson ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');
    _emailController = TextEditingController(text: widget.supplier?.email ?? '');
    _addressController = TextEditingController(text: widget.supplier?.address ?? '');
    _noteController = TextEditingController(text: widget.supplier?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _picController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final service = SupplierService();
    Map<String, dynamic> result;

    if (_isEdit) {
      result = await service.updateSupplier(
        widget.supplier!.id,
        name: _nameController.text.trim(),
        code: widget.supplier!.code,
        contactPerson: _picController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        note: _noteController.text.trim(),
      );
    } else {
      result = await service.createSupplier(
        name: _nameController.text.trim(),
        code: '', // Kosongkan agar backend meng-generate SUP-xxxx secara otomatis
        contactPerson: _picController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        note: _noteController.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? (_isEdit ? 'Supplier berhasil diperbarui' : 'Supplier berhasil ditambahkan')),
            backgroundColor: const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memproses supplier'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
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
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isEdit ? Icons.edit_note_rounded : Icons.add_business_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEdit ? 'Edit Data Rekanan' : 'Tambah Rekanan Supplier Baru',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _isEdit ? 'Perbarui informasi vendor rekanan' : 'Daftarkan vendor pemasok barang ke koperasi',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // ── NAMA PERUSAHAAN / SUPPLIER ─────────────────────────
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nama Supplier / Perusahaan *',
                    hintText: 'Contoh: PT. Sumber Makmur Abadi',
                    prefixIcon: const Icon(Icons.business_rounded, color: primaryColor, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama supplier wajib diisi';
                    }
                    if (v.trim().length < 2) {
                      return 'Nama supplier minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── NAMA PIC / KONTAK ──────────────────────────────────
                TextFormField(
                  controller: _picController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nama PIC / Kontak',
                    hintText: 'Contoh: Bpk. Budi Santoso',
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: primaryColor, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // ── TELEPON & EMAIL (2 KOLOM SEJAJAR RAPI) ─────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'No. Telepon / WA',
                          hintText: '08123456789',
                          prefixIcon: const Icon(Icons.phone_outlined, color: primaryColor, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Supplier',
                          hintText: 'vendor@domain.com',
                          prefixIcon: const Icon(Icons.email_outlined, color: primaryColor, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── ALAMAT KANTOR / GUDANG ─────────────────────────────
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Alamat Kantor / Gudang',
                    hintText: 'Alamat lengkap distributor / pabrik...',
                    prefixIcon: const Icon(Icons.location_on_outlined, color: primaryColor, size: 20),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // ── CATATAN / KETERANGAN ───────────────────────────────
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Catatan / Keterangan',
                    hintText: 'Contoh: Jadwal pasokan rutin setiap Senin',
                    prefixIcon: const Icon(Icons.notes_rounded, color: primaryColor, size: 20),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // ── ACTION BUTTONS ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        _isLoading
                            ? 'Menyimpan...'
                            : (_isEdit ? 'Simpan Perubahan' : 'Simpan Supplier'),
                      ),
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
