import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/cashier_shift_model.dart';
import '../../../services/owner_shift_service.dart';

class OwnerShiftDetailSheet extends StatefulWidget {
  final CashierShiftModel shift;
  final VoidCallback onReviewed;

  const OwnerShiftDetailSheet({
    super.key,
    required this.shift,
    required this.onReviewed,
  });

  static Future<void> show(
    BuildContext context, {
    required CashierShiftModel shift,
    required VoidCallback onReviewed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OwnerShiftDetailSheet(
        shift: shift,
        onReviewed: onReviewed,
      ),
    );
  }

  @override
  State<OwnerShiftDetailSheet> createState() => _OwnerShiftDetailSheetState();
}

class _OwnerShiftDetailSheetState extends State<OwnerShiftDetailSheet> {
  final TextEditingController _reviewNoteController = TextEditingController();
  final OwnerShiftService _shiftService = OwnerShiftService();

  bool _isLoadingDetail = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _detailData;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _reviewNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoadingDetail = true);
    final res = await _shiftService.getShiftDetail(widget.shift.id);

    if (mounted) {
      setState(() {
        _isLoadingDetail = false;
        if (res['success'] == true) {
          _detailData = res['data'] as Map<String, dynamic>?;
          if (_detailData?['review_note'] != null) {
            _reviewNoteController.text = _detailData!['review_note'];
          }
        }
      });
    }
  }

  Future<void> _submitReview(String decision) async {
    final note = _reviewNoteController.text.trim();
    if (decision == 'recount' && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan wajib diisi saat meminta kasir melakukan hitung ulang.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await _shiftService.reviewShift(
      widget.shift.id,
      decision: decision,
      reviewNote: note.isEmpty ? null : note,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res['success'] == true) {
        Navigator.pop(context);
        widget.onReviewed();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Status shift berhasil diperbarui.'),
            backgroundColor: decision == 'approve' ? const Color(0xFF047857) : const Color(0xFFB45309),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal memverifikasi shift.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const ownerTeal = Color(0xFF00796B);
    final shift = widget.shift;
    final summary = _detailData?['summary'] as Map<String, dynamic>? ?? shift.summary;

    final cashSales = summary['cash_sales'] as int? ?? 0;
    final qrisSales = summary['qris_sales'] as int? ?? 0;
    final cashIn = summary['cash_in'] as int? ?? 0;
    final cashOut = summary['cash_out'] as int? ?? 0;

    final counted = _detailData?['counted_cash'] as int? ?? shift.countedCash;
    final expected = _detailData?['expected_cash'] as int? ?? shift.expectedCash;
    final diff = counted - expected;

    final entries = _detailData?['entries'] as List? ?? [];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ownerTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.point_of_sale_rounded, color: ownerTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Shift #${shift.id}',
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(shift.status),
                      ],
                    ),
                    Text(
                      'Kasir: ${shift.cashierName}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoadingDetail
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Waktu Operasional
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              _buildRow('Waktu Buka Shift', shift.openedAt ?? '-'),
                              const SizedBox(height: 6),
                              _buildRow('Waktu Tutup Shift', shift.closedAt ?? 'Sedang Berjalan (Aktif)'),
                              if (shift.approvedBy != null) ...[
                                const SizedBox(height: 6),
                                _buildRow('Disetujui Oleh', '${shift.approvedBy} (${shift.approvedAt ?? '-'})'),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Rincian Arus Kas
                        const Text(
                          'Rekonsiliasi Kas Toko',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              _buildFinanceRow('Modal Kas Awal (+)', shift.openingCash),
                              const Divider(height: 16),
                              _buildFinanceRow('Penjualan Kasir Tunai (+)', cashSales, color: const Color(0xFF047857)),
                              const SizedBox(height: 6),
                              _buildFinanceRow('Penjualan QRIS (Non-Tunai)', qrisSales, color: Colors.blue.shade700),
                              const SizedBox(height: 6),
                              _buildFinanceRow('Kas Masuk Lainnya (+)', cashIn),
                              const SizedBox(height: 6),
                              _buildFinanceRow('Pengeluaran / Refund Tunai (-)', -cashOut, color: Colors.red.shade700),
                              const Divider(height: 16),
                              _buildFinanceRow('Kas Sistem (Expected)', expected, isBold: true),
                              const SizedBox(height: 6),
                              _buildFinanceRow('Kas Fisik Dihitung Kasir', counted, isBold: true),
                              const Divider(height: 16),

                              // Selisih Kas Card
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Selisih Kas (Discrepancy)',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: diff == 0
                                          ? const Color(0xFFECFDF5)
                                          : diff < 0
                                              ? const Color(0xFFFEF2F2)
                                              : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      diff == 0
                                          ? 'Pas (Rp 0)'
                                          : diff < 0
                                              ? 'Tekor -${CurrencyHelper.formatRupiah(diff.abs())}'
                                              : 'Lebih +${CurrencyHelper.formatRupiah(diff)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: diff == 0
                                            ? const Color(0xFF047857)
                                            : diff < 0
                                                ? const Color(0xFFB91C1C)
                                                : const Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Catatan Kasir Saat Tutup Kas
                        if (shift.closingNote != null && shift.closingNote!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Text(
                            'Catatan Penutupan Kasir',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Text(
                              shift.closingNote!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],

                        // Riwayat Kas Masuk / Keluar
                        if (entries.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Mutasi Kas Laci (In / Out)',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                          ),
                          const SizedBox(height: 6),
                          ...entries.map((e) {
                            final isIn = e['type'] == 'IN';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      e['note'] ?? (isIn ? 'Kas Masuk' : 'Kas Keluar'),
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF374151)),
                                    ),
                                  ),
                                  Text(
                                    isIn
                                        ? '+${CurrencyHelper.formatRupiah(e['amount'])}'
                                        : '-${CurrencyHelper.formatRupiah(e['amount'])}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isIn ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        // Form Evaluasi / Review Owner
                        const SizedBox(height: 16),
                        const Text(
                          'Catatan Evaluasi / Persetujuan Pengawas',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _reviewNoteController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Tuliskan catatan rekonsiliasi, verifikasi fisik, atau instruksi hitung ulang...',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),

          // Action Buttons: Approve & Recount
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD97706),
                    side: const BorderSide(color: Color(0xFFD97706)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSubmitting ? null : () => _submitReview('recount'),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Hitung Ulang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSubmitting ? null : () => _submitReview('approve'),
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Setujui Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFEFF6FF);
    Color text = const Color(0xFF1D4ED8);
    String label = 'Aktif';

    switch (status.toUpperCase()) {
      case 'OPEN':
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1D4ED8);
        label = 'Aktif (Buka)';
        break;
      case 'CLOSED':
      case 'SUBMITTED':
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFB45309);
        label = 'Menunggu Review';
        break;
      case 'APPROVED':
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF047857);
        label = 'Disetujui';
        break;
      case 'RECOUNT':
        bg = const Color(0xFFFEF2F2);
        text = const Color(0xFFDC2626);
        label = 'Hitung Ulang';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: text)),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
      ],
    );
  }

  Widget _buildFinanceRow(String label, int amount, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? const Color(0xFF111827) : const Color(0xFF4B5563),
          ),
        ),
        Text(
          CurrencyHelper.formatRupiah(amount),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: color ?? (isBold ? const Color(0xFF111827) : const Color(0xFF1F2937)),
          ),
        ),
      ],
    );
  }
}
