import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:capsicum/core/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('DateFormatter', () {
    group('formatRelative', () {
      test('returns "Hari ini" for current date', () {
        final now = DateTime.now();
        final result = DateFormatter.formatRelative(now);
        expect(result, startsWith('Hari ini,'));
      });

      test('returns "Kemarin" for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final result = DateFormatter.formatRelative(yesterday);
        expect(result, startsWith('Kemarin,'));
      });

      test('returns formatted date for older dates', () {
        final oldDate = DateTime(2024, 1, 15, 10, 30);
        final result = DateFormatter.formatRelative(oldDate);
        expect(result, contains('2024'));
      });

      test('includes time in result', () {
        final now = DateTime(2024, 7, 15, 14, 30);
        final result = DateFormatter.formatRelative(now);
        expect(result, contains('14:30'));
      });
    });

    group('formatFull', () {
      test('returns full date string with year', () {
        final date = DateTime(2024, 7, 15, 14, 30);
        final result = DateFormatter.formatFull(date);
        expect(result, contains('2024'));
      });

      test('includes time', () {
        final date = DateTime(2024, 7, 15, 14, 30);
        final result = DateFormatter.formatFull(date);
        expect(result, contains('14:30'));
      });
    });

    group('formatDate', () {
      test('returns date without time', () {
        final date = DateTime(2024, 7, 15);
        final result = DateFormatter.formatDate(date);
        expect(result, contains('2024'));
        expect(result, isNot(contains(':')));
      });
    });
  });
}
