import 'package:flutter/material.dart';
import '../../../models/auth_user.dart';

class UserCard extends StatelessWidget {
  final AuthUser user;
  final Function(bool isActive)? onToggleActive;
  final VoidCallback? onDelete;

  const UserCard({
    super.key,
    required this.user,
    this.onToggleActive,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: roleColor.withValues(alpha: 0.12),
          child: Icon(_getRoleIcon(user.role), color: roleColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name.isEmpty ? user.username : user.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
          child: Text(
            '@${user.username}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                tooltip: 'Hapus User',
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }
}
