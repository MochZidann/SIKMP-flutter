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
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isEdit ? Icons.edit_note_rounded : Icons.local_shipping_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEdit ? 'Edit Rekanan Supplier' : 'Tambah Rekanan Supplier Baru',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEdit
                                  ? 'Perbarui data vendor rekanan pasokan'
                                  : 'Daftarkan vendor pemasok barang masuk / retur',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: Colors.grey.shade500,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // ── NAMA SUPPLIER ────────────────────────────────────
                  _buildFieldLabel('Nama Supplier / Perusahaan *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      hint: 'Contoh: PT. Sumber Makmur Abadi',
                      prefixIcon: Icons.business_outlined,
                      primaryColor: primaryColor,
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

                  // ── NAMA PIC / KONTAK ────────────────────────────────
                  _buildFieldLabel('Nama PIC / Penanggung Jawab'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _picController,
                    decoration: _inputDecoration(
                      hint: 'Contoh: Bpk. Budi Santoso',
                      prefixIcon: Icons.person_outline_rounded,
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── TELEPON & EMAIL ──────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('No. Telepon / WA'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration(
                                hint: '08123456789',
                                prefixIcon: Icons.phone_outlined,
                                primaryColor: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Email'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration(
                                hint: 'vendor@domain.com',
                                prefixIcon: Icons.email_outlined,
                                primaryColor: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── ALAMAT KANTOR / GUDANG ───────────────────────────
                  _buildFieldLabel('Alamat Kantor / Gudang'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      hint: 'Alamat lengkap distributor / kantor...',
                      prefixIcon: Icons.location_on_outlined,
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── CATATAN / KETERANGAN ─────────────────────────────
                  _buildFieldLabel('Catatan / Keterangan'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      hint: 'Contoh: Jadwal pasokan setiap hari Senin',
                      prefixIcon: Icons.notes_rounded,
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── AKSI TOMBOL SIMPAN & BATAL ───────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          _isLoading ? 'Menyimpan...' : (_isEdit ? 'Simpan Perubahan' : 'Simpan Supplier'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF475569),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    required Color primaryColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
      prefixIcon: Icon(prefixIcon, size: 18, color: Colors.grey.shade500),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
