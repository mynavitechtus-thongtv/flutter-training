import 'package:intl/intl.dart';

import '../../index.dart';

class AppUtil {
  AppUtil._();

  static String formatPrice(double price) {
    return NumberFormat.currency(symbol: '￥', decimalDigits: 0).format(price);
  }

  static String formatNumber(int number) {
    return NumberFormat(Constant.numberFormat1).format(number);
  }

  static bool isValidPassword(String password) {
    const _mimimumPasswordLength = 6;
    const _whitespace = ' ';

    return password.length >= _mimimumPasswordLength && !password.contains(_whitespace);
  }

  static bool isValidEmail(String email) {
    final value = email.trim();
    if (value.isEmpty || value.length > 254) {
      return false;
    }

    if (!RegExp(
            r'''^(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])$''')
        .hasMatch(value)) {
      return false;
    }

    return true;
  }

  static bool isKatakana(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    return RegExp(r'^([ァ-ン]|ー)+$').hasMatch(trimmed);
  }

  static bool isValidPhoneNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    if (trimmed.length > 15) {
      return false;
    }

    return RegExp(r'^[0-9]+$').hasMatch(trimmed);
  }

  static bool isValidEmailOrPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    if (isValidEmail(trimmed)) {
      return true;
    }

    return isValidPhoneNumber(trimmed);
  }
}
