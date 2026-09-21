import 'package:flutter/material.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../models/audit_log.dart';
import '../../../services/admin_service.dart';
import '../../../services/pos_service.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/database_health_sheet.dart';
import '../widgets/store_settings_dialog.dart';

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
    final stats = await _adminService.getDashboardStats();
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
    final activeUsers = _stats['activeUsers'] ?? 0;
    final totalMembers = _stats['totalMembers'] ?? 0;
    final totalLogs = _stats['totalLogs'] ?? 0;
    final totalDatabaseRows = _stats['totalDatabaseRows'] ?? 0;
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
                    'Server: ${PosService.baseUrl.replaceAll('/api/pos', '')}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── GRID METRIK UTAMA ───────────────────────────────────────
            const Text(
              'Ringkasan Sistem & Performa',
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
                  subtitle: '$activeUsers Aktif',
                  onTap: () => widget.onNavigateTab?.call(1),
                ),
                MetricCard(
                  title: 'Anggota Koperasi',
                  value: '$totalMembers Anggota',
                  icon: Icons.card_membership_rounded,
                  color: const Color(0xFF00897B),
                  subtitle: 'Terdaftar Aktif',
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
                MetricCard(
                  title: 'Catatan Audit',
                  value: '$totalLogs Log',
                  icon: Icons.history_edu_rounded,
                  color: const Color(0xFF8E24AA),
                  subtitle: 'Audit Trail',
                  onTap: () => widget.onNavigateTab?.call(3),
                ),
                MetricCard(
                  title: 'Kesehatan Data',
                  value: '$totalDatabaseRows Baris',
                  icon: Icons.storage_rounded,
                  color: const Color(0xFFE65100),
                  subtitle: 'Tabel & Server Cache',
                  onTap: () => DatabaseHealthSheet.show(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── QUICK ACTIONS ───────────────────────────────────────────
            const Text(
              'Pusat Kendali Admin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2B2B2B)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Tambah User',
                    color: const Color(0xFF1976D2),
                    onTap: () {
                      AddUserDialog.show(context, onUserAdded: _loadDashboardData);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.storefront_rounded,
                    label: 'Profil & Struk',
                    color: const Color(0xFF00796B),
                    onTap: () {
                      StoreSettingsDialog.show(context, onSaved: _loadDashboardData);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.storage_rounded,
                    label: 'Database & Cache',
                    color: const Color(0xFFE65100),
                    onTap: () {
                      DatabaseHealthSheet.show(context);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.sync_rounded,
                    label: 'Sinkronisasi',
                    color: const Color(0xFF455A64),
                    onTap: _loadDashboardData,
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
