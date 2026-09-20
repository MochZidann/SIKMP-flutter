import 'package:flutter/material.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../models/audit_log.dart';
import '../../../services/admin_service.dart';

class AdminAuditTab extends StatefulWidget {
  const AdminAuditTab({super.key});

  @override
  State<AdminAuditTab> createState() => _AdminAuditTabState();
}

class _AdminAuditTabState extends State<AdminAuditTab> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<AuditLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    final logs = await _adminService.getAuditLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Color _getActionColor(String action) {
    final act = action.toUpperCase();
    if (act.contains('LOGIN') || act.contains('AUTH')) {
      return const Color(0xFF1976D2);
    }
    if (act.contains('CREATE') || act.contains('ADD') || act.contains('IN')) {
      return const Color(0xFF2E7D32);
    }
    if (act.contains('UPDATE') || act.contains('EDIT') || act.contains('ADJUST')) {
      return const Color(0xFFF57C00);
    }
    if (act.contains('DELETE') || act.contains('REMOVE') || act.contains('CANCEL')) {
      return const Color(0xFFD32F2F);
    }
    return const Color(0xFF5E35B1);
  }

  List<AuditLog> get _filteredLogs {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _logs;

    return _logs.where((l) {
      final actionMatch = l.action.toLowerCase().contains(query);
      final detailMatch = l.detail?.toLowerCase().contains(query) ?? false;
      final entityMatch = l.entity?.toLowerCase().contains(query) ?? false;
      return actionMatch || detailMatch || entityMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // ── PENCARIAN LOG ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari aksi log, entitas, atau detail...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8E24AA), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // ── DAFTAR AUDIT LOG ───────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8E24AA)))
                : _filteredLogs.isEmpty
                    ? EmptyDataView(
                        icon: Icons.history_edu_rounded,
                        title: 'Log Aktivitas Kosong',
                        subtitle: 'Semua aktivitas transaksi dan login akan terekam di sini.',
                        actionLabel: 'Muat Ulang',
                        onAction: _loadAuditLogs,
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF8E24AA),
                        onRefresh: _loadAuditLogs,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredLogs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final log = _filteredLogs[index];
                            final actionColor = _getActionColor(log.action);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: actionColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          log.action,
                                          style: TextStyle(
                                            color: actionColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        DateHelper.formatEpochMs(log.createdAtEpochMs),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    log.detail ?? 'Aktivitas sistem dilakukan oleh User ID: ${log.userId ?? '-'}',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF2B2B2B), height: 1.3),
                                  ),
                                  if (log.entity != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.layers_outlined, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Entitas: ${log.entity} ${log.entityId != null ? '#${log.entityId}' : ''}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
