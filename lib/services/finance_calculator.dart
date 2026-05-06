import '../models/transaction.dart';
import '../models/income.dart';
import '../utils/formatters.dart';

class TransactionOccurrence {
  final Transaction transaction;
  final double amount;
  final int installmentIndex;
  final int installmentTotal;

  const TransactionOccurrence({
    required this.transaction,
    required this.amount,
    this.installmentIndex = 0,
    this.installmentTotal = 1,
  });
}

class MonthSummary {
  final double totalExpenses;
  final double totalIncome;
  final double totalDebit;
  final double carryover;
  final double balance;
  final Map<String, double> byCategory;
  final Map<String, double> byGroup;
  final Map<String, double> byBank;
  final Map<String, double> byDebitCategory;

  const MonthSummary({
    required this.totalExpenses,
    required this.totalIncome,
    required this.totalDebit,
    required this.balance,
    required this.byCategory,
    required this.byGroup,
    required this.byBank,
    required this.byDebitCategory,
    this.carryover = 0.0,
  });
}

class YearSummary {
  final int year;
  final int untilMonth;
  final List<DateTime> months;
  final List<MonthSummary> monthSummaries;
  final double totalIncome;
  final double totalExpenses;
  final double totalDebit;
  final double totalOutflow;
  final double annualBalance;
  final double monthlyAverage;
  final DateTime? bestMonth;
  final DateTime? worstMonth;

  const YearSummary({
    required this.year,
    required this.untilMonth,
    required this.months,
    required this.monthSummaries,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalDebit,
    required this.totalOutflow,
    required this.annualBalance,
    required this.monthlyAverage,
    this.bestMonth,
    this.worstMonth,
  });
}

class YearComparison {
  final YearSummary current;
  final YearSummary previous;
  final double incomeDiff;
  final double outflowDiff;
  final double balanceDiff;
  final double incomePercent;
  final double outflowPercent;
  final double balancePercent;

  const YearComparison({
    required this.current,
    required this.previous,
    required this.incomeDiff,
    required this.outflowDiff,
    required this.balanceDiff,
    required this.incomePercent,
    required this.outflowPercent,
    required this.balancePercent,
  });
}

class FinanceCalculator {
  // Retorna ocorrências de crédito (avista, parcelamento, assinatura) — exclui débito.
  static List<TransactionOccurrence> getOccurrencesForMonth(
    List<Transaction> transactions,
    DateTime yearMonth,
    int familyCount, {
    bool familyOnly = false,
  }) {
    final result = <TransactionOccurrence>[];
    final divisor = familyCount > 1 ? familyCount.toDouble() : 1.0;

    for (final t in transactions) {
      if (t.groupId == 'debito') continue;
      if (familyOnly && !t.familyMode) continue;

      switch (t.groupId) {
        case 'avista':
          if (isSameMonth(t.startDate, yearMonth)) {
            final amount = t.familyMode ? t.totalAmount / divisor : t.totalAmount;
            result.add(TransactionOccurrence(transaction: t, amount: amount));
          }

        case 'parcelamento':
          final diff = monthDiff(t.startDate, yearMonth);
          if (diff >= 0 && diff < t.installments) {
            final monthly = t.totalAmount / t.installments;
            final amount = t.familyMode ? monthly / divisor : monthly;
            result.add(TransactionOccurrence(
              transaction: t,
              amount: amount,
              installmentIndex: diff + 1,
              installmentTotal: t.installments,
            ));
          }

        case 'assinatura':
          final started = !yearMonth.isBefore(DateTime(t.startDate.year, t.startDate.month));
          final notCancelled = t.cancelledFrom == null ||
              yearMonth.isBefore(DateTime(t.cancelledFrom!.year, t.cancelledFrom!.month));
          if (started && notCancelled) {
            final amount = t.familyMode ? t.totalAmount / divisor : t.totalAmount;
            result.add(TransactionOccurrence(transaction: t, amount: amount));
          }
      }
    }

    result.sort((a, b) => b.transaction.startDate.compareTo(a.transaction.startDate));
    return result;
  }

  // Retorna ocorrências de débito direto do mês (sempre à vista, só desconta do saldo).
  static List<TransactionOccurrence> getDebitOccurrencesForMonth(
    List<Transaction> transactions,
    DateTime yearMonth,
    int familyCount, {
    bool familyOnly = false,
  }) {
    final result = <TransactionOccurrence>[];
    final divisor = familyCount > 1 ? familyCount.toDouble() : 1.0;

    for (final t in transactions) {
      if (t.groupId != 'debito') continue;
      if (familyOnly && !t.familyMode) continue;
      if (!isSameMonth(t.startDate, yearMonth)) continue;
      final amount = t.familyMode ? t.totalAmount / divisor : t.totalAmount;
      result.add(TransactionOccurrence(transaction: t, amount: amount));
    }

    result.sort((a, b) => b.transaction.startDate.compareTo(a.transaction.startDate));
    return result;
  }

  static double getIncomeForMonth(List<Income> incomes, DateTime yearMonth) {
    double total = 0;
    for (final i in incomes) {
      if (i.recurring || isSameMonth(i.date, yearMonth)) {
        total += i.amount;
      }
    }
    return total;
  }

  static MonthSummary summarize(
    List<Transaction> transactions,
    List<Income> incomes,
    DateTime yearMonth,
    int familyCount, {
    bool familyOnly = false,
    double carryover = 0.0,
  }) {
    final occurrences = getOccurrencesForMonth(transactions, yearMonth, familyCount, familyOnly: familyOnly);
    final totalExpenses = occurrences.fold(0.0, (s, o) => s + o.amount);
    final totalIncome = getIncomeForMonth(incomes, yearMonth);

    final debitOccurrences = getDebitOccurrencesForMonth(transactions, yearMonth, familyCount, familyOnly: familyOnly);
    final totalDebit = debitOccurrences.fold(0.0, (s, o) => s + o.amount);

    final byCategory = <String, double>{};
    final byGroup = <String, double>{};
    final byBank = <String, double>{};
    final byDebitCategory = <String, double>{};

    for (final o in occurrences) {
      byCategory[o.transaction.categoryId] = (byCategory[o.transaction.categoryId] ?? 0) + o.amount;
      byGroup[o.transaction.groupId] = (byGroup[o.transaction.groupId] ?? 0) + o.amount;
      final bank = o.transaction.bankId ?? 'sem_banco';
      byBank[bank] = (byBank[bank] ?? 0) + o.amount;
    }

    for (final o in debitOccurrences) {
      byDebitCategory[o.transaction.categoryId] = (byDebitCategory[o.transaction.categoryId] ?? 0) + o.amount;
    }

    return MonthSummary(
      totalExpenses: totalExpenses,
      totalIncome: totalIncome,
      totalDebit: totalDebit,
      carryover: carryover,
      balance: totalIncome + carryover - totalExpenses - totalDebit,
      byCategory: byCategory,
      byGroup: byGroup,
      byBank: byBank,
      byDebitCategory: byDebitCategory,
    );
  }

  /// Calcula o total BRUTO da família (sem divisão por membro), apenas crédito.
  static double getGrossFamilyExpenses(
    List<Transaction> transactions,
    DateTime yearMonth,
    int familyCount,
  ) {
    final raw = getOccurrencesForMonth(transactions, yearMonth, 1);
    return raw.fold(0.0, (s, o) => s + o.amount);
  }

  static List<DateTime> lastNMonths(DateTime base, int n) {
    return List.generate(n, (i) {
      final offset = n - 1 - i;
      var month = base.month - offset;
      var year = base.year;
      while (month <= 0) { month += 12; year--; }
      return DateTime(year, month);
    });
  }

  /// Retorna todos os meses que têm pelo menos 1 transação ou entrada, ordenados.
  static List<DateTime> getMonthsWithData(
    List<Transaction> transactions,
    List<Income> incomes,
  ) {
    final months = <DateTime>{};
    for (final t in transactions) {
      months.add(DateTime(t.startDate.year, t.startDate.month));
    }
    for (final i in incomes) {
      months.add(DateTime(i.date.year, i.date.month));
    }
    final list = months.toList()..sort();
    return list;
  }

  static YearSummary summarizeYear(
    List<Transaction> transactions,
    List<Income> incomes,
    int year,
    int familyCount, {
    int? untilMonth,
    bool familyOnly = false,
  }) {
    final now = DateTime.now();
    final lastMonth = (untilMonth ?? (year == now.year ? now.month : 12)).clamp(1, 12);

    final months = List.generate(12, (i) => DateTime(year, i + 1));
    final summaries = months
        .map((m) => summarize(transactions, incomes, m, familyCount, familyOnly: familyOnly))
        .toList();

    double totalIncome = 0;
    double totalExpenses = 0;
    double totalDebit = 0;

    for (int i = 0; i < lastMonth; i++) {
      totalIncome += summaries[i].totalIncome;
      totalExpenses += summaries[i].totalExpenses;
      totalDebit += summaries[i].totalDebit;
    }

    final totalOutflow = totalExpenses + totalDebit;
    final annualBalance = totalIncome - totalOutflow;
    final monthlyAverage = lastMonth > 0 ? annualBalance / lastMonth : 0.0;

    DateTime? bestMonth;
    DateTime? worstMonth;
    double? bestBalance;
    double? worstBalance;

    for (int i = 0; i < lastMonth; i++) {
      final s = summaries[i];
      final hasData = s.totalIncome > 0 || s.totalExpenses > 0 || s.totalDebit > 0;
      if (!hasData) continue;
      final b = s.totalIncome - s.totalExpenses - s.totalDebit;
      if (bestBalance == null || b > bestBalance) {
        bestBalance = b;
        bestMonth = months[i];
      }
      if (worstBalance == null || b < worstBalance) {
        worstBalance = b;
        worstMonth = months[i];
      }
    }

    return YearSummary(
      year: year,
      untilMonth: lastMonth,
      months: months,
      monthSummaries: summaries,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalDebit: totalDebit,
      totalOutflow: totalOutflow,
      annualBalance: annualBalance,
      monthlyAverage: monthlyAverage,
      bestMonth: bestMonth,
      worstMonth: worstMonth,
    );
  }

  static YearComparison compareYears(
    List<Transaction> transactions,
    List<Income> incomes,
    int currentYear,
    int previousYear,
    int familyCount, {
    int? untilMonth,
    bool familyOnly = false,
  }) {
    final current = summarizeYear(
      transactions, incomes, currentYear, familyCount,
      untilMonth: untilMonth, familyOnly: familyOnly,
    );
    final previous = summarizeYear(
      transactions, incomes, previousYear, familyCount,
      untilMonth: current.untilMonth, familyOnly: familyOnly,
    );

    double safePct(double a, double b) => b == 0 ? 0 : ((a - b) / b) * 100;

    return YearComparison(
      current: current,
      previous: previous,
      incomeDiff: current.totalIncome - previous.totalIncome,
      outflowDiff: current.totalOutflow - previous.totalOutflow,
      balanceDiff: current.annualBalance - previous.annualBalance,
      incomePercent: safePct(current.totalIncome, previous.totalIncome),
      outflowPercent: safePct(current.totalOutflow, previous.totalOutflow),
      balancePercent: safePct(current.annualBalance, previous.annualBalance),
    );
  }

  static List<int> getYearsWithData(
    List<Transaction> transactions,
    List<Income> incomes,
  ) {
    final years = <int>{};
    for (final t in transactions) { years.add(t.startDate.year); }
    for (final i in incomes) { years.add(i.date.year); }
    return years.toList()..sort();
  }

  /// Calcula o saldo acumulado de meses anteriores ao mês alvo.
  static double getCarryover(
    List<Transaction> transactions,
    List<Income> incomes,
    DateTime targetMonth,
    int familyCount,
  ) {
    final allMonths = getMonthsWithData(transactions, incomes);
    final target = DateTime(targetMonth.year, targetMonth.month);
    final prevMonths = allMonths.where((m) => m.isBefore(target)).toList();

    double accumulated = 0.0;
    for (final month in prevMonths) {
      final s = summarize(transactions, incomes, month, familyCount);
      accumulated = s.totalIncome + accumulated - s.totalExpenses - s.totalDebit;
    }
    return accumulated;
  }
}
