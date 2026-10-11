import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../firebase_options.dart';

/// Handler background saat aplikasi dalam keadaan ditutup/terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint('🔔 [FCM Background] Pesan diterima: ${message.notification?.title} - ${message.notification?.body}');
}

/// Service terpusat untuk Push Notification Firebase Cloud Messaging (FCM)
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _highPriorityChannel = AndroidNotificationChannel(
    'kopdes_high_importance_channel',
    'Notifikasi Koperasi Merah Putih',
    description: 'Saluran notifikasi transaksi kasir, stok gudang, dan laporan owner',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Inisialisasi Firebase & FCM Listener
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Inisialisasi Firebase App
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Setup Android Local Notifications untuk menampilkan notifikasi saat aplikasi dibuka (Foreground)
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('🔔 Notifikasi ditekan (payload: ${response.payload})');
          _handleNotificationPayload(response.payload);
        },
      );

      // Buat channel di Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_highPriorityChannel);

      // 3. Minta izin Push Notification kepada pengguna (Android 13+ & iOS)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('🔔 Status Izin Notifikasi: ${settings.authorizationStatus}');

      // 4. Ambil Token FCM Perangkat
      _fcmToken = await messaging.getToken();
      debugPrint('🔑 [FCM Token]: $_fcmToken');

      // Otomatis berlangganan topik awal agar pengetesan terminal langsung masuk
      try {
        await messaging.subscribeToTopic('all_users');
        await messaging.subscribeToTopic('notif_gudang');
        await messaging.subscribeToTopic('notif_owner');
        debugPrint('🔔 [FCM] Berhasil berlangganan topik awal: notif_gudang, notif_owner, all_users');
      } catch (e) {
        debugPrint('⚠️ [FCM] Gagal berlangganan topik awal: $e');
      }

      if (_fcmToken != null) {
        _sendTokenToBackend(_fcmToken!);
      }

      // Pantau jika ada pembaruan token
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔑 [FCM Token Diperbarui]: $newToken');
        _sendTokenToBackend(newToken);
      });

      // 5. Listener Pesan saat Aplikasi Aktif di Layar (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM Foreground]: ${message.notification?.title} | ${message.notification?.body}');
        _showLocalNotification(message);
      });

      // 6. Listener saat Notifikasi Ditekan dari System Tray (Background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM Dibuka dari Tray]: ${message.data}');
        _handleNotificationPayload(jsonEncode(message.data));
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ [FcmService] Firebase belum aktif atau google-services.json belum dipasang: $e');
    }
  }

  /// Tampilkan notifikasi pop-up saat aplikasi sedang dibuka
  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _highPriorityChannel.id,
          _highPriorityChannel.name,
          channelDescription: _highPriorityChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Langganan topik berdasarkan Role saat user Login:
  /// - 'gudang' -> Peringatan Stok Kritis & PO Masuk
  /// - 'owner'  -> Ringkasan Omzet Harian & Fraud Alert
  /// - 'kasir'  -> Pembayaran QRIS Sukses
  /// - 'admin'  -> Peringatan Sistem & Keamanan
  Future<void> subscribeToRole(String role) async {
    if (!_isInitialized) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.subscribeToTopic('all_users');

      final normalizedRole = role.toLowerCase().trim();
      switch (normalizedRole) {
        case 'gudang':
        case 'admin gudang':
          await messaging.subscribeToTopic('notif_gudang');
          debugPrint('🔔 Berlangganan topik: notif_gudang (Stok Kritis & PO)');
          break;
        case 'owner':
          await messaging.subscribeToTopic('notif_owner');
          debugPrint('🔔 Berlangganan topik: notif_owner (Omzet Tutup Toko & Fraud)');
          break;
        case 'kasir':
          await messaging.subscribeToTopic('notif_kasir');
          debugPrint('🔔 Berlangganan topik: notif_kasir (QRIS Masuk)');
          break;
        case 'admin':
        case 'admin sistem':
          await messaging.subscribeToTopic('notif_admin');
          debugPrint('🔔 Berlangganan topik: notif_admin (Sistem)');
          break;
      }

      // Kirim token FCM ke backend untuk dicatat bersama User ID
      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      debugPrint('⚠️ Gagal berlangganan topik role: $e');
    }
  }

  /// Batalkan langganan topik saat Logout agar notifikasi role sebelumnya tidak masuk
  Future<void> unsubscribeAllRoleTopics() async {
    if (!_isInitialized) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.unsubscribeFromTopic('notif_gudang');
      await messaging.unsubscribeFromTopic('notif_owner');
      await messaging.unsubscribeFromTopic('notif_kasir');
      await messaging.unsubscribeFromTopic('notif_admin');
      debugPrint('🔕 Berhasil berhenti berlangganan semua topik role');
    } catch (e) {
      debugPrint('⚠️ Gagal membatalkan langganan topik: $e');
    }
  }

  /// Kirim token FCM perangkat ke backend Laravel agar backend bisa kirim pesan personal
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiBaseUrl}/fcm/token');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'fcm_token': token}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Backend route fcm/token opsional jika menggunakan pola Topics
    }
  }

  /// Navigasi atau respon saat pengguna mengklik notifikasi
  void _handleNotificationPayload(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type']?.toString();
      debugPrint('🚀 Menangani klik notifikasi tipe: $type');
      // Anda dapat menghubungkan callback navigasi ke halaman terkait di sini
    } catch (_) {}
  }

  /// Fitur pengujian mandiri: Menampilkan notifikasi simulasi langsung di layar HP
  Future<void> showTestNotification({
    required String title,
    required String body,
    String? type,
  }) async {
    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _highPriorityChannel.id,
          _highPriorityChannel.name,
          channelDescription: _highPriorityChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: jsonEncode({'type': type ?? 'test'}),
    );
  }
}
