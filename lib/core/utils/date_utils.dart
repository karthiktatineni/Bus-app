import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _standardFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  /// Formats date as '10 Oct 2026'
  static String formatDate(DateTime date) {
    return _standardFormat.format(date);
  }

  /// Formats date as '2026-10-10'
  static String formatIso(DateTime date) {
    return _isoFormat.format(date);
  }

  /// Calculates days difference between date and reference date (ignoring time)
  static int daysDifference(DateTime target, {DateTime? reference}) {
    final ref = reference ?? DateTime.now();
    final targetDate = DateTime(target.year, target.month, target.day);
    final refDate = DateTime(ref.year, ref.month, ref.day);
    return targetDate.difference(refDate).inDays;
  }

  /// Returns friendly relative date: 'Today', 'Tomorrow', 'Yesterday', 'In 5 days', '3 days ago'
  static String formatRelative(DateTime target, {DateTime? reference}) {
    final diff = daysDifference(target, reference: reference);
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1) return 'In $diff days';
    return '${diff.abs()} days ago';
  }

  /// Returns true if target date is in the past relative to reference
  static bool isOverdue(DateTime target, {DateTime? reference}) {
    return daysDifference(target, reference: reference) < 0;
  }

  /// Returns true if target date is due within the given window (default 14 days)
  static bool isDueSoon(DateTime target, {int withinDays = 14, DateTime? reference}) {
    final diff = daysDifference(target, reference: reference);
    return diff >= 0 && diff <= withinDays;
  }
}
