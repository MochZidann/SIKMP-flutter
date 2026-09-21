import 'package:flutter/material.dart';
import '../../../models/store_setting.dart';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';

class StoreSettingsDialog extends StatefulWidget {
  final VoidCallback? onSaved;

  const StoreSettingsDialog({super.key, this.onSaved});

  static Future<void> show(BuildContext context, {VoidCallback? onSaved}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StoreSettingsDialog(onSaved: onSaved),
    );
  }

  @override
  State<StoreSettingsDialog> createState() => _StoreSettingsDialogState();
}

class _StoreSettingsDialogState extends State<StoreSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  StoreSetting? _currentSetting;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    final setting = await _adminService.getStoreSettings();
    if (mounted) {
      if (setting != null) {
        _currentSetting = setting;
        _nameController.text = setting.koperasiName;
        _addressController.text = setting.koperasiAddress;
        _phoneController.text = setting.koperasiPhone;
        _taxController.text = setting.taxPercent.toString();
        _discountController.text = setting.discountPercent.toString();
      } else {
        _nameController.text = 'Koperasi Desa Jajar';
        _taxController.text = '0';
        _discountController.text = '0';
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final currentAdmin = AuthService().currentUser;
    final newSetting = StoreSetting(
      id: _currentSetting?.id,
      koperasiName: _nameController.text.trim(),
      koperasiAddress: _addressController.text.trim(),
      koperasiPhone: _phoneController.text.trim(),
      taxPercent: double.tryParse(_taxController.text.trim()) ?? 0.0,
      discountPercent: double.tryParse(_discountController.text.trim()) ?? 0.0,
    );

    final result = await _adminService.updateStoreSettings(
      newSetting,
      adminId: currentAdmin?.id,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Pengaturan toko berhasil diperbarui'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        widget.onSaved?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan pengaturan'),
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
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(22),
        child: _isLoading
            ? const SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF1976D2)),
                ),
              )
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Dialog
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.store_rounded,
                              color: Color(0xFF1976D2),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Identitas Toko & Struk',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Info kop & pengaturan struk kasir',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
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
                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 18),

                      // Nama Koperasi
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Koperasi / Toko *',
                          prefixIcon: const Icon(Icons.business_rounded, size: 20, color: Color(0xFF1976D2)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nama koperasi tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Alamat
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Alamat Koperasi (Kop Struk)',
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF1976D2)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // No Telepon
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Nomor Telepon / WhatsApp',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF1976D2)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Pajak & Diskon Standar
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _taxController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Pajak / PPN (%)',
                                prefixIcon: const Icon(Icons.percent_rounded, size: 18, color: Color(0xFF1976D2)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _discountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Diskon Umum (%)',
                                prefixIcon: const Icon(Icons.local_offer_outlined, size: 18, color: Color(0xFF1976D2)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Actions
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
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isSaving ? null : _saveSettings,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_rounded, size: 18),
                            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Pengaturan'),
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
