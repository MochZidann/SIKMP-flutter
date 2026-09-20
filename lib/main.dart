import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
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
        ),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}
