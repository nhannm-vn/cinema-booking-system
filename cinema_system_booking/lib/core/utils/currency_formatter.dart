import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  static String format(int amount) {
    try {
      final formatter = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: 'đ',
        decimalDigits: 0,
      );
      return formatter.format(amount).trim();
    } catch (_) {
      // Fallback format if locale data is not loaded: 120.000 đ
      final str = amount.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) {
          buffer.write('.');
        }
        buffer.write(str[i]);
      }
      return '${buffer.toString()} đ';
    }
  }

  static String formatVnd(int amount) => format(amount);
}
