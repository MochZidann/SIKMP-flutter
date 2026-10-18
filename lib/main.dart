import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/api_config.dart';
import 'pages/splash/splash_page.dart';
import 'services/fcm_service.dart';
import 'services/sound_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  final initServicesFuture = _initBackgroundServices();

  runApp(KopdesApp(initFuture: initServicesFuture));
}

/// Menjalankan konfigurasi & inisialisasi modul pihak ketiga secara paralel di background
Future<void> _initBackgroundServices() async {
  try {
    await Future.wait([
      ApiConfig.init(),
      SupabaseService.init(),
      SoundService.init(),
      FcmService().init(),
    ]);
  } catch (e) {
    debugPrint('Background services init warning: $e');
  }
}

class KopdesApp extends StatelessWidget {
  final Future<void>? initFuture;

  const KopdesApp({super.key, this.initFuture});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kopdes Merah Putih',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          primary: const Color(0xFFD32F2F),
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: SplashPage(initFuture: initFuture),
    );
  }
}
