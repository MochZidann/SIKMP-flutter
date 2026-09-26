import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/qris_response.dart';
import '../../../services/pos_service.dart';

class QrisModalBottomSheet extends StatefulWidget {
  final QrisResponse qris;
  final Function(Map<String, dynamic> receiptData) onSuccess;
  final VoidCallback onCancelled;

  const QrisModalBottomSheet({
    super.key,
    required this.qris,
    required this.onSuccess,
    required this.onCancelled,
  });

  static Future<void> show(
    BuildContext context, {
    required QrisResponse qris,
    required Function(Map<String, dynamic> receiptData) onSuccess,
    required VoidCallback onCancelled,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QrisModalBottomSheet(
        qris: qris,
        onSuccess: onSuccess,
        onCancelled: onCancelled,
      ),
    );
  }

  @override
  State<QrisModalBottomSheet> createState() => _QrisModalBottomSheetState();
}

class _QrisModalBottomSheetState extends State<QrisModalBottomSheet> {
  final PosService _posService = PosService();
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  final ValueNotifier<int> _remainingSecondsNotifier = ValueNotifier<int>(900);
  bool _isCheckingStatus = false;
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void dispose() {
    _stopTimers();
    _remainingSecondsNotifier.dispose();
    super.dispose();
  }

  void _stopTimers() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _startTimers() {
    _stopTimers();

    // 1. Countdown timer 15 menit
    _remainingSecondsNotifier.value = 900;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSecondsNotifier.value <= 1) {
        _stopTimers();
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi QRIS telah kadaluarsa.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _remainingSecondsNotifier.value--;
      }
    });

    // 2. Polling status setiap 3 detik
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isCheckingStatus) return;
      _isCheckingStatus = true;

      try {
        final result = await _posService.checkQrisStatus(widget.qris.orderId);
        if (result.paid || result.status == 'settlement') {
          _stopTimers();
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
            widget.onSuccess(result.data ?? {'transactionId': widget.qris.orderId});
          }
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      } finally {
        _isCheckingStatus = false;
      }
    });
  }

  Future<void> _handleSimulateSandbox() async {
    setState(() => _isSimulating = true);
    final result = await _posService.simulatePayment(widget.qris.orderId);
    if (mounted) setState(() => _isSimulating = false);

    if (result.paid) {
      _stopTimers();
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        widget.onSuccess(result.data ?? {'transactionId': widget.qris.orderId});
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulasi gagal: ${result.message}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmCancelOrder() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan QRIS?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan transaksi pembayaran ini? Kode QR tidak akan dapat digunakan lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog konfirmasi
              _stopTimers();
              await _posService.cancelQris(widget.qris.orderId);
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context); // Tutup bottomsheet QR
              }
              widget.onCancelled();
            },
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header QRIS Dialog
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: Color(0xFFD32F2F),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QRIS DINAMIS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                        if (widget.qris.isSandbox)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SANDBOX MIDTRANS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // Close / Cancel Button
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: _confirmCancelOrder,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Nominal Total Besar
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(widget.qris.grossAmount),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD32F2F),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kartu QRIS Rendered
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Badge Brand Koperasi & GPN/QRIS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/sikmp.png',
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'KOPDES MERAH PUTIH',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: Color(0xFF2B2B2B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // WIDGET QR_FLUTTER
                        RepaintBoundary(
                          child: QrImageView(
                            data: widget.qris.qrString,
                            version: QrVersions.auto,
                            size: 220.0,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),

                        const SizedBox(height: 10),
                        Text(
                          'Scan dengan BCA, GoPay, OVO, Dana, ShopeePay, dll.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Indikator Polling & Countdown Timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Menunggu konfirmasi bayar...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: _remainingSecondsNotifier,
                          builder: (context, remaining, _) {
                            final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
                            final seconds = (remaining % 60).toString().padLeft(2, '0');
                            return Text(
                              '$minutes:$seconds',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Order ID & Salin
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Order ID: ${widget.qris.orderId}',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: widget.qris.orderId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order ID disalin ke clipboard!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tombol Simulasi Bayar Sandbox
                  if (widget.qris.isSandbox)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSimulating ? null : _handleSimulateSandbox,
                        icon: _isSimulating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.flash_on_rounded, size: 18),
                        label: Text(
                          _isSimulating
                              ? 'Memproses Simulasi...'
                              : '⚡ Simulasi Bayar Cepat (Sandbox)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Tombol Batalkan Transaksi
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmCancelOrder,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Batalkan Transaksi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
