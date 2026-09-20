import 'package:intl/intl.dart';

final NumberFormat _rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// Format angka ke representasi Rupiah (misal: 10000 -> "Rp 10.000")
String formatRupiah(num? amount) {
  if (amount == null) return 'Rp 0';
  return _rupiahFormat.format(amount);
}
