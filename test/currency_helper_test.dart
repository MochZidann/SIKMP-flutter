import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kop/core/utils/currency_formatter.dart';

void main() {
  test('CurrencyHelper and formatRupiah work without recursion', () {
    expect(formatRupiah(10000), 'Rp 10.000');
    expect(CurrencyHelper.formatRupiah(10000), 'Rp 10.000');
    expect(formatRupiah(0), 'Rp 0');
    expect(CurrencyHelper.formatRupiah(0), 'Rp 0');
    expect(formatRupiah(null), 'Rp 0');
    expect(CurrencyHelper.formatRupiah(null), 'Rp 0');
    expect(CurrencyHelper.formatRupiah(2500000), 'Rp 2.500.000');
  });
}

