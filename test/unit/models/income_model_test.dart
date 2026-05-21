import 'package:flutter_test/flutter_test.dart';
import 'package:konta/models/income.dart';

Income makeIncome({
  String id = 'i1',
  String description = 'Salário',
  double amount = 5000.0,
  DateTime? date,
  bool recurring = false,
  bool isFamilyValue = false,
}) {
  return Income(
    id: id,
    description: description,
    amount: amount,
    date: date ?? DateTime(2026, 5, 1),
    recurring: recurring,
    isFamilyValue: isFamilyValue,
  );
}

void main() {
  group('Income.toJson / fromJson', () {
    test('round-trip preserves all fields', () {
      final income = makeIncome(amount: 3500.0, recurring: true);
      final restored = Income.fromJson(income.toJson());

      expect(restored.id, income.id);
      expect(restored.description, income.description);
      expect(restored.amount, income.amount);
      expect(restored.date, DateTime(2026, 5, 1));
      expect(restored.recurring, true);
      expect(restored.isFamilyValue, false);
    });

    test('round-trip preserves isFamilyValue true', () {
      final income = makeIncome(isFamilyValue: true);
      final restored = Income.fromJson(income.toJson());
      expect(restored.isFamilyValue, true);
    });

    test('fromJson defaults isFamilyValue to false when field is absent', () {
      final json = makeIncome().toJson()..remove('isFamilyValue');
      final restored = Income.fromJson(json);
      expect(restored.isFamilyValue, false);
    });

    test('fromJson defaults recurring to false when field is absent', () {
      final json = makeIncome().toJson()..remove('recurring');
      final restored = Income.fromJson(json);
      expect(restored.recurring, false);
    });

    test('round-trip preserves non-recurring income', () {
      final income = makeIncome(recurring: false, date: DateTime(2026, 3, 15));
      final restored = Income.fromJson(income.toJson());
      expect(restored.recurring, false);
      expect(restored.date, DateTime(2026, 3, 15));
    });
  });
}
