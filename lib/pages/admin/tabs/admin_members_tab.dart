import 'package:flutter/material.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../models/member.dart';
import '../../../services/admin_service.dart';

class AdminMembersTab extends StatefulWidget {
  const AdminMembersTab({super.key});

  @override
  State<AdminMembersTab> createState() => _AdminMembersTabState();
}

class _AdminMembersTabState extends State<AdminMembersTab> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<Member> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final members = await _adminService.getMembers();
    if (mounted) {
      setState(() {
        _members = members;
        _isLoading = false;
      });
    }
  }

  List<Member> get _filteredMembers {
    final query = _searchController.text.trim().toLowerCase();
    return _members.where((m) {
      return query.isEmpty ||
          m.name.toLowerCase().contains(query) ||
          m.memberNo.toLowerCase().contains(query) ||
          (m.phone != null && m.phone!.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // ── PENCARIAN ANGGOTA ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari nama, No. Anggota, atau telepon...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00897B), size: 20),
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

          // ── DAFTAR ANGGOTA ─────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)))
                : _filteredMembers.isEmpty
                    ? EmptyDataView(
                        icon: Icons.card_membership_rounded,
                        title: 'Anggota Tidak Ditemukan',
                        subtitle: 'Pastikan nama atau nomor anggota sudah sesuai.',
                        actionLabel: 'Muat Ulang',
                        onAction: _loadMembers,
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF00897B),
                        onRefresh: _loadMembers,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredMembers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final m = _filteredMembers[index];
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
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFF00897B).withValues(alpha: 0.12),
                                    child: const Icon(Icons.person_rounded, color: Color(0xFF00897B), size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                m.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: m.isActive ? Colors.green.shade50 : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                m.isActive ? 'AKTIF' : 'NON-AKTIF',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: m.isActive ? Colors.green.shade800 : Colors.red.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'No: ${m.memberNo} ${m.phone != null && m.phone!.isNotEmpty ? '• ${m.phone}' : ''}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        if (m.address != null && m.address!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            m.address!,
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        if (m.createdAtEpochMs != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Terdaftar: ${DateHelper.formatEpochMs(m.createdAtEpochMs, withTime: false)}',
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
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
