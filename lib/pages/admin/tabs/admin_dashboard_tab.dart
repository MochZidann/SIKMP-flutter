import 'package:flutter/material.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../core/widgets/header_curve_clipper.dart';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── BANNER HEADER ADMIN SISTEM DENGAN BACKGROUND MELENGKUNG ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Background Biru Melengkung di Tengah ke Bawah
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 35,
                  child: ClipPath(
                    clipper: const HeaderCurveClipper(),
                    child: Container(
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                ),

                // Card 2 Layer (Layer 1: Putih, Layer 2: Biru Solid)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1976D2).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
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
                                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
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
                                          fontSize: 14.5,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Pengendali Master Data & Keamanan',
                                        style: TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 4,
                                      backgroundColor: serverStatus == 'ONLINE'
                                          ? const Color(0xFF69F0AE)
                                          : const Color(0xFFFF5252),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      serverStatus,
                                      style: TextStyle(
                                        color: serverStatus == 'ONLINE'
                                            ? const Color(0xFF69F0AE)
                                            : const Color(0xFFFF5252),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.dns_rounded, size: 13, color: Colors.white70),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Server: ${PosService.baseUrl.replaceAll('/api/pos', '')}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── LAYER PERTAMA WARNA PUTIH (DI BAWAH LAYER BIRU): AKSI CEPAT ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3.5,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1976D2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Aksi Admin Cepat',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2B2B2B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildQuickActionBtn(
                                title: 'Tambah User',
                                icon: Icons.person_add_alt_1_rounded,
                                color: const Color(0xFF1976D2),
                                onTap: () {
                                  AddUserDialog.show(context, onUserAdded: _loadDashboardData);
                                },
                              ),
                              const SizedBox(width: 6),
                              _buildQuickActionBtn(
                                title: 'Profil Toko',
                                icon: Icons.storefront_rounded,
                                color: const Color(0xFF00796B),
                                onTap: () {
                                  StoreSettingsDialog.show(context, onSaved: _loadDashboardData);
                                },
                              ),
                              const SizedBox(width: 6),
                              _buildQuickActionBtn(
                                title: 'Database',
                                icon: Icons.storage_rounded,
                                color: const Color(0xFFE65100),
                                onTap: () {
                                  DatabaseHealthSheet.show(context);
                                },
                              ),
                              const SizedBox(width: 6),
                              _buildQuickActionBtn(
                                title: 'Sinkronisasi',
                                icon: Icons.sync_rounded,
                                color: const Color(0xFF5C6BC0),
                                onTap: _loadDashboardData,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

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
      ],
    ),
  ),
    );
  }

  Widget _buildQuickActionBtn({
    required String title,
    IconData? icon,
    String? assetPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: assetPath != null
                      ? Image.asset(
                          assetPath,
                          width: 24,
                          height: 24,
                          color: color,
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(icon ?? Icons.circle, color: color, size: 24),
                        )
                      : Icon(icon ?? Icons.circle, color: color, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
