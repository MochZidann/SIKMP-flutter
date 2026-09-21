import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Modal pemindai barcode kamera performa tinggi & berproteksi keamanan data
class BarcodeScannerSheet extends StatefulWidget {
  final String title;
  final ValueChanged<String>? onScanned;

  const BarcodeScannerSheet({
    super.key,
    this.title = 'Pindai Barcode Produk',
    this.onScanned,
  });

  /// Helper statis untuk menampilkan scanner sebagai modal bottom-sheet
  /// Mengembalikan nilai barcode yang terverifikasi & disanitasi secara aman
  static Future<String?> show(
    BuildContext context, {
    String title = 'Pindai Barcode Produk',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) => BarcodeScannerSheet(
        title: title,
        onScanned: (code) => Navigator.of(ctx).pop(code),
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

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    // Optimasi performa: detectionSpeed noDuplicates mengurangi frekuensi event
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    // Pencegahan memory leak & battery drain: stop dan dispose kamera seketika
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    // Atomic lock untuk mencegah multi-trigger (anti double-entry)
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      final cleanCode = BarcodeScannerSheet.sanitizeBarcode(rawValue);

      if (cleanCode != null && cleanCode.isNotEmpty) {
        setState(() => _isProcessing = true);
        // Haptic feedback untuk konfirmasi fisik ke user
        HapticFeedback.mediumImpact();

        if (widget.onScanned != null) {
          widget.onScanned!(cleanCode);
        } else {
          Navigator.of(context).pop(cleanCode);
        }
        return;
      }
    }
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  void _switchCamera() async {
    await _controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanWindowSize = size.width * 0.72;

    return Container(
      height: size.height * 0.82,
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
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.redAccent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
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
                  onPressed: () => Navigator.of(context).pop(),
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

                // Frame Viewfinder Kotak Fokus
                Container(
                  width: scanWindowSize,
                  height: scanWindowSize * 0.65,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.redAccent, width: 2.5),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // Garis Panduan Animasi / Laser
                Container(
                  width: scanWindowSize * 0.85,
                  height: 2,
                  color: Colors.redAccent.withValues(alpha: 0.8),
                ),

                // Indikator Loading Saat Berhasil Mendeteksi
                if (_isProcessing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),

          // ── FOOTER PETUNJUK PENGGUNA ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF141414),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Posisikan barcode di dalam kotak merah',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
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
