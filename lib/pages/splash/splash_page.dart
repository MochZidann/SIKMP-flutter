import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../admin/admin_main_page.dart';
import '../gudang/gudang_main_page.dart';
import '../kasir_main_page.dart';
import '../login_page.dart';
import '../owner/owner_main_page.dart';

class SplashPage extends StatefulWidget {
  final Future<void>? initFuture;

  const SplashPage({super.key, this.initFuture});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Jalankan inisialisasi services & navigasi otomatis
    _startStartupFlow();
  }

  Future<void> _startStartupFlow() async {
    final stopwatch = Stopwatch()..start();

    // Tunggu background services selesai diinisialisasi (maksimal 4 detik agar tidak stuck jika offline)
    if (widget.initFuture != null) {
      try {
        await widget.initFuture!.timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            debugPrint('⚠️ [Splash] Inisialisasi background service melebihi batas waktu 4 detik.');
          },
        );
      } catch (e) {
        debugPrint('Splash init error: $e');
      }
    }

    // Tampilkan splash screen selama 2 detik
    final elapsed = stopwatch.elapsedMilliseconds;
    final remaining = 2000 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final user = AuthService().currentUser;
    Widget targetPage = const LoginPage();
    if (AuthService().isLoggedIn && user != null) {
      if (user.isAdmin) {
        targetPage = const AdminMainPage();
      } else if (user.isGudang) {
        targetPage = const GudangMainPage();
      } else if (user.isKasir) {
        targetPage = const KasirMainPage();
      } else if (user.isOwner) {
        targetPage = const OwnerMainPage();
      }
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => targetPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8E0000),
      body: SizedBox.expand(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo Resmi SIKMP KOP DES KEL
              Image.asset(
                'assets/images/sikmp_white.png',
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),

              // Teks Brand Kopdes Merah Putih
              const Text(
                'KOPDES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const Text(
                'MERAH PUTIH',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Membangun Ekonomi Desa Mandiri',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const Spacer(),

              // Loading Spinner Langsung Aktif di Tengah Bawah
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Versi 1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
