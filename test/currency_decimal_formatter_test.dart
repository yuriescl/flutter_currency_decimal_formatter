import 'package:flutter_test/flutter_test.dart';

import 'package:intl/intl.dart' show NumberFormat;
import 'package:decimal/decimal.dart' show Decimal;
import 'package:currency_decimal_formatter/currency_decimal_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('en_US', () {
      CurrencyFormatter formatter = CurrencyFormatter(locale: 'en_US');
      expect(formatter.decimalFromString('1.234'), Decimal.parse('1.23'));
    });
    test('en_US', () {
      CurrencyFormatter formatter =
          CurrencyFormatter(locale: 'en_US', decimalDigits: 2, symbol: '');
      expect(formatter.stringFromString('2512'), '2,512.00');
    });
    test('en_US', () {
      CurrencyFormatter formatter =
          CurrencyFormatter(locale: 'en_US', decimalDigits: 6);
      expect(formatter.stringFromString('2512.12345678'), 'USD2,512.123457');
    });
    test('ja_JP', () {
      CurrencyFormatter formatter =
          CurrencyFormatter(locale: 'ja_JP', symbol: '');
      expect(formatter.stringFromString('2512.43123'), '2,512');
    });
    test('pt_BR', () {
      CurrencyFormatter formatter =
          CurrencyFormatter(locale: 'pt_BR', symbol: '');
      expect(
          formatter.stringFromDecimal(Decimal.parse('1252.5112')), '1.252,51');
    });
    test('en_GB', () {
      CurrencyFormatter formatter =
          CurrencyFormatter(locale: 'en_GB', symbol: '');
      expect(
          formatter.stringFromDecimal(Decimal.parse('1252.5112')), '1,252.51');
    });
  });
}
