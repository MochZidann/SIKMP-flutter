import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helper.dart';
import '../../../models/member.dart';
import '../../../services/member_service.dart';

class MemberDetailSheet extends StatefulWidget {
  final Member member;
  final VoidCallback? onEdit;

  const MemberDetailSheet({
    super.key,
    required this.member,
    this.onEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required Member member,
    VoidCallback? onEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MemberDetailSheet(
        member: member,
        onEdit: onEdit,
      ),
    );
  }

  @override
  State<MemberDetailSheet> createState() => _MemberDetailSheetState();
}

class _MemberDetailSheetState extends State<MemberDetailSheet> with SingleTickerProviderStateMixin {
  final MemberService _memberService = MemberService();
  bool _isLoading = true;
  Map<String, dynamic>? _detailData;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    final data = await _memberService.getMemberDetail(widget.member.id);
    if (mounted) {
      setState(() {
        _detailData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00897B);

    final summary = _detailData?['summary'] as Map<String, dynamic>?;
    final activeBatches = (_detailData?['activeBatches'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final sales = (_detailData?['sales'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── HANDLE BAR ──
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),

          // ── HEADER PROFIL ANGGOTA ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: primaryColor.withValues(alpha: 0.12),
                  child: const Icon(Icons.person_rounded, color: primaryColor, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.member.name,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.member.memberNo,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.member.phone != null && widget.member.phone!.isNotEmpty
                            ? widget.member.phone!
                            : 'Tanpa nomor telepon',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (widget.member.address != null && widget.member.address!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.member.address!,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Saldo Poin Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 5),
                      Text(
                        '${widget.member.points} Pts',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── RINGKASAN METRIK POIN (JIKA DATA TERSEDIA) ──
          if (summary != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Poin Aktif',
                      value: '${summary['active_points'] ?? widget.member.points}',
                      color: Colors.green.shade700,
                      bgColor: Colors.green.shade50,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Total Diperoleh',
                      value: '${summary['lifetime_earned'] ?? 0}',
                      color: Colors.blue.shade700,
                      bgColor: Colors.blue.shade50,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Total Terpakai',
                      value: '${summary['lifetime_redeemed'] ?? 0}',
                      color: Colors.purple.shade700,
                      bgColor: Colors.purple.shade50,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // ── TAB BAR ──
          TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: [
              Tab(
                text: 'Kelompok Poin (${activeBatches.length})',
                icon: const Icon(Icons.history_toggle_off_rounded, size: 18),
              ),
              Tab(
                text: 'Riwayat Transaksi (${sales.length})',
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
              ),
            ],
          ),
          const Divider(height: 1),

          // ── TAB CONTENT ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: KELOMPOK POIN & KEDALUWARSA (TERBARU PALING ATAS)
                      _buildBatchesTab(activeBatches),

                      // TAB 2: RIWAYAT TRANSAKSI BELANJA (TERBARU PALING ATAS)
                      _buildSalesTab(sales),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesTab(List<Map<String, dynamic>> batches) {
    if (batches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('Tidak ada kelompok poin aktif', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: batches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final b = batches[index];
        final earnedAt = b['earned_at'] ?? b['created_at'];
        final expiresAt = b['expires_at'];
        final remaining = b['remaining_points'] ?? b['points'] ?? 0;
        final initial = b['initial_points'] ?? b['points'] ?? 0;
        final used = (b['used_points'] ?? 0);
        final refTrx = b['reference_no'] ?? (b['sale'] != null ? b['sale']['transactionId'] : null);

        // Hitung sisa hari kedaluwarsa
        int daysLeft = 0;
        if (expiresAt != null) {
          try {
            final expDate = DateTime.parse(expiresAt.toString());
            daysLeft = expDate.difference(DateTime.now()).inDays;
          } catch (_) {}
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        earnedAt != null ? _formatDateString(earnedAt.toString()) : '-',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      'Aktif ($daysLeft hari lagi)',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (refTrx != null && refTrx.toString().isNotEmpty) ...[
                Text(
                  'Ref: ${refTrx.toString()}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 6),
              ],
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSubPointInfo('Poin Awal', '$initial'),
                  _buildSubPointInfo('Terpakai', '$used'),
                  _buildSubPointInfo('Tersedia', '$remaining', isHighlight: true),
                ],
              ),
              if (expiresAt != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Kedaluwarsa: ${_formatDateString(expiresAt.toString())}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubPointInfo(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFFE65100) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesTab(List<Map<String, dynamic>> sales) {
    if (sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('Belum ada transaksi belanja', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sales.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final s = sales[index];
        final trxId = s['transactionId'] ?? 'TRX-${s['id']}';
        final total = (s['total'] as num?)?.toInt() ?? 0;
        final createdAt = s['created_at'];
        final pointsEarned = s['points_earned'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_rounded, color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trxId,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      createdAt != null ? _formatDateString(createdAt.toString()) : '-',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRupiah(total),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E293B)),
                  ),
                  if (pointsEarned > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '+$pointsEarned Pts',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateString(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      return DateHelper.formatEpochMs(dt.millisecondsSinceEpoch, withTime: false);
    } catch (_) {
      return rawDate;
    }
  }
}
