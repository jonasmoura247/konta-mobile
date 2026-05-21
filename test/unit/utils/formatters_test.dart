import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:konta/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  group('formatCurrency', () {
    test('formats BRL positive value with correct number', () {
      final result = formatCurrency(1500.50);
      expect(result, contains('1.500,50'));
    });

    test('formats BRL positive value with currency symbol', () {
      final result = formatCurrency(1500.50);
      expect(result, startsWith(r'R$'));
    });

    test('formats zero as 0,00', () {
      expect(formatCurrency(0), contains('0,00'));
    });

    test('formats USD value', () {
      expect(formatCurrency(99.99, currency: 'USD'), contains('99.99'));
    });
  });

  group('formatMonth', () {
    test('formats may 2026 in pt_BR', () {
      expect(formatMonth(DateTime(2026, 5)), 'maio 2026');
    });

    test('formats january 2026', () {
      expect(formatMonth(DateTime(2026, 1)), 'janeiro 2026');
    });
  });

  group('formatMonthShort', () {
    test('formats january 2026 short', () {
      expect(formatMonthShort(DateTime(2026, 1)), contains('jan'));
    });

    test('formats december 2025 short', () {
      expect(formatMonthShort(DateTime(2025, 12)), contains('dez'));
    });
  });

  group('formatDate', () {
    test('formats date as dd/MM/yyyy', () {
      expect(formatDate(DateTime(2026, 5, 20)), '20/05/2026');
    });
  });

  group('formatDateShort', () {
    test('formats date as dd/MM', () {
      expect(formatDateShort(DateTime(2026, 5, 20)), '20/05');
    });
  });

  group('isSameMonth', () {
    test('returns true for same year and month', () {
      expect(isSameMonth(DateTime(2026, 5, 1), DateTime(2026, 5, 31)), isTrue);
    });

    test('returns false for different months', () {
      expect(isSameMonth(DateTime(2026, 5), DateTime(2026, 6)), isFalse);
    });

    test('returns false for same month different year', () {
      expect(isSameMonth(DateTime(2025, 5), DateTime(2026, 5)), isFalse);
    });
  });

  group('monthDiff', () {
    test('returns 0 for same month', () {
      expect(monthDiff(DateTime(2026, 5), DateTime(2026, 5)), 0);
    });

    test('returns 1 for next month', () {
      expect(monthDiff(DateTime(2026, 5), DateTime(2026, 6)), 1);
    });

    test('returns 12 for next year same month', () {
      expect(monthDiff(DateTime(2025, 1), DateTime(2026, 1)), 12);
    });

    test('returns negative for past month', () {
      expect(monthDiff(DateTime(2026, 6), DateTime(2026, 5)), -1);
    });
  });

  group('lastDayOfMonth', () {
    test('returns 31 for January', () {
      expect(lastDayOfMonth(DateTime(2026, 1)).day, 31);
    });

    test('returns 28 for February in non-leap year', () {
      expect(lastDayOfMonth(DateTime(2025, 2)).day, 28);
    });

    test('returns 29 for February in leap year', () {
      expect(lastDayOfMonth(DateTime(2024, 2)).day, 29);
    });

    test('returns 30 for April', () {
      expect(lastDayOfMonth(DateTime(2026, 4)).day, 30);
    });
  });

  group('groupLabel', () {
    test('maps avista to Credito', () {
      expect(groupLabel('avista'), 'Crédito');
    });

    test('maps parcelamento', () {
      expect(groupLabel('parcelamento'), 'Parcelamento');
    });

    test('maps assinatura', () {
      expect(groupLabel('assinatura'), 'Assinatura');
    });

    test('maps debito to Debito', () {
      expect(groupLabel('debito'), 'Débito');
    });

    test('returns id unchanged for unknown group', () {
      expect(groupLabel('desconhecido'), 'desconhecido');
    });
  });

  group('capitalize', () {
    test('capitalizes first letter', () {
      expect(capitalize('netflix'), 'Netflix');
    });

    test('leaves empty string unchanged', () {
      expect(capitalize(''), '');
    });

    test('does not change already capitalized string', () {
      expect(capitalize('Netflix'), 'Netflix');
    });
  });
}
