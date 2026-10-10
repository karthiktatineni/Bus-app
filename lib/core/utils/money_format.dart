import 'package:intl/intl.dart';

class MoneyFormat {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrDecimalFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats amount in INR with Indian grouping, e.g., ₹1,80,000
  static String format(num amount) {
    return _inrFormatter.format(amount);
  }

  /// Formats amount with 2 decimal places, e.g., ₹1,80,000.50
  static String formatWithDecimals(num amount) {
    return _inrDecimalFormatter.format(amount);
  }
}
