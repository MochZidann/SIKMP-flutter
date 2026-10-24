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
  late final TextEditingController _codeController;
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
    _codeController = TextEditingController(text: widget.supplier?.code ?? '');
    _picController = TextEditingController(text: widget.supplier?.contactPerson ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');
    _emailController = TextEditingController(text: widget.supplier?.email ?? '');
    _addressController = TextEditingController(text: widget.supplier?.address ?? '');
    _noteController = TextEditingController(text: widget.supplier?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
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
        code: _codeController.text.trim(),
        contactPerson: _picController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        note: _noteController.text.trim(),
      );
    } else {
      result = await service.createSupplier(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
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
            backgroundColor: const Color(0xFF7C3AED),
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
    const primaryColor = Color(0xFF7C3AED);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
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
                              _isEdit ? 'Edit Data Rekanan Supplier' : 'Tambah Rekanan Supplier Baru',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEdit
                                  ? 'Perbarui identitas & kontak vendor rekanan'
                                  : 'Daftarkan vendor pemasok barang masuk / retur',
                              style: TextStyle(
                                fontSize: 12,
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
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 18),

                  // ── NAMA SUPPLIER ────────────────────────────────────
                  const Text(
                    'Nama Supplier / Perusahaan *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: PT. Sumber Makmur Abadi',
                      prefixIcon: const Icon(Icons.business_outlined, size: 20),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
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

                  // ── KODE SUPPLIER & NAMA PIC ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kode Supplier (Opsional)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _codeController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'Otomatis dibuat',
                                prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: primaryColor, width: 2),
                                ),
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
                            const Text(
                              'Nama PIC / Kontak',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _picController,
                              decoration: InputDecoration(
                                hintText: 'Bpk. Ahmad',
                                prefixIcon: const Icon(Icons.person_outline, size: 18),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: primaryColor, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── NO TELEPON & EMAIL ───────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'No. Telepon / WhatsApp',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: '081234567890',
                                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: primaryColor, width: 2),
                                ),
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
                            const Text(
                              'Email Supplier',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'vendor@email.com',
                                prefixIcon: const Icon(Icons.email_outlined, size: 18),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: primaryColor, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── ALAMAT KANTOR / GUDANG ───────────────────────────
                  const Text(
                    'Alamat Kantor / Gudang',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Alamat lengkap distributor / pabrik...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.location_on_outlined, size: 18),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── CATATAN SUPPLIER ─────────────────────────────────
                  const Text(
                    'Catatan / Keterangan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Jadwal pasokan setiap hari Senin...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.notes_rounded, size: 18),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── ACTION BUTTONS ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(_isEdit ? Icons.check_circle_rounded : Icons.save_rounded, size: 18, color: Colors.white),
                        label: Text(
                          _isLoading ? 'Menyimpan...' : (_isEdit ? 'Perbarui Supplier' : 'Simpan Supplier'),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          elevation: 0,
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
