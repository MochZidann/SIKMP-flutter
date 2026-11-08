import 'package:flutter/material.dart';
import '../../core/utils/date_helper.dart';
import '../../core/widgets/app_skeleton.dart';
import '../../core/widgets/empty_data_view.dart';
import '../../models/member.dart';
import '../../services/member_service.dart';
import '../admin/widgets/member_detail_sheet.dart';
import '../admin/widgets/member_form_dialog.dart';

class GudangMembersPage extends StatefulWidget {
  const GudangMembersPage({super.key});

  @override
  State<GudangMembersPage> createState() => _GudangMembersPageState();
}

class _GudangMembersPageState extends State<GudangMembersPage> {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          'Apakah Anda yakin ingin menghapus data anggota "${member.name}" dari sistem koperasi?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade300),
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
                      backgroundColor: const Color(0xFFE65100),
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Daftar Anggota / Member',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateMember,
        backgroundColor: primaryColor,
        elevation: 3,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Tambah Member',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: Column(
        children: [
          // ── SEARCH BAR & SUMMARY HEADER ─────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau nomor telepon member...',
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
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${_filteredMembers.length} anggota terdaftar',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    if (_searchController.text.isNotEmpty)
                      InkWell(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Text(
                          'Reset Pencarian',
                          style: TextStyle(fontSize: 11.5, color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── DAFTAR ANGGOTA (MEMBER CARDS) ───────────────────────────────
          Expanded(
            child: _isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                    itemCount: 6,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, _) => const SkeletonTransactionTile(),
                  )
                : _filteredMembers.isEmpty
                    ? EmptyDataView(
                        icon: Icons.card_membership_rounded,
                        title: 'Anggota Tidak Ditemukan',
                        subtitle: 'Pastikan nama atau telepon sudah benar atau daftarkan anggota baru.',
                        actionLabel: 'Muat Ulang',
                        onAction: _loadMembers,
                      )
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: _loadMembers,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 84),
                          itemCount: _filteredMembers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final m = _filteredMembers[index];

                            return Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  MemberDetailSheet.show(
                                    context,
                                    member: m,
                                    onEdit: () => _openEditMember(m),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Avatar Bulat
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: primaryColor.withValues(alpha: 0.12),
                                        child: Text(
                                          m.name.isNotEmpty ? m.name.substring(0, 1).toUpperCase() : 'M',
                                          style: const TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Detail Informasi Member
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15.5,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF475569)),
                                                const SizedBox(width: 5),
                                                Text(
                                                  m.phone != null && m.phone!.isNotEmpty ? m.phone! : 'Tanpa nomor telepon',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (m.address != null && m.address!.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Padding(
                                                    padding: EdgeInsets.only(top: 1),
                                                    child: Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Expanded(
                                                    child: Text(
                                                      m.address!,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: Color(0xFF334155),
                                                        height: 1.25,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            if (m.createdAtEpochMs != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    'Terdaftar: ${DateHelper.formatEpochMs(m.createdAtEpochMs, withTime: false)}',
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w500,
                                                      color: Color(0xFF475569),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Poin & Menu Aksi
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFFFDE68A)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFD97706)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${m.points} Poin',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF92400E),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF475569)),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 130),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            onSelected: (val) {
                                              if (val == 'detail') {
                                                MemberDetailSheet.show(
                                                  context,
                                                  member: m,
                                                  onEdit: () => _openEditMember(m),
                                                );
                                              }
                                              if (val == 'edit') _openEditMember(m);
                                              if (val == 'delete') _confirmDeleteMember(m);
                                            },
                                            itemBuilder: (ctx) => const [
                                              PopupMenuItem(
                                                value: 'detail',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.badge_outlined, size: 16, color: primaryColor),
                                                    SizedBox(width: 8),
                                                    Text('Kartu Member', style: TextStyle(fontSize: 12.5)),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
                                                    SizedBox(width: 8),
                                                    Text('Edit Member', style: TextStyle(fontSize: 12.5)),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Hapus Member', style: TextStyle(fontSize: 12.5, color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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

