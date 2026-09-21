import 'package:flutter/material.dart';
import '../../../models/auth_user.dart';

class UserCard extends StatelessWidget {
  final AuthUser user;
  final ValueChanged<bool>? onToggleActive;
  final VoidCallback? onResetPassword;
  final VoidCallback? onDelete;

  const UserCard({
    super.key,
    required this.user,
    this.onToggleActive,
    this.onResetPassword,
    this.onDelete,
  });

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN_SISTEM':
        return const Color(0xFF1976D2);
      case 'ADMIN_GUDANG':
        return const Color(0xFFE65100);
      case 'KASIR':
        return const Color(0xFFD32F2F);
      case 'OWNER_PENGAWAS':
        return const Color(0xFF00796B);
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'ADMIN_SISTEM':
        return Icons.admin_panel_settings_rounded;
      case 'ADMIN_GUDANG':
        return Icons.warehouse_rounded;
      case 'KASIR':
        return Icons.point_of_sale_rounded;
      case 'OWNER_PENGAWAS':
        return Icons.pie_chart_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(user.role);
    final isInactive = !user.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isInactive ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInactive ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isInactive ? 0.01 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isInactive
                  ? Colors.grey.shade200
                  : roleColor.withValues(alpha: 0.12),
              child: Icon(
                _getRoleIcon(user.role),
                color: isInactive ? Colors.grey.shade500 : roleColor,
                size: 22,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: user.isActive ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name.isEmpty ? user.username : user.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isInactive ? Colors.grey.shade600 : Colors.black87,
                  decoration: isInactive ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.roleLabel,
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                '@${user.username}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              if (isInactive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Nonaktif',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onToggleActive != null)
              Tooltip(
                message: user.isActive ? 'Kunci / Nonaktifkan Akun' : 'Aktifkan Akun',
                child: Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: user.isActive,
                    activeThumbColor: const Color(0xFF1976D2),
                    activeTrackColor: const Color(0xFF90CAF9),
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade200,
                    onChanged: onToggleActive,
                  ),
                ),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'reset') onResetPassword?.call();
                if (val == 'delete') onDelete?.call();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset_rounded, size: 18, color: Color(0xFF1976D2)),
                      SizedBox(width: 10),
                      Text('Reset Password', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Hapus User', style: TextStyle(fontSize: 13, color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
