import 'package:intl/intl.dart';

class DateHelper {
  DateHelper._();

  static DateFormat _getFormat(String pattern) {
    try {
      return DateFormat(pattern, 'id_ID');
    } catch (_) {
      return DateFormat(pattern);
    }
  }

  /// Format epoch milliseconds menjadi string tanggal & jam (e.g. 20 Sep 2026, 14:30)
  static String formatEpochMs(dynamic epochMs, {bool withTime = true}) {
    if (epochMs == null) return '-';
    int? ms;
    if (epochMs is int) {
      ms = epochMs;
    } else if (epochMs is String) {
      ms = int.tryParse(epochMs);
    }
    if (ms == null || ms == 0) return '-';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(ms);
    final fmt = withTime ? _getFormat('dd MMM yyyy, HH:mm') : _getFormat('dd MMMM yyyy');
    return fmt.format(dateTime);
  }

  /// Format DateTime standar
  static String formatDateTime(DateTime dateTime) {
    return _getFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  /// Format jam saja (HH:mm)
  static String formatTime(DateTime dateTime) {
    return _getFormat('HH:mm').format(dateTime);
  }

  /// Mendapatkan salam kata sambutan berdasarkan jam (Pagi, Siang, Sore, Malam)
  static String getTimeGreeting([DateTime? time]) {
    final now = time ?? DateTime.now();
    final hour = now.hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat Pagi,';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang,';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore,';
    } else {
      return 'Selamat Malam,';
    }
  }
}
