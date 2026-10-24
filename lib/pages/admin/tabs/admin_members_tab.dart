import 'package:flutter/material.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../models/member.dart';
import '../../../services/member_service.dart';
import '../widgets/member_form_dialog.dart';

class AdminMembersTab extends StatefulWidget {
  const AdminMembersTab({super.key});

  @override
  State<AdminMembersTab> createState() => _AdminMembersTabState();
}

class _AdminMembersTabState extends State<AdminMembersTab> {
  final MemberService _memberService = MemberService();
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
    final members = await _memberService.getMembers(search: _searchController.text.trim());
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
          (m.phone != null && m.phone!.toLowerCase().contains(query)) ||
          (m.address != null && m.address!.toLowerCase().contains(query));
    }).toList();
  }

  void _openCreateMember() {
    MemberFormDialog.show(
      context,
      onSaved: _loadMembers,
    );
  }

  void _openEditMember(Member member) {
    MemberFormDialog.show(
      context,
      member: member,
      onSaved: _loadMembers,
    );
  }

  void _confirmDeleteMember(Member member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Hapus Anggota?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus anggota "${member.name}" dari sistem?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final result = await _memberService.deleteMember(member.id);
              if (mounted) {
                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Anggota berhasil dihapus'),
                      backgroundColor: const Color(0xFF00897B),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadMembers();
                } else {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Gagal menghapus anggota'),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00897B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateMember,
        backgroundColor: primaryColor,
        elevation: 3,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Tambah Anggota',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
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
                hintText: 'Cari nama atau telepon (min. 2 huruf)...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search_rounded, color: primaryColor, size: 20),
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // ── DAFTAR ANGGOTA ─────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: 6,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, _) => const SkeletonTransactionTile(),
                  )
                : _filteredMembers.isEmpty
                    ? EmptyDataView(
                        icon: Icons.card_membership_rounded,
                        title: 'Anggota Tidak Ditemukan',
                        subtitle: 'Pastikan nama atau telepon anggota sudah sesuai atau tambahkan anggota baru.',
                        actionLabel: 'Muat Ulang',
                        onAction: _loadMembers,
                      )
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: _loadMembers,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 84),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: primaryColor.withValues(alpha: 0.12),
                                    child: const Icon(Icons.person_rounded, color: primaryColor, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.phone_outlined, size: 13, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(
                                              m.phone != null && m.phone!.isNotEmpty ? m.phone! : 'Tanpa nomor telepon',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                        if (m.address != null && m.address!.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade400),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  m.address!,
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
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
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Poin Belanja Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.amber.shade200),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.stars_rounded, size: 14, color: Colors.amber.shade700),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${m.points} Poin',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // Action Buttons: Edit & Delete
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => _openEditMember(m),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.blue.shade200),
                                              ),
                                              child: Icon(Icons.edit_rounded, size: 16, color: Colors.blue.shade700),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () => _confirmDeleteMember(m),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.red.shade200),
                                              ),
                                              child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
