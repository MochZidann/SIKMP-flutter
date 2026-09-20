import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHelper {
  PasswordHelper._();

  /// Membuat 16-byte random salt yang di-encode ke Base64
  static String generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(values);
  }

  /// Melakukan hashing SHA-256(salt_bytes + password_bytes) -> Base64
  /// Kompatibel 100% dengan PasswordHasher.php dan PasswordHasher.kt
  static String hashPassword(String password, String saltBase64) {
    final saltBytes = base64.decode(saltBase64);
    final passwordBytes = utf8.encode(password);
    final combined = [...saltBytes, ...passwordBytes];
    final digest = sha256.convert(combined);
    return base64.encode(digest.bytes);
  }

  /// Verifikasi kecocokan password plaintext dengan salt dan hash tersimpan
  static bool verifyPassword(String password, String saltBase64, String expectedHash) {
    return hashPassword(password, saltBase64) == expectedHash;
  }
}
