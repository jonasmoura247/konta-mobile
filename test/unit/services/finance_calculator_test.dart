import 'package:flutter_test/flutter_test.dart';
import 'package:konta/models/income.dart';
import 'package:konta/models/transaction.dart';
import 'package:konta/services/finance_calculator.dart';

Transaction tx({
  required String id,
  required String groupId,
  required double totalAmount,
  required DateTime startDate,
  int installments = 1,
  bool familyMode = false,
  DateTime? cancelledFrom,
  DateTime? invoiceMonth,
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
    invoiceMonth: invoiceMonth,
  );
}

void main() {
  // ── Testes existentes (assinatura) ───────────────────────────────────────

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

  // ── Parcelamento ─────────────────────────────────────────────────────────

  group('parcelamento', () {
    test('3x purchase appears in 3 consecutive months', () {
      final transactions = [
        tx(
          id: 'tv',
          groupId: 'parcelamento',
          totalAmount: 3000,
          installments: 3,
          startDate: DateTime(2026, 4, 10),
        ),
      ];

      final april = FinanceCalculator.getOccurrencesForMonth(
          transactions, DateTime(2026, 4), 1);
      final may = FinanceCalculator.getOccurrencesForMonth(
          transactions, DateTime(2026, 5), 1);
      final june = FinanceCalculator.getOccurrencesForMonth(
          transactions, DateTime(2026, 6), 1);
      final july = FinanceCalculator.getOccurrencesForMonth(
          transactions, DateTime(2026, 7), 1);

      expect(april.single.amount, 1000.0);
      expect(may.single.amount, 1000.0);
      expect(june.single.amount, 1000.0);
      expect(july, isEmpty);
    });

    test('does not appear in months before start', () {
      final transactions = [
        tx(
          id: 'geladeira',
          groupId: 'parcelamento',
          totalAmount: 2400,
          installments: 6,
          startDate: DateTime(2026, 6, 1),
        ),
      ];

      final may = FinanceCalculator.getOccurrencesForMonth(
          transactions, DateTime(2026, 5), 1);
      expect(may, isEmpty);
    });

    test('family installment is divided by family count', () {
      final transactions = [
        tx(
          id: 'sofa',
          groupId: 'parcelamento',
          totalAmount: 4000,
          installments: 4,
          startDate: DateTime(2026, 5, 1),
          familyMode: true,
        ),
      ];

      final may = FinanceCalculator.getOccurrencesForMonth(
          transactions, DateTime(2026, 5), 4);
      expect(may.single.amount, closeTo(250.0, 0.01));
    });
  });

  // ── getBillingMonth (sem fechamento de cartão) ───────────────────────────

  group('getBillingMonth', () {
    test('invoiceMonth has absolute priority over any rule', () {
      final t = tx(
        id: 'compra',
        groupId: 'avista',
        totalAmount: 500,
        startDate: DateTime(2026, 5, 25),
        invoiceMonth: DateTime(2026, 5),
      );

      expect(FinanceCalculator.getBillingMonth(t), DateTime(2026, 5));
    });

    test('without applyClosureDate returns startDate month', () {
      final t = Transaction(
        id: 'c1',
        groupId: 'avista',
        categoryId: 'outros',
        description: 'Compra',
        totalAmount: 100,
        startDate: DateTime(2026, 5, 25),
        createdAt: DateTime(2026, 5, 25),
        applyClosureDate: false,
      );

      expect(FinanceCalculator.getBillingMonth(t), DateTime(2026, 5, 25));
    });

    test('without bankId returns startDate even with applyClosureDate', () {
      final t = Transaction(
        id: 'c2',
        groupId: 'avista',
        categoryId: 'outros',
        description: 'Compra',
        totalAmount: 100,
        startDate: DateTime(2026, 5, 25),
        createdAt: DateTime(2026, 5, 25),
        applyClosureDate: true,
        bankId: null,
      );

      expect(FinanceCalculator.getBillingMonth(t), DateTime(2026, 5, 25));
    });
  });

  // ── Débito ───────────────────────────────────────────────────────────────

  group('getDebitOccurrencesForMonth', () {
    test('debit appears only in its own month', () {
      final transactions = [
        tx(
          id: 'onibus',
          groupId: 'debito',
          totalAmount: 50,
          startDate: DateTime(2026, 5, 10),
        ),
      ];

      final may = FinanceCalculator.getDebitOccurrencesForMonth(
          transactions, DateTime(2026, 5), 1);
      final june = FinanceCalculator.getDebitOccurrencesForMonth(
          transactions, DateTime(2026, 6), 1);

      expect(may.single.amount, 50.0);
      expect(june, isEmpty);
    });

    test('debit is excluded from getOccurrencesForMonth', () {
      final transactions = [
        tx(
          id: 'onibus',
          groupId: 'debito',
          totalAmount: 50,
          startDate: DateTime(2026, 5, 10),
        ),
      ];

      final may = FinanceCalculator.getOccurrencesForMonth(
          transactions, DateTime(2026, 5), 1);
      expect(may, isEmpty);
    });
  });

  // ── summarize ────────────────────────────────────────────────────────────

  group('summarize', () {
    test('balance = income - credit - debit', () {
      final transactions = [
        tx(
          id: 'supermercado',
          groupId: 'avista',
          totalAmount: 300,
          startDate: DateTime(2026, 5, 5),
        ),
        tx(
          id: 'onibus',
          groupId: 'debito',
          totalAmount: 50,
          startDate: DateTime(2026, 5, 10),
        ),
      ];
      final incomes = [
        Income(
          id: 'i1',
          description: 'Salário',
          amount: 5000,
          date: DateTime(2026, 5, 1),
          recurring: false,
        ),
      ];

      final summary = FinanceCalculator.summarize(
          transactions, incomes, DateTime(2026, 5), 1);

      expect(summary.totalExpenses, 300.0);
      expect(summary.totalDebit, 50.0);
      expect(summary.totalIncome, 5000.0);
      expect(summary.balance, 4650.0);
    });
  });

  // ── getIncomeForMonth ────────────────────────────────────────────────────

  group('getIncomeForMonth', () {
    test('recurring income counts in every month', () {
      final incomes = [
        Income(
          id: 'salario',
          description: 'Salário',
          amount: 4000,
          date: DateTime(2026, 1, 5),
          recurring: true,
        ),
      ];

      expect(
          FinanceCalculator.getIncomeForMonth(incomes, DateTime(2026, 5)),
          4000);
      expect(
          FinanceCalculator.getIncomeForMonth(incomes, DateTime(2026, 12)),
          4000);
    });

    test('non-recurring income counts only in its own month', () {
      final incomes = [
        Income(
          id: 'bonus',
          description: 'Bônus',
          amount: 1000,
          date: DateTime(2026, 3, 15),
          recurring: false,
        ),
      ];

      expect(
          FinanceCalculator.getIncomeForMonth(incomes, DateTime(2026, 3)),
          1000);
      expect(
          FinanceCalculator.getIncomeForMonth(incomes, DateTime(2026, 4)), 0);
    });

    test('isFamilyValue income does NOT count in getIncomeForMonth', () {
      final incomes = [
        Income(
          id: 'fam',
          description: 'Valor família',
          amount: 2000,
          date: DateTime(2026, 5, 1),
          recurring: true,
          isFamilyValue: true,
        ),
      ];

      expect(
          FinanceCalculator.getIncomeForMonth(incomes, DateTime(2026, 5)), 0);
    });

    test('isFamilyValue income counts in getFamilyIncomeForMonth', () {
      final incomes = [
        Income(
          id: 'fam',
          description: 'Valor família',
          amount: 2000,
          date: DateTime(2026, 5, 1),
          recurring: true,
          isFamilyValue: true,
        ),
      ];

      expect(
          FinanceCalculator.getFamilyIncomeForMonth(incomes, DateTime(2026, 5)),
          2000);
    });
  });

  // ── lastNMonths ──────────────────────────────────────────────────────────

  group('lastNMonths', () {
    test('returns months in ascending order', () {
      final months = FinanceCalculator.lastNMonths(DateTime(2026, 5), 3);
      expect(months, [
        DateTime(2026, 3),
        DateTime(2026, 4),
        DateTime(2026, 5),
      ]);
    });

    test('crosses year boundary correctly', () {
      final months = FinanceCalculator.lastNMonths(DateTime(2026, 1), 3);
      expect(months, [
        DateTime(2025, 11),
        DateTime(2025, 12),
        DateTime(2026, 1),
      ]);
    });
  });

  // ── getCarryover ─────────────────────────────────────────────────────────

  group('getCarryover', () {
    test('returns 0 when no prior months have data', () {
      final transactions = [
        tx(
          id: 'tx1',
          groupId: 'avista',
          totalAmount: 100,
          startDate: DateTime(2026, 5, 1),
        ),
      ];
      final incomes = [
        Income(
          id: 'i1',
          description: 'Salário',
          amount: 3000,
          date: DateTime(2026, 5, 1),
          recurring: false,
        ),
      ];

      final carryover = FinanceCalculator.getCarryover(
          transactions, incomes, DateTime(2026, 5), 1);
      expect(carryover, 0.0);
    });

    test('accumulates surplus from prior months', () {
      final incomes = [
        Income(
          id: 'sal',
          description: 'Salário',
          amount: 1000,
          date: DateTime(2026, 4, 1),
          recurring: false,
        ),
      ];
      final transactions = [
        tx(
          id: 'gasto',
          groupId: 'avista',
          totalAmount: 200,
          startDate: DateTime(2026, 4, 5),
        ),
      ];

      final carryover = FinanceCalculator.getCarryover(
          transactions, incomes, DateTime(2026, 5), 1);
      expect(carryover, closeTo(800.0, 0.01));
    });
  });
}
