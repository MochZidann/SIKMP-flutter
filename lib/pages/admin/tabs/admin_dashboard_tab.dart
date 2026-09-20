import 'package:flutter/material.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../models/audit_log.dart';
import '../../../services/admin_service.dart';
import '../../../services/pos_service.dart';
import '../widgets/add_user_dialog.dart';

class AdminDashboardTab extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const AdminDashboardTab({super.key, this.onNavigateTab});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final stats = await _adminService.getSystemStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
    }

    final totalUsers = _stats['totalUsers'] ?? 0;
    final totalMembers = _stats['totalMembers'] ?? 0;
    final totalLogs = _stats['totalLogs'] ?? 0;
    final serverStatus = _stats['serverStatus'] ?? 'ONLINE';
    final recentLogs = _stats['recentLogs'] as List<AuditLog>? ?? [];

    return RefreshIndicator(
      color: const Color(0xFF1976D2),
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── BANNER HEADER ADMIN SISTEM ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ADMIN SISTEM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'Pengendali Master Data & Keamanan',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: serverStatus == 'ONLINE'
                              ? Colors.green.withValues(alpha: 0.25)
                              : Colors.red.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: serverStatus == 'ONLINE' ? Colors.greenAccent : Colors.redAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: serverStatus == 'ONLINE' ? Colors.greenAccent : Colors.redAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              serverStatus,
                              style: TextStyle(
                                color: serverStatus == 'ONLINE' ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Server Endpoint: ${PosService.baseUrl.replaceAll('/api/pos', '')}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── GRID METRIK UTAMA ───────────────────────────────────────
            const Text(
              'Ringkasan Sistem',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2B2B2B)),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                MetricCard(
                  title: 'Total Pengguna',
                  value: '$totalUsers User',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF1976D2),
                  subtitle: 'Akun Aktif',
                  onTap: () => widget.onNavigateTab?.call(1),
                ),
                MetricCard(
                  title: 'Anggota Koperasi',
                  value: '$totalMembers Anggota',
                  icon: Icons.card_membership_rounded,
                  color: const Color(0xFF00897B),
                  subtitle: 'Terdaftar',
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
                MetricCard(
                  title: 'Catatan Audit',
                  value: '$totalLogs Log',
                  icon: Icons.history_edu_rounded,
                  color: const Color(0xFF8E24AA),
                  subtitle: 'Terekam',
                  onTap: () => widget.onNavigateTab?.call(3),
                ),
                MetricCard(
                  title: 'Status Koneksi',
                  value: serverStatus,
                  icon: Icons.cloud_done_rounded,
                  color: const Color(0xFF2E7D32),
                  subtitle: 'REST API',
                  onTap: _loadDashboardData,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── QUICK ACTIONS ───────────────────────────────────────────
            const Text(
              'Aksi Cepat Admin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2B2B2B)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      AddUserDialog.show(context, onUserAdded: _loadDashboardData);
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Tambah User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadDashboardData,
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Sinkronisasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1976D2),
                      side: const BorderSide(color: Color(0xFF1976D2)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── RECENT AUDIT ACTIVITY ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aktivitas Sistem Terkini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2B2B2B)),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab?.call(3),
                  child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFF1976D2))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentLogs.isEmpty)
              const EmptyDataView(
                icon: Icons.history_rounded,
                title: 'Belum ada catatan aktivitas',
                subtitle: 'Aktivitas transaksi & login akan otomatis muncul di sini.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentLogs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final log = recentLogs[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF1976D2).withValues(alpha: 0.1),
                          child: const Icon(Icons.bolt_rounded, color: Color(0xFF1976D2), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.action,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (log.detail != null && log.detail!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  log.detail!,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          DateHelper.formatEpochMs(log.createdAtEpochMs),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
