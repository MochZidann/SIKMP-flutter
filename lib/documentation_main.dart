// Entrypoint for local report screenshots only. Product source is unchanged.
// Uses the original widgets and services; external FCM/Storage initialization
// is omitted because screenshots do not validate those integrations.
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_kop/core/config/api_config.dart';
import 'package:flutter_kop/main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('custom_server_ip', '127.0.0.1');
  await ApiConfig.init();
  ApiConfig.serverPort = '8000';
  runApp(const app.KopdesApp());
}
