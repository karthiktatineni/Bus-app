import 'package:flutter_test/flutter_test.dart';
import 'package:bus_app/core/utils/date_utils.dart';
import 'package:bus_app/core/utils/money_format.dart';

void main() {
  group('AppDateUtils Tests', () {
    final referenceDate = DateTime(2026, 10, 10, 12, 0);

    test('formatDate outputs standard human date', () {
      final formatted = AppDateUtils.formatDate(referenceDate);
      expect(formatted, contains('2026'));
      expect(formatted, contains('Oct'));
      expect(formatted, contains('10'));
    });

    test('daysDifference calculates day difference accurately', () {
      final tomorrow = DateTime(2026, 10, 11, 8, 0);
      final yesterday = DateTime(2026, 10, 9, 18, 0);

      expect(
          AppDateUtils.daysDifference(tomorrow, reference: referenceDate), 1);
      expect(
          AppDateUtils.daysDifference(yesterday, reference: referenceDate), -1);
      expect(
          AppDateUtils.daysDifference(referenceDate, reference: referenceDate),
          0);
    });

    test('formatRelative produces friendly labels', () {
      final today = DateTime(2026, 10, 10, 9, 0);
      final tomorrow = DateTime(2026, 10, 11, 15, 0);
      final yesterday = DateTime(2026, 10, 9, 14, 0);
      final inFiveDays = DateTime(2026, 10, 15);
      final fourDaysAgo = DateTime(2026, 10, 6);

      expect(AppDateUtils.formatRelative(today, reference: referenceDate),
          'Today');
      expect(AppDateUtils.formatRelative(tomorrow, reference: referenceDate),
          'Tomorrow');
      expect(AppDateUtils.formatRelative(yesterday, reference: referenceDate),
          'Yesterday');
      expect(AppDateUtils.formatRelative(inFiveDays, reference: referenceDate),
          'In 5 days');
      expect(AppDateUtils.formatRelative(fourDaysAgo, reference: referenceDate),
          '4 days ago');
    });

    test('isOverdue and isDueSoon logic', () {
      final pastDate = DateTime(2026, 10, 5);
      final soonDate = DateTime(2026, 10, 18);
      final farFuture = DateTime(2026, 11, 15);

      expect(
          AppDateUtils.isOverdue(pastDate, reference: referenceDate), isTrue);
      expect(
          AppDateUtils.isOverdue(soonDate, reference: referenceDate), isFalse);

      expect(
          AppDateUtils.isDueSoon(soonDate,
              withinDays: 14, reference: referenceDate),
          isTrue);
      expect(
          AppDateUtils.isDueSoon(farFuture,
              withinDays: 14, reference: referenceDate),
          isFalse);
    });
  });

  group('MoneyFormat Tests', () {
    test('formats Indian Rupee amounts with symbol and grouping', () {
      final largeAmount = MoneyFormat.format(180000);
      expect(largeAmount, contains('₹'));
      expect(largeAmount, contains('1,80,000'));

      final smallAmount = MoneyFormat.format(2500);
      expect(smallAmount, contains('₹'));
      expect(smallAmount, contains('2,500'));

      final zeroAmount = MoneyFormat.format(0);
      expect(zeroAmount, contains('₹0'));
    });
  });
}
