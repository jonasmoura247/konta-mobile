import 'package:konta/models/transaction.dart';
import 'package:konta/services/finance_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction tx({
  required String id,
  required String groupId,
  required double totalAmount,
  required DateTime startDate,
  int installments = 1,
  bool familyMode = false,
  DateTime? cancelledFrom,
}) {
  return Transaction(
    id: id,
    groupId: groupId,
    categoryId: 'outros',
    description: id,
    totalAmount: totalAmount,
    installments: installments,
    startDate: startDate,
    isSubscription: groupId == 'assinatura',
    familyMode: familyMode,
    cancelledFrom: cancelledFrom,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  test('divide edited family cash transaction by family count', () {
    final transactions = [
      tx(
        id: 'mercado',
        groupId: 'avista',
        totalAmount: 900,
        startDate: DateTime(2026, 5, 6),
        familyMode: true,
      ),
    ];

    final occurrences = FinanceCalculator.getOccurrencesForMonth(
      transactions,
      DateTime(2026, 5),
      4,
    );

    expect(occurrences.single.amount, 225);
  });

  test('keeps old subscription value before a versioned change', () {
    final transactions = [
      tx(
        id: 'old',
        groupId: 'assinatura',
        totalAmount: 39.90,
        startDate: DateTime(2026, 1),
        cancelledFrom: DateTime(2026, 3),
      ),
      tx(
        id: 'new',
        groupId: 'assinatura',
        totalAmount: 49.90,
        startDate: DateTime(2026, 3),
      ),
    ];

    final february = FinanceCalculator.getOccurrencesForMonth(
      transactions,
      DateTime(2026, 2),
      1,
    );
    final march = FinanceCalculator.getOccurrencesForMonth(
      transactions,
      DateTime(2026, 3),
      1,
    );

    expect(february.single.amount, 39.90);
    expect(march.single.amount, 49.90);
  });

  test('keeps cancellation month and stops subscription on following months',
      () {
    final transactions = [
      tx(
        id: 'streaming',
        groupId: 'assinatura',
        totalAmount: 39.90,
        startDate: DateTime(2026, 1),
        cancelledFrom: DateTime(2026, 4),
      ),
    ];

    expect(
      FinanceCalculator.getOccurrencesForMonth(
        transactions,
        DateTime(2026, 3),
        1,
      ),
      hasLength(1),
    );
    expect(
      FinanceCalculator.getOccurrencesForMonth(
        transactions,
        DateTime(2026, 4),
        1,
      ),
      isEmpty,
    );
  });

  test('preserves monthly subscription history across edit and cancellation',
      () {
    final transactions = [
      tx(
        id: 'old',
        groupId: 'assinatura',
        totalAmount: 49.90,
        startDate: DateTime(2026, 5),
        cancelledFrom: DateTime(2026, 6),
      ),
      tx(
        id: 'new',
        groupId: 'assinatura',
        totalAmount: 59.90,
        startDate: DateTime(2026, 6),
        cancelledFrom: DateTime(2026, 9),
      ),
    ];

    double totalFor(DateTime month) => FinanceCalculator.getOccurrencesForMonth(
          transactions,
          month,
          1,
        ).fold(0.0, (sum, occurrence) => sum + occurrence.amount);

    expect(totalFor(DateTime(2026, 5)), 49.90);
    expect(totalFor(DateTime(2026, 6)), 59.90);
    expect(totalFor(DateTime(2026, 7, 20)), 59.90);
    expect(totalFor(DateTime(2026, 8)), 59.90);
    expect(totalFor(DateTime(2026, 9)), 0);
    expect(totalFor(DateTime(2026, 10)), 0);
  });

  test(
      'keeps january to april value, changes in may, and keeps july cancel month',
      () {
    final transactions = [
      tx(
        id: 'netflix-old',
        groupId: 'assinatura',
        totalAmount: 49.90,
        startDate: DateTime(2026, 1),
        cancelledFrom: DateTime(2026, 5),
      ),
      tx(
        id: 'netflix-new',
        groupId: 'assinatura',
        totalAmount: 59.90,
        startDate: DateTime(2026, 5),
        cancelledFrom: DateTime(2026, 8),
      ),
    ];

    double totalFor(int month) => FinanceCalculator.getOccurrencesForMonth(
          transactions,
          DateTime(2026, month),
          1,
        ).fold(0.0, (sum, occurrence) => sum + occurrence.amount);

    expect(totalFor(1), 49.90);
    expect(totalFor(2), 49.90);
    expect(totalFor(3), 49.90);
    expect(totalFor(4), 49.90);
    expect(totalFor(5), 59.90);
    expect(totalFor(6), 59.90);
    expect(totalFor(7), 59.90);
    expect(totalFor(8), 0);
  });
}
