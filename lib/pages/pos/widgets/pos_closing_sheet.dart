import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/auth_service.dart';
import '../../../services/pos_service.dart';
import '../../login_page.dart';

class PosClosingSheet extends StatefulWidget {
  final VoidCallback? onClosingSuccess;

  const PosClosingSheet({super.key, this.onClosingSuccess});

  static Future<void> show(BuildContext context, {VoidCallback? onClosingSuccess}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PosClosingSheet(onClosingSuccess: onClosingSuccess),
    );
  }

  @override
  State<PosClosingSheet> createState() => _PosClosingSheetState();
}

class _PosClosingSheetState extends State<PosClosingSheet> {
  final PosService _posService = PosService();
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _summary;

  int _actualCash = 0;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    setState(() => _isLoading = true);
    final user = AuthService().currentUser;
    final summary = await _posService.getClosingSummary(cashierId: user?.id);

    if (mounted) {
      setState(() {
        _summary = summary;
        _isLoading = false;
        // Default uang kas sesuai dengan total tunai
        if (summary != null) {
          final tunai = (summary['tunaiRevenue'] as num?)?.toInt() ?? 0;
          _actualCash = tunai;
          _cashController.text = tunai > 0 ? tunai.toString() : '';
        }
      });
    }
  }

  void _onCashChanged(String val) {
    final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
    final numVal = int.tryParse(cleaned) ?? 0;
    setState(() {
      _actualCash = numVal;
    });
  }

  Future<void> _handleConfirmClosing() async {
    if (_summary == null) return;
    setState(() => _isSubmitting = true);

    final user = AuthService().currentUser;
    final result = await _posService.closeShift(
      cashierId: user?.id,
      actualCash: _actualCash,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null && result['success'] == true) {
      final closingData = result['data'] as Map<String, dynamic>? ?? {};
      Navigator.pop(context); // Tutup bottomsheet
      widget.onClosingSuccess?.call();
      _showClosingSuccessDialog(closingData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?['message'] ?? 'Gagal memproses tutup kasir.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showClosingSuccessDialog(Map<String, dynamic> data) {
    final totalOmzet = (data['totalRevenue'] as num?)?.toInt() ?? 0;
    final totalTrx = (data['totalTransactions'] as num?)?.toInt() ?? 0;
    final tunai = (data['tunaiRevenue'] as num?)?.toInt() ?? 0;
    final qris = (data['qrisRevenue'] as num?)?.toInt() ?? 0;
    final actual = (data['actualCash'] as num?)?.toInt() ?? 0;
    final diff = (data['cashDifference'] as num?)?.toInt() ?? 0;
    final closingTime = data['closingTime'] ?? '';
    final closingDate = data['closingDate'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tutup Kasir Berhasil!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, size: 18, color: Color(0xFFD32F2F)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Laporan ringkasan telah dikirim ke HP Owner via notifikasi FCM.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFFB71C1C), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildReceiptRow('Waktu Closing', '$closingDate, $closingTime WIB'),
              _buildReceiptRow('Total Transaksi', '$totalTrx Penjualan'),
              const Divider(height: 18),
              _buildReceiptRow('Total Omzet', formatRupiah(totalOmzet), isBold: true, valueColor: const Color(0xFFD32F2F)),
              _buildReceiptRow('Penjualan Tunai', formatRupiah(tunai)),
              _buildReceiptRow('Penjualan QRIS', formatRupiah(qris)),
              if (actual > 0) ...[
                const Divider(height: 18),
                _buildReceiptRow('Kas Fisik di Laci', formatRupiah(actual)),
                _buildReceiptRow(
                  'Selisih Kas',
                  diff == 0 ? 'Pas (Sesuai)' : (diff > 0 ? '+${formatRupiah(diff)}' : formatRupiah(diff)),
                  valueColor: diff == 0 ? Colors.green.shade700 : (diff > 0 ? Colors.blue.shade700 : Colors.red.shade700),
                  isBold: true,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tetap di Aplikasi'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AuthService().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
            label: const Text('Logout Kasir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final totalRevenue = (_summary?['totalRevenue'] as num?)?.toInt() ?? 0;
    final totalTransactions = (_summary?['totalTransactions'] as num?)?.toInt() ?? 0;
    final tunaiRevenue = (_summary?['tunaiRevenue'] as num?)?.toInt() ?? 0;
    final tunaiTrx = (_summary?['tunaiTransactions'] as num?)?.toInt() ?? 0;
    final qrisRevenue = (_summary?['qrisRevenue'] as num?)?.toInt() ?? 0;
    final qrisTrx = (_summary?['qrisTransactions'] as num?)?.toInt() ?? 0;
    final cashierName = _summary?['cashierName'] ?? AuthService().currentUser?.name ?? 'Kasir';
    final dateStr = _summary?['date'] ?? '';
    final timeStr = _summary?['time'] ?? '';

    final cashDiff = _actualCash - tunaiRevenue;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFFD32F2F), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tutup Kasir / Closing Shift',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Rekonsiliasi omzet & kirim laporan ke Owner',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                  ),
                ),
              ] else ...[
                // Info Kasir & Waktu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 16, color: Color(0xFFD32F2F)),
                          const SizedBox(width: 6),
                          Text(
                            cashierName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 15, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '$dateStr $timeStr',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Card Ringkasan Omzet Utama
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFF8E0000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Omzet Penjualan Hari Ini',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(totalRevenue),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$totalTransactions Transaksi Berhasil',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Rincian Metode Pembayaran
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.money_rounded, size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Tunai (Cash)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah(tunaiRevenue),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.green.shade900),
                            ),
                            Text('$tunaiTrx transaksi', style: TextStyle(fontSize: 10, color: Colors.green.shade700)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'QRIS Digital',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah(qrisRevenue),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blue.shade900),
                            ),
                            Text('$qrisTrx transaksi', style: TextStyle(fontSize: 10, color: Colors.blue.shade700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Form Rekonsiliasi Kas Laci
                const Text(
                  'Uang Fisik di Laci Kasir (Cash Count)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Masukkan total uang tunai yang ada di laci untuk memeriksa selisih.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  onChanged: _onCashChanged,
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    hintText: '0',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calculate_rounded, size: 20),
                      tooltip: 'Set Sesuai Tunai',
                      onPressed: () {
                        setState(() {
                          _actualCash = tunaiRevenue;
                          _cashController.text = tunaiRevenue.toString();
                        });
                      },
                    ),
                  ),
                ),

                if (_actualCash > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: cashDiff == 0
                          ? Colors.green.shade50
                          : (cashDiff > 0 ? Colors.blue.shade50 : Colors.red.shade50),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cashDiff == 0
                            ? Colors.green.shade200
                            : (cashDiff > 0 ? Colors.blue.shade200 : Colors.red.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cashDiff == 0 ? 'Status Kas Laci' : 'Selisih Kas Laci',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: cashDiff == 0
                                ? Colors.green.shade800
                                : (cashDiff > 0 ? Colors.blue.shade800 : Colors.red.shade800),
                          ),
                        ),
                        Text(
                          cashDiff == 0
                              ? 'PAS (Sesuai Rp ${formatRupiah(tunaiRevenue)})'
                              : (cashDiff > 0
                                  ? 'Surplus +${formatRupiah(cashDiff)}'
                                  : 'Minus ${formatRupiah(cashDiff)}'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cashDiff == 0
                                ? Colors.green.shade900
                                : (cashDiff > 0 ? Colors.blue.shade900 : Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Catatan Kasir (Opsional)
                const Text(
                  'Catatan Shift (Opsional)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Modal awal Rp 100.000 sudah disisihkan...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Konfirmasi Tutup Kasir
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: _isSubmitting ? null : _handleConfirmClosing,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Konfirmasi Tutup Kasir & Kirim Laporan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
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
        ),
      ),
    );
  }
}
