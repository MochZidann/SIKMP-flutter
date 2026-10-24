import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/member.dart';
import '../../../services/member_service.dart';

class MemberFormDialog extends StatefulWidget {
  final Member? member; // Jika null -> Tambah Baru, Jika tidak null -> Edit
  final VoidCallback onSaved;

  const MemberFormDialog({
    super.key,
    this.member,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    Member? member,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MemberFormDialog(
        member: member,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _pointsController;

  bool _isLoading = false;
  bool get _isEdit => widget.member != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _phoneController = TextEditingController(text: widget.member?.phone ?? '');
    _addressController = TextEditingController(text: widget.member?.address ?? '');
    _pointsController = TextEditingController(text: (widget.member?.points ?? 0).toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final service = MemberService();
    Map<String, dynamic> result;

    if (_isEdit) {
      result = await service.updateMember(
        widget.member!.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        points: int.tryParse(_pointsController.text.trim()) ?? 0,
      );
    } else {
      result = await service.createMember(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        points: int.tryParse(_pointsController.text.trim()) ?? 0,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? (_isEdit ? 'Data anggota diperbarui' : 'Anggota baru berhasil ditambahkan')),
            backgroundColor: const Color(0xFF00897B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memproses data anggota'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00897B);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                          _isEdit ? Icons.edit_note_rounded : Icons.person_add_rounded,
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
                              _isEdit ? 'Edit Data Anggota' : 'Tambah Anggota Baru',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEdit
                                  ? 'Perbarui identitas & poin belanja anggota'
                                  : 'Daftarkan pelanggan tetap sebagai anggota',
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

                  // ── NAMA LENGKAP ─────────────────────────────────────
                  const Text(
                    'Nama Lengkap *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Budi Santoso',
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
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
                        return 'Nama lengkap wajib diisi';
                      }
                      if (v.trim().length < 2) {
                        return 'Nama minimal 2 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── NOMOR TELEPON ────────────────────────────────────
                  const Text(
                    'Nomor Telepon / WhatsApp',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 081234567890',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
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

                  // ── ALAMAT TEMPAT TINGGAL ────────────────────────────
                  const Text(
                    'Alamat Tempat Tinggal',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Alamat lengkap tempat tinggal...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.home_outlined, size: 20),
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

                  // ── POIN BELANJA (HANYA DITAMPILKAN SAAT EDIT) ───────
                  if (_isEdit) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Poin Belanja Anggota',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixIcon: const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                        suffixText: 'Poin',
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
                  ],

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
                          _isLoading ? 'Menyimpan...' : (_isEdit ? 'Perbarui Anggota' : 'Simpan Anggota'),
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
