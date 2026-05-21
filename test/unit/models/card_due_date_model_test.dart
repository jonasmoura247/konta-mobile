import 'package:flutter_test/flutter_test.dart';
import 'package:konta/models/card_due_date.dart';

void main() {
  group('CardDueDate.closureDayFor', () {
    test('returns configured closureDay when no override', () {
      final cdd = CardDueDate(bankId: 'nubank', closureDay: 15, paymentDay: 10);
      expect(cdd.closureDayFor(DateTime(2026, 5)), 15);
    });

    test('returns override when set for that month', () {
      final cdd = CardDueDate(bankId: 'nubank', closureDay: 15, paymentDay: 10);
      cdd.setClosureOverride(DateTime(2026, 5), 20);
      expect(cdd.closureDayFor(DateTime(2026, 5)), 20);
    });

    test('does not apply override to other months', () {
      final cdd = CardDueDate(bankId: 'nubank', closureDay: 15, paymentDay: 10);
      cdd.setClosureOverride(DateTime(2026, 5), 20);
      expect(cdd.closureDayFor(DateTime(2026, 6)), 15);
    });

    test('clamps day 31 to last day of February in non-leap year', () {
      final cdd = CardDueDate(bankId: 'itau', closureDay: 31, paymentDay: 10);
      expect(cdd.closureDayFor(DateTime(2025, 2)), 28);
    });

    test('clamps day 31 to 29 in leap February', () {
      final cdd = CardDueDate(bankId: 'itau', closureDay: 31, paymentDay: 10);
      expect(cdd.closureDayFor(DateTime(2024, 2)), 29);
    });

    test('clamps day 31 to 30 in April', () {
      final cdd = CardDueDate(bankId: 'itau', closureDay: 31, paymentDay: 10);
      expect(cdd.closureDayFor(DateTime(2026, 4)), 30);
    });
  });

  group('CardDueDate.paymentDayFor', () {
    test('returns configured paymentDay when no override', () {
      final cdd = CardDueDate(bankId: 'nubank', closureDay: 15, paymentDay: 5);
      expect(cdd.paymentDayFor(DateTime(2026, 5)), 5);
    });

    test('returns override when set for that month', () {
      final cdd = CardDueDate(bankId: 'nubank', closureDay: 15, paymentDay: 5);
      cdd.setPaymentOverride(DateTime(2026, 5), 10);
      expect(cdd.paymentDayFor(DateTime(2026, 5)), 10);
    });
  });

  group('CardDueDate.monthKey', () {
    test('formats may 2026 correctly', () {
      expect(CardDueDate.monthKey(DateTime(2026, 5)), '202605');
    });

    test('formats december 2026 correctly', () {
      expect(CardDueDate.monthKey(DateTime(2026, 12)), '202612');
    });

    test('pads single-digit month with zero', () {
      expect(CardDueDate.monthKey(DateTime(2026, 1)), '202601');
    });
  });

  group('CardDueDate.toJson / fromJson', () {
    test('round-trip preserves base fields', () {
      final cdd = CardDueDate(bankId: 'itau', closureDay: 15, paymentDay: 10);
      final restored = CardDueDate.fromJson(cdd.toJson());
      expect(restored.bankId, 'itau');
      expect(restored.closureDay, 15);
      expect(restored.paymentDay, 10);
    });

    test('round-trip preserves closure overrides', () {
      final cdd = CardDueDate(bankId: 'itau', closureDay: 15, paymentDay: 10);
      cdd.setClosureOverride(DateTime(2026, 5), 20);
      final restored = CardDueDate.fromJson(cdd.toJson());
      expect(restored.closureDayFor(DateTime(2026, 5)), 20);
      expect(restored.closureDay, 15);
    });

    test('round-trip preserves null overrides as null', () {
      final cdd = CardDueDate(bankId: 'nubank', closureDay: 10, paymentDay: 5);
      final restored = CardDueDate.fromJson(cdd.toJson());
      expect(restored.overrideClosure, isNull);
    });
  });
}
