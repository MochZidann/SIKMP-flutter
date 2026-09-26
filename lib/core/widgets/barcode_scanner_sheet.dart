import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Modal pemindai barcode kamera performa tinggi & berproteksi keamanan data.
/// Mendukung mode single-scan (langsung tutup) dan mode continuous (kamera tetap menyala untuk banyak barang).
class BarcodeScannerSheet extends StatefulWidget {
  final String title;
  final bool isContinuous;
  final FutureOr<String?> Function(String code)? onScanned;

  const BarcodeScannerSheet({
    super.key,
    this.title = 'Pindai Barcode Produk',
    this.isContinuous = false,
    this.onScanned,
  });

  /// Helper statis untuk menampilkan scanner sebagai modal bottom-sheet.
  /// Jika [isContinuous] = true, kamera tidak akan tertutup otomatis setelah scan satu barang,
  /// sehingga kasir bisa terus memindai banyak produk secara beruntun.
  static Future<String?> show(
    BuildContext context, {
    String title = 'Pindai Barcode Produk',
    bool isContinuous = false,
    FutureOr<String?> Function(String code)? onScanned,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: !isContinuous, // Nonaktifkan drag-dismiss pada continuous scan agar tidak sengaja tertutup
      builder: (ctx) => BarcodeScannerSheet(
        title: title,
        isContinuous: isContinuous,
        onScanned: onScanned,
      ),
    );
  }

  /// Sanitizer & Validator keamanan data barcode
  /// Mencegah SQL injection, script injection, dan payload tidak wajar
  static String? sanitizeBarcode(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    // Panjang barcode normal antara 3 hingga 64 karakter
    if (trimmed.length < 3 || trimmed.length > 64) return null;
    // Hanya perbolehkan alfanumerik dan simbol barcode standar
    final safePattern = RegExp(r'^[A-Za-z0-9\-_./]+$');
    if (!safePattern.hasMatch(trimmed)) return null;
    return trimmed;
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  bool _hasDetected = false;
  bool _torchOn = false;
  bool _isSuccessFlash = false;
  String? _lastScannedCode;
  DateTime _lastScannedTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _scannedCount = 0;
  String? _feedbackMessage;
  bool _feedbackIsSuccess = true;
  Timer? _feedbackTimer;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Menggunakan DetectionSpeed.normal dengan timeout 300ms untuk performa stabil di Android CameraX / Xiaomi
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 300,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _feedbackTimer?.cancel();
    _flashTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _triggerSuccessFlash() {
    _flashTimer?.cancel();
    if (mounted) setState(() => _isSuccessFlash = true);
    _flashTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isSuccessFlash = false);
      }
    });
  }

  void _resetFeedbackTimer() {
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() => _feedbackMessage = null);
      }
    });
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_hasDetected && !widget.isContinuous) return;
    if (!widget.isContinuous && _isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      final cleanCode = BarcodeScannerSheet.sanitizeBarcode(rawValue);

      if (cleanCode != null && cleanCode.isNotEmpty) {
        final now = DateTime.now();

        if (widget.isContinuous) {
          // Anti-spam debounce / cooldown proteksi:
          // 1. Jika kode sama persis dengan yang baru discan, jeda minimal 1.6 detik
          if (_lastScannedCode == cleanCode &&
              now.difference(_lastScannedTime).inMilliseconds < 1600) {
            return;
          }
          // 2. Cooldown global minimal 800ms antar barang yang berbeda
          if (now.difference(_lastScannedTime).inMilliseconds < 800) {
            return;
          }

          _lastScannedCode = cleanCode;
          _lastScannedTime = now;

          // Haptic feedback fisik ke kasir
          HapticFeedback.mediumImpact();

          // Efek visual flash hijau pada viewfinder
          _triggerSuccessFlash();

          if (widget.onScanned != null) {
            final feedback = await widget.onScanned!(cleanCode);
            if (!mounted) return;

            setState(() {
              if (feedback != null && feedback.isNotEmpty) {
                _scannedCount++;
                _feedbackMessage = feedback;
                _feedbackIsSuccess = true;
              } else {
                _feedbackMessage = 'Barcode "$cleanCode" tidak ditemukan';
                _feedbackIsSuccess = false;
              }
            });

            _resetFeedbackTimer();
          }
          return;
        } else {
          // Mode Single Scan (bawaan untuk input form / satu barang)
          _hasDetected = true;
          setState(() => _isProcessing = true);
          HapticFeedback.mediumImpact();

          try {
            if (widget.onScanned != null) {
              await widget.onScanned!(cleanCode);
            }
          } finally {
            try {
              await _controller.stop();
            } catch (_) {}
            if (mounted) {
              Navigator.of(context).pop(cleanCode);
            }
          }
          return;
        }
      }
    }
  }

  void _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) {
        setState(() => _torchOn = !_torchOn);
      }
    } catch (_) {}
  }

  void _switchCamera() async {
    try {
      await _controller.switchCamera();
    } catch (_) {}
  }

  Future<void> _closeSheet() async {
    try {
      await _controller.stop();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanWindowSize = size.width * 0.72;

    return Container(
      height: size.height * (widget.isContinuous ? 0.88 : 0.82),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── HEADER MODAL ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isContinuous) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _scannedCount > 0
                                ? const Color(0xFF2E7D32)
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_scannedCount item',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Nyalakan Senter',
                  icon: Icon(
                    _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _torchOn ? Colors.amberAccent : Colors.white70,
                    size: 20,
                  ),
                  onPressed: _toggleTorch,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Putar Kamera',
                  icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white70, size: 20),
                  onPressed: _switchCamera,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  onPressed: _closeSheet,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white12),

          // ── AREA KAMERA DENGAN VIEWFINDER OVERLAY ─────────────────────
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Komponen Scanner Native
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_off_rounded, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'Izin Kamera Ditolak / Kamera Tidak Tersedia',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pastikan memberikan izin kamera di Pengaturan HP untuk memindai barcode secara otomatis.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Frame Viewfinder Kotak Fokus (Flash hijau saat berhasil scan)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: scanWindowSize,
                  height: scanWindowSize * 0.65,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isSuccessFlash ? const Color(0xFF00E676) : Colors.redAccent,
                      width: _isSuccessFlash ? 3.5 : 2.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _isSuccessFlash
                            ? const Color(0xFF00E676).withValues(alpha: 0.4)
                            : Colors.redAccent.withValues(alpha: 0.2),
                        blurRadius: _isSuccessFlash ? 24 : 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // Garis Panduan Laser
                Container(
                  width: scanWindowSize * 0.85,
                  height: 2,
                  color: _isSuccessFlash
                      ? const Color(0xFF00E676).withValues(alpha: 0.9)
                      : Colors.redAccent.withValues(alpha: 0.8),
                ),

                // Floating Banner Hasil Scan Langsung di Bawah Viewfinder
                if (_feedbackMessage != null)
                  Positioned(
                    bottom: 14,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _feedbackIsSuccess
                            ? const Color(0xFF1B5E20).withValues(alpha: 0.95)
                            : const Color(0xFFB71C1C).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _feedbackIsSuccess ? Colors.greenAccent : Colors.redAccent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _feedbackIsSuccess
                                ? Icons.check_circle_rounded
                                : Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _feedbackMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Indikator Loading Saat Berhasil Mendeteksi (Hanya pada mode Single-Scan)
                if (!widget.isContinuous && _isProcessing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),

          // ── FOOTER DENGAN TOMBOL SELESAI SCAN BANYAK BARANG ───────────
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF141414),
            child: SafeArea(
              top: false,
              child: widget.isContinuous
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flash_auto_rounded, color: Colors.greenAccent, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Kamera tetap aktif • Scan barang berikutnya',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _closeSheet,
                            icon: const Icon(Icons.check_circle_rounded, size: 20),
                            label: Text(
                              _scannedCount > 0
                                  ? 'Selesai Scan ($_scannedCount Barang Ditambahkan)'
                                  : 'Selesai & Kembali ke POS',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Posisikan barcode di dalam kotak merah',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
