import 'package:flutter/material.dart';
import '../../../core/widgets/empty_data_view.dart';
import '../../../models/auth_user.dart';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/user_card.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<AuthUser> _users = [];
  bool _isLoading = true;
  String _selectedRole = 'SEMUA';

  final List<Map<String, String>> _roleFilters = [
    {'role': 'SEMUA', 'label': 'Semua Role'},
    {'role': 'KASIR', 'label': 'Kasir'},
    {'role': 'ADMIN_GUDANG', 'label': 'Gudang'},
    {'role': 'ADMIN_SISTEM', 'label': 'Admin'},
    {'role': 'OWNER_PENGAWAS', 'label': 'Owner'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _adminService.getUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  List<AuthUser> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    return _users.where((u) {
      final matchesQuery = query.isEmpty ||
          u.name.toLowerCase().contains(query) ||
          u.username.toLowerCase().contains(query);

      final matchesRole = _selectedRole == 'SEMUA' || u.role.toUpperCase() == _selectedRole;

      return matchesQuery && matchesRole;
    }).toList();
  }

  void _toggleUserStatus(AuthUser user, bool targetActive) {
    final actionText = targetActive ? 'Aktifkan' : 'Nonaktifkan';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionText Akun?'),
        content: Text(
          targetActive
              ? 'Akun @${user.username} akan dapat login dan bertransaksi kembali di sistem.'
              : 'Akun @${user.username} akan dinonaktifkan dan tidak dapat login ke sistem sampai diaktifkan kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: targetActive ? const Color(0xFF1976D2) : Colors.orange.shade800,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final currentAdmin = AuthService().currentUser;
              final res = await _adminService.toggleUserStatus(user.id, adminId: currentAdmin?.id);
              if (mounted) {
                if (res['success'] == true) {
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Status berhasil diubah'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Gagal mengubah status akun'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              }
            },
            child: Text(actionText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(AuthUser user) {
    final passCtrl = TextEditingController(text: 'password123');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password Pengguna'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset password akun @${user.username} (${user.name}). Pengguna perlu menggunakan password ini untuk login kembali.',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passCtrl,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
            onPressed: () async {
              final newPass = passCtrl.text.trim();
              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password minimal 6 karakter')),
                );
                return;
              }
              Navigator.pop(ctx);
              final currentAdmin = AuthService().currentUser;
              final res = await _adminService.resetUserPassword(
                user.id,
                password: newPass,
                adminId: currentAdmin?.id,
              );
              if (mounted) {
                if (res['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Password berhasil di-reset'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Gagal reset password'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              }
            },
            child: const Text('Reset Password', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(AuthUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengguna?'),
        content: Text('Apakah Anda yakin ingin menghapus akun @${user.username}? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _adminService.deleteUser(user.username);
              if (mounted) {
                if (success) {
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User @${user.username} berhasil dihapus')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus user')),
                  );
                }
              }
            },
            child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // ── SEARCH BAR & ROLE FILTERS ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau username...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1976D2), size: 20),
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
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _roleFilters.length,
                    itemBuilder: (context, index) {
                      final item = _roleFilters[index];
                      final isSelected = _selectedRole == item['role'];

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Text(
                            item['label']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF333333),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF1976D2),
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (_) {
                            setState(() => _selectedRole = item['role']!);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── USER LIST VIEW ─────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
                : _filteredUsers.isEmpty
                    ? EmptyDataView(
                        icon: Icons.people_outline_rounded,
                        title: 'Pengguna Tidak Ditemukan',
                        subtitle: 'Coba ubah kata kunci pencarian atau role filter.',
                        actionLabel: 'Muat Ulang',
                        onAction: _loadUsers,
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF1976D2),
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return UserCard(
                              user: user,
                              onToggleActive: (active) => _toggleUserStatus(user, active),
                              onResetPassword: () => _showResetPasswordDialog(user),
                              onDelete: () => _confirmDeleteUser(user),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah User', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          AddUserDialog.show(context, onUserAdded: _loadUsers);
        },
      ),
    );
  }
}
