import '../models/transaction.dart';
import '../models/income.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';

class TransactionOccurrence {
  final Transaction transaction;
  final double amount;
  final int installmentIndex;
  final int installmentTotal;
  /// Data efetiva no mês de cobrança: mesmo dia da compra, mês da fatura.
  final DateTime billingDate;

  const TransactionOccurrence({
    required this.transaction,
    required this.amount,
    required this.billingDate,
    this.installmentIndex = 0,
    this.installmentTotal = 1,
  });
}

class MonthSummary {
  final double totalExpenses;
  final double totalIncome;
  final double familyIncomeForMonth; // Entradas marcadas como "valor de família"
  final double totalDebit;
  final double carryover;
  final double balance;
  final Map<String, double> byCategory;
  final Map<String, double> byGroup;
  final Map<String, double> byBank;
  final Map<String, double> byDebitCategory;
  // Total bruto por cartão, sem divisão familiar
  final Map<String, double> byBankGross;

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
    this.byBankGross = const {},
    this.familyIncomeForMonth = 0.0,
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
  final DateTime? highestIncomeMonth;
  final DateTime? lowestIncomeMonth;

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
    this.highestIncomeMonth,
    this.lowestIncomeMonth,
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
  /// Mesmo dia da compra no mês de cobrança, clampado ao último dia do mês.
  static DateTime _billingDate(DateTime billingMonth, int purchaseDay) {
    final lastDay = DateTime(billingMonth.year, billingMonth.month + 1, 0).day;
    return DateTime(billingMonth.year, billingMonth.month, purchaseDay.clamp(1, lastDay));
  }

  /// Retorna o mês de cobrança de uma transação de crédito (avista ou parcelamento).
  ///
  /// Prioridade:
  ///   1. Se `t.invoiceMonth != null` → usa esse mês SEM NENHUMA regra automática.
  ///      A escolha manual do usuário é absoluta e não pode ser movida.
  ///   2. Caso contrário, aplica a regra de fechamento do cartão (se applyClosureDate=true):
  ///      - Compra ANTES do fechamento → cobrança no mês seguinte (ciclo atual fecha este mês)
  ///      - Compra NO DIA do fechamento ou APÓS → cobrança dois meses depois (entra no próximo ciclo)
  ///      - Sem banco configurado / sem CardDueDate → mantém mês da compra
  static DateTime getBillingMonth(Transaction t) {
    // Prioridade absoluta: mês definido manualmente pelo usuário
    if (t.invoiceMonth != null) {
      return DateTime(t.invoiceMonth!.year, t.invoiceMonth!.month);
    }

    if (!t.applyClosureDate) return t.startDate;
    if (t.bankId == null) return t.startDate;
    if (t.groupId != 'avista' && t.groupId != 'parcelamento') return t.startDate;

    final cdd = DatabaseService.getCardDueDate(t.bankId!);
    if (cdd == null) return t.startDate;

    final closureDay = cdd.closureDayFor(t.startDate);

    if (t.startDate.day < closureDay) {
      return DateTime(t.startDate.year, t.startDate.month + 1);
    } else {
      return DateTime(t.startDate.year, t.startDate.month + 2);
    }
  }

  // Retorna ocorrências de crédito (avista, parcelamento, assinatura) — exclui débito.
  static List<TransactionOccurrence> getOccurrencesForMonth(
    List<Transaction> transactions,
    DateTime yearMonth,
    int familyCount, {
    bool familyOnly = false,
  }) {
    final result = <TransactionOccurrence>[];
    final divisor = familyCount > 1 ? familyCount.toDouble() : 1.0;
    final targetMonth = DateTime(yearMonth.year, yearMonth.month);

    for (final t in transactions) {
      if (t.groupId == 'debito') continue;
      if (familyOnly && !t.familyMode) continue;

      switch (t.groupId) {
        case 'avista':
          // Usa mês de cobrança (pode ser próximo mês se após fechamento do cartão)
          final billingMonth = getBillingMonth(t);
          if (isSameMonth(billingMonth, yearMonth)) {
            final amount =
                t.familyMode ? t.totalAmount / divisor : t.totalAmount;
            result.add(TransactionOccurrence(
              transaction: t,
              amount: amount,
              billingDate: _billingDate(yearMonth, t.startDate.day),
            ));
          }

        case 'parcelamento':
          // O primeiro mês da parcela é o mês de cobrança (respeitando fechamento do cartão)
          final billingStart = getBillingMonth(t);
          final diff = monthDiff(billingStart, yearMonth);
          if (diff >= 0 && diff < t.installments) {
            final monthly = t.totalAmount / t.installments;
            final amount = t.familyMode ? monthly / divisor : monthly;
            result.add(TransactionOccurrence(
              transaction: t,
              amount: amount,
              billingDate: _billingDate(yearMonth, t.startDate.day),
              installmentIndex: diff + 1,
              installmentTotal: t.installments,
            ));
          }

        case 'assinatura':
          final started = !targetMonth
              .isBefore(DateTime(t.startDate.year, t.startDate.month));
          final notCancelled = t.cancelledFrom == null ||
              targetMonth.isBefore(
                  DateTime(t.cancelledFrom!.year, t.cancelledFrom!.month));
          if (started && notCancelled) {
            final amount =
                t.familyMode ? t.totalAmount / divisor : t.totalAmount;
            result.add(TransactionOccurrence(
              transaction: t,
              amount: amount,
              billingDate: _billingDate(yearMonth, t.startDate.day),
            ));
          }
      }
    }

    result.sort((a, b) => b.billingDate.compareTo(a.billingDate));
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
      result.add(TransactionOccurrence(
        transaction: t,
        amount: amount,
        billingDate: t.startDate,
      ));
    }

    result.sort((a, b) => b.billingDate.compareTo(a.billingDate));
    return result;
  }

  static double getIncomeForMonth(List<Income> incomes, DateTime yearMonth) {
    double total = 0;
    for (final i in incomes) {
      // Excluir entradas marcadas como "valor de família"
      if (i.isFamilyValue) continue;
      if (i.recurring || isSameMonth(i.date, yearMonth)) {
        total += i.amount;
      }
    }
    return total;
  }

  // Retorna soma das entradas marcadas como "valor de família" (informativo, não afeta saldo)
  static double getFamilyIncomeForMonth(List<Income> incomes, DateTime yearMonth) {
    double total = 0;
    for (final i in incomes) {
      // Considerar APENAS entradas com isFamilyValue=true
      if (!i.isFamilyValue) continue;
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
    final occurrences = getOccurrencesForMonth(
        transactions, yearMonth, familyCount,
        familyOnly: familyOnly);
    final totalExpenses = occurrences.fold(0.0, (s, o) => s + o.amount);
    final totalIncome = getIncomeForMonth(incomes, yearMonth);
    final familyIncomeForMonth = getFamilyIncomeForMonth(incomes, yearMonth);

    final debitOccurrences = getDebitOccurrencesForMonth(
        transactions, yearMonth, familyCount,
        familyOnly: familyOnly);
    final totalDebit = debitOccurrences.fold(0.0, (s, o) => s + o.amount);

    final byCategory = <String, double>{};
    final byGroup = <String, double>{};
    final byBank = <String, double>{};
    final byDebitCategory = <String, double>{};

    for (final o in occurrences) {
      byCategory[o.transaction.categoryId] =
          (byCategory[o.transaction.categoryId] ?? 0) + o.amount;
      byGroup[o.transaction.groupId] =
          (byGroup[o.transaction.groupId] ?? 0) + o.amount;
      final bank = o.transaction.bankId ?? 'sem_banco';
      byBank[bank] = (byBank[bank] ?? 0) + o.amount;
    }

    for (final o in debitOccurrences) {
      byDebitCategory[o.transaction.categoryId] =
          (byDebitCategory[o.transaction.categoryId] ?? 0) + o.amount;
    }

    // Total bruto por cartão sem divisão familiar
    final byBankGross = <String, double>{};
    final grossOccurrences = getOccurrencesForMonth(transactions, yearMonth, 1, familyOnly: false);
    for (final o in grossOccurrences) {
      final bank = o.transaction.bankId ?? 'sem_banco';
      byBankGross[bank] = (byBankGross[bank] ?? 0) + o.amount;
    }

    return MonthSummary(
      totalExpenses: totalExpenses,
      totalIncome: totalIncome,
      familyIncomeForMonth: familyIncomeForMonth,
      totalDebit: totalDebit,
      carryover: carryover,
      balance: totalIncome + carryover - totalExpenses - totalDebit,
      byCategory: byCategory,
      byGroup: byGroup,
      byBank: byBank,
      byDebitCategory: byDebitCategory,
      byBankGross: byBankGross,
    );
  }

  /// Calcula o total BRUTO da família (sem divisão por membro), apenas crédito.
  static double getGrossFamilyExpenses(
    List<Transaction> transactions,
    DateTime yearMonth,
    int familyCount,
  ) {
    final raw =
        getOccurrencesForMonth(transactions, yearMonth, 1, familyOnly: true);
    return raw.fold(0.0, (s, o) => s + o.amount);
  }

  static List<DateTime> lastNMonths(DateTime base, int n) {
    return List.generate(n, (i) {
      final offset = n - 1 - i;
      var month = base.month - offset;
      var year = base.year;
      while (month <= 0) {
        month += 12;
        year--;
      }
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
    final lastMonth =
        (untilMonth ?? (year == now.year ? now.month : 12)).clamp(1, 12);

    final months = List.generate(12, (i) => DateTime(year, i + 1));
    final summaries = months
        .map((m) => summarize(transactions, incomes, m, familyCount,
            familyOnly: familyOnly))
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
    DateTime? highestIncomeMonth;
    DateTime? lowestIncomeMonth;
    double? maxIncome;
    double? minIncome;

    for (int i = 0; i < lastMonth; i++) {
      final s = summaries[i];
      final hasData =
          s.totalIncome > 0 || s.totalExpenses > 0 || s.totalDebit > 0;
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
      if (s.totalIncome > 0) {
        if (maxIncome == null || s.totalIncome > maxIncome) {
          maxIncome = s.totalIncome;
          highestIncomeMonth = months[i];
        }
        if (minIncome == null || s.totalIncome < minIncome) {
          minIncome = s.totalIncome;
          lowestIncomeMonth = months[i];
        }
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
      highestIncomeMonth: highestIncomeMonth,
      lowestIncomeMonth: lowestIncomeMonth,
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
      transactions,
      incomes,
      currentYear,
      familyCount,
      untilMonth: untilMonth,
      familyOnly: familyOnly,
    );
    final previous = summarizeYear(
      transactions,
      incomes,
      previousYear,
      familyCount,
      untilMonth: current.untilMonth,
      familyOnly: familyOnly,
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
    for (final t in transactions) {
      years.add(t.startDate.year);
      // Para parcelamentos, adiciona todos os anos até o fim das parcelas
      if (t.groupId == 'parcelamento' && t.installments > 1) {
        final totalMonths = t.startDate.month + t.installments - 1;
        final endYear = t.startDate.year + (totalMonths - 1) ~/ 12;
        for (int y = t.startDate.year + 1; y <= endYear; y++) {
          years.add(y);
        }
      }
    }
    for (final i in incomes) {
      years.add(i.date.year);
    }
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
      accumulated =
          s.totalIncome + accumulated - s.totalExpenses - s.totalDebit;
    }
    return accumulated;
  }
}
