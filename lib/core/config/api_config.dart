import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  /// Alamat IP Server Backend (dapat diubah langsung di baris ini)
  static const String defaultServerIp = '192.168.1.6';

  /// Port Server Backend Laravel (default: 8000)
  static const String defaultServerPort = '8000';

  static String serverIp = defaultServerIp;
  static String serverPort = defaultServerPort;

  /// Root host server tanpa path (contoh: http://192.168.1.6:8000 atau https://xyz.trycloudflare.com)
  static String get hostUrl {
    var raw = serverIp.trim();
    while (raw.endsWith('/')) {
      raw = raw.substring(0, raw.length - 1);
    }

    // Jika menginputkan skema http:// atau https://
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.host.isNotEmpty) {
        final host = uri.host;
        // Domain tunnel (Cloudflare, Ngrok, dll) selalu menggunakan HTTPS standar (port 443)
        if (host.contains('trycloudflare.com') || host.contains('ngrok')) {
          return 'https://$host';
        }
        if (uri.hasPort && uri.port != 80 && uri.port != 443) {
          return '${uri.scheme}://$host:${uri.port}';
        }
        return '${uri.scheme}://$host';
      }
      return raw;
    }

    // Jika domain publik / tunnel tanpa skema (misal xyz.trycloudflare.com)
    if (raw.contains('trycloudflare.com') ||
        raw.contains('ngrok.io') ||
        raw.contains('ngrok-free.app') ||
        (!raw.contains(':') && raw.contains('.') && !RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(raw))) {
      return 'https://$raw';
    }

    // Jika IP sudah menyertakan port (misal 192.168.1.6:8000)
    if (raw.contains(':')) {
      return 'http://$raw';
    }

    // Default IP lokal dengan port backend
    return 'http://$raw:$serverPort';
  }

  /// Root base URL API Laravel (contoh: http://192.168.1.6:8000/api)
  static String get apiBaseUrl => '$hostUrl/api';

  /// Endpoint Modul Kasir / POS
  static String get posUrl => '$apiBaseUrl/pos';

  /// Endpoint Modul Autentikasi
  static String get authUrl => '$apiBaseUrl/auth';

  /// Endpoint Modul Admin Sistem
  static String get adminUrl => '$apiBaseUrl/admin';

  /// Endpoint Modul Admin Gudang
  static String get gudangUrl => '$apiBaseUrl/gudang';

  /// Endpoint Modul Sinkronisasi
  static String get syncUrl => '$apiBaseUrl/sync';

  /// Endpoint Modul Owner
  static String get ownerUrl => '$apiBaseUrl/owner';

  /// Endpoint Modul Member / Anggota
  static String get membersUrl => '$apiBaseUrl/members';

  /// Endpoint Modul Supplier & Vendor
  static String get suppliersUrl => '$apiBaseUrl/suppliers';

  /// Inisialisasi konfigurasi saat aplikasi dimulai
  static Future<void> init() async {
    serverIp = defaultServerIp;
    serverPort = defaultServerPort;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDefaultIp = prefs.getString('last_default_server_ip');

      // Jika programmer baru saja mengganti defaultServerIp di kode, sinkronkan ke IP baru
      if (lastDefaultIp != defaultServerIp) {
        serverIp = defaultServerIp;
        await prefs.setString('custom_server_ip', defaultServerIp);
        await prefs.setString('last_default_server_ip', defaultServerIp);
      } else {
        final savedIp = prefs.getString('custom_server_ip');
        if (savedIp != null && savedIp.isNotEmpty) {
          serverIp = savedIp;
        } else {
          serverIp = defaultServerIp;
          await prefs.setString('custom_server_ip', defaultServerIp);
        }
      }
    } catch (_) {}
  }

  /// Simpan custom IP ke SharedPreferences jika diubah secara dinamis
  static Future<void> setServerIp(String newIp) async {
    serverIp = newIp;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_server_ip', newIp);
    } catch (_) {}
  }
}
