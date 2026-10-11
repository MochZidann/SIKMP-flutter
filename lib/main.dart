import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/api_config.dart';
import 'pages/splash/splash_page.dart';
import 'services/fcm_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await ApiConfig.init();
  await SupabaseService.init();
  await FcmService().init();
  runApp(const KopdesApp());
}

class KopdesApp extends StatelessWidget {
  const KopdesApp({super.key});

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
      home: const SplashPage(),
    );
  }
}
