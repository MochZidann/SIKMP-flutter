import 'package:flutter/material.dart';
import '../../../services/pos_service.dart';

class PosSettingsDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const PosSettingsDialog({super.key, required this.onSaved});

  static Future<void> show(BuildContext context, {required VoidCallback onSaved}) {
    return showDialog(
      context: context,
      builder: (ctx) => PosSettingsDialog(onSaved: onSaved),
    );
  }

  @override
  State<PosSettingsDialog> createState() => _PosSettingsDialogState();
}

class _PosSettingsDialogState extends State<PosSettingsDialog> {
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: PosService.baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _save() {
    PosService.baseUrl = _urlCtrl.text.trim();
    Navigator.pop(context);
    widget.onSaved();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alamat API berhasil diperbarui!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pengaturan API Backend'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alamat URL Laravel API (POS):',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlCtrl,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
              hintText: 'http://10.0.2.2:8000/api/pos',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Petunjuk:\n'
            '• Android Emulator: http://10.0.2.2:8000/api/pos\n'
            '• Laragon Apache: http://10.0.2.2/api-koperasi/public/api/pos\n'
            '• HP Fisik (WiFi): http://[IP_PC_ANDA]:8000/api/pos',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
          onPressed: _save,
          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
