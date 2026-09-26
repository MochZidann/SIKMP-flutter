import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../utils/date_helper.dart';

/// Komponen Title Navbar Atas (AppBar) dengan Logo Resmi SIKMP,
/// Kata Sambutan otomatis sesuai waktu (Pagi/Siang/Sore/Malam),
/// dan Nama Role dalam tipografi Bold.
class AppTopBarTitle extends StatelessWidget {
  /// Override nama role jika ingin secara spesifik ditentukan (misal 'Kasir', 'Admin Gudang', dll.)
  /// Jika null, akan membaca otomatis dari role aktif pengguna di AuthService.
  final String? roleName;

  /// Tinggi logo di samping kiri (sedikit diperbesar, default 40)
  final double logoHeight;

  /// Custom greeting jika ingin mengesampingkan jam otomatis
  final String? customGreeting;

  const AppTopBarTitle({
    super.key,
    this.roleName,
    this.logoHeight = 40.0,
    this.customGreeting,
  });

  @override
  Widget build(BuildContext context) {
    final greeting = customGreeting ?? DateHelper.getTimeGreeting();
    final user = AuthService().currentUser;
    final role = roleName ?? (user != null ? user.roleLabel : 'Petugas');

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Logo Resmi SIKMP (diperbesar sedikit)
        Image.asset(
          'assets/images/sikmp_white.png',
          height: logoHeight,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),

        // 2. Kolom Sambutan & Role Bold
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kata sambutan selamat berdasarkan jam
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.90),
                  letterSpacing: 0.2,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 1),
              // Nama role dalam format bold
              Text(
                role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
