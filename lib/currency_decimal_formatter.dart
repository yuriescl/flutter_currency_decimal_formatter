library currency_decimal_formatter;

import 'dart:ui' show TextDirection;
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart' show Decimal;
import 'package:intl/intl.dart' show NumberFormat;

class CurrencyFormatter {
  final String? locale;
  final String? currency;
  final String? symbol;
  int? decimalDigits;

  late final NumberFormat _format;

  CurrencyFormatter(
      {this.locale, this.currency, this.symbol, this.decimalDigits}) {
    _format = NumberFormat.currency(
        locale: locale,
        name: currency,
        symbol: symbol,
        decimalDigits: decimalDigits);
    decimalDigits = _format.decimalDigits ?? 0;
  }

  NumberFormat get format {
    return _format;
  }

  Decimal decimalFromString(String text) {
    num parsed = _format.parse(text);
    return Decimal.parse(parsed.toStringAsFixed(decimalDigits!));
  }

  Decimal decimalFromDecimal(Decimal decimal) {
    return Decimal.parse(decimal.toStringAsFixed(decimalDigits!));
  }

  String stringFromString(String text) {
    num parsed = _format.parse(text);
    Decimal value = Decimal.parse(parsed.toStringAsFixed(decimalDigits!));
    if (value == Decimal.zero) {
      return value.toStringAsFixed(decimalDigits!);
    }
    String result = _format.format(parsed);
    // workaround for https://github.com/dart-lang/intl/issues/376
    if (symbol == '') {
      try {
        int.parse(result[0]);
      } on FormatException {
        result = result.substring(1, result.length);
      }
    }
    return result;
  }

  String stringFromDecimal(Decimal decimal) {
    String result = _format.format(decimal.toDouble());
    // workaround for https://github.com/dart-lang/intl/issues/376
    if (symbol == '') {
      try {
        int.parse(result[0]);
      } on FormatException {
        result = result.substring(1, result.length);
      }
    }
    return result;
  }
}

class CurrencyTextInputFormatter extends TextInputFormatter {
  final bool zeroIsEmpty;
  final TextDirection textDirection;
  late final CurrencyFormatter _formatter;

  CurrencyTextInputFormatter(
      {String? locale,
      String? currency,
      String? symbol,
      int? decimalDigits,
      this.zeroIsEmpty = false,
      this.textDirection = TextDirection.ltr}) {
    _formatter = CurrencyFormatter(
        locale: locale,
        currency: currency,
        symbol: symbol,
        decimalDigits: decimalDigits);
  }

  CurrencyTextInputFormatter.fromFormatter(CurrencyFormatter formatter,
      {this.zeroIsEmpty = false, this.textDirection = TextDirection.ltr}) {
    _formatter = CurrencyFormatter(
        locale: formatter.locale,
        currency: formatter.currency,
        symbol: formatter.symbol,
        decimalDigits: formatter.decimalDigits);
  }

  CurrencyFormatter get formatter {
    return _formatter;
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text == '') {
      return TextEditingValue(
          text: '',
          selection: TextSelection.fromPosition(TextPosition(offset: 0)));
    } else {
      int decimalDigits = _formatter.decimalDigits!;
      NumberFormat format = _formatter.format;
      String groupSep = format.symbols.GROUP_SEP;
      String decimalSep = format.symbols.DECIMAL_SEP;

      String newText = newValue.text;
      try {
        formatter.stringFromString(newText);
      } on FormatException {
        return oldValue;
      }

      if (newText.length < oldValue.text.length) {
        for (int i = 0; i < newText.length; i++) {
          if (newText[i] != oldValue.text[i] &&
              (oldValue.text[i] == groupSep ||
                  oldValue.text[i] == decimalSep)) {
            newText = newText.substring(0, i - 1) + newText.substring(i);
            break;
          }
        }
      }

      newText = newText.replaceAll(groupSep, '').replaceAll(decimalSep, '');
      if (decimalDigits > 0) {
        if (newText.length > decimalDigits) {
          newText = newText.substring(0, newText.length - decimalDigits) +
              decimalSep +
              newText.substring(newText.length - decimalDigits, newText.length);
        } else {
          String newTextWithZeroes = '';
          while (newTextWithZeroes.length + newText.length < decimalDigits) {
            newTextWithZeroes += '0';
          }
          newText = '0' + decimalSep + newTextWithZeroes + newText;
        }
      }
      num parsed = format.parse(newText);
      Decimal value = Decimal.parse(parsed.toStringAsFixed(decimalDigits));
      if (zeroIsEmpty) {
        if (value == Decimal.zero) {
          return TextEditingValue(
              text: '',
              selection: TextSelection.fromPosition(TextPosition(offset: 0)));
        }
      }
      newText = format.format(parsed);

      int baseOffset = oldValue.selection.baseOffset;
      int extentOffset = oldValue.selection.extentOffset;

      if (oldValue.text.length < newText.length) {
        int diff = newText.length - oldValue.text.length;
        if (textDirection == TextDirection.ltr) {
          baseOffset += diff;
        } else {
          baseOffset -= diff;
        }
      } else if (oldValue.text.length > newText.length) {
        int diff = oldValue.text.length - newText.length;
        if (baseOffset == extentOffset) {
          if (textDirection == TextDirection.ltr) {
            baseOffset -= diff;
          } else {
            baseOffset += diff;
          }
        }
      }
      if (baseOffset > newText.length) {
        baseOffset = newText.length;
      } else if (baseOffset < 0) {
        baseOffset = 0;
      }
      return TextEditingValue(
          text: newText,
          selection:
              TextSelection.fromPosition(TextPosition(offset: baseOffset)));
    }
  }
}
