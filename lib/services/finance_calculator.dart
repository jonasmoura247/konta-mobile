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
  final double balance;
  final Map<String, double> byCategory;
  final Map<String, double> byGroup;
  final Map<String, double> byBank;

  const MonthSummary({
    required this.totalExpenses,
    required this.totalIncome,
    required this.balance,
    required this.byCategory,
    required this.byGroup,
    required this.byBank,
  });
}

class FinanceCalculator {
  // Porta fiel da lógica getOccurrencesForMonth do Farmas web.
  // [familyOnly]: quando true, retorna apenas lançamentos marcados como familyMode=true
  static List<TransactionOccurrence> getOccurrencesForMonth(
    List<Transaction> transactions,
    DateTime yearMonth,
    int familyCount, {
    bool familyOnly = false,
  }) {
    final result = <TransactionOccurrence>[];
    final divisor = familyCount > 1 ? familyCount.toDouble() : 1.0;

    for (final t in transactions) {
      // Modo família: se familyOnly=true, ignora transações não-família
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
  }) {
    final occurrences = getOccurrencesForMonth(transactions, yearMonth, familyCount, familyOnly: familyOnly);
    final totalExpenses = occurrences.fold(0.0, (s, o) => s + o.amount);
    final totalIncome = getIncomeForMonth(incomes, yearMonth);

    final byCategory = <String, double>{};
    final byGroup = <String, double>{};
    final byBank = <String, double>{};

    for (final o in occurrences) {
      byCategory[o.transaction.categoryId] = (byCategory[o.transaction.categoryId] ?? 0) + o.amount;
      byGroup[o.transaction.groupId] = (byGroup[o.transaction.groupId] ?? 0) + o.amount;
      final bank = o.transaction.bankId ?? 'sem_banco';
      byBank[bank] = (byBank[bank] ?? 0) + o.amount;
    }

    return MonthSummary(
      totalExpenses: totalExpenses,
      totalIncome: totalIncome,
      balance: totalIncome - totalExpenses,
      byCategory: byCategory,
      byGroup: byGroup,
      byBank: byBank,
    );
  }

  /// Calcula o total BRUTO da família: restaura o divisor para obter o valor real
  /// (mesmo cálculo que totalExpensesAll no web)
  static double getGrossFamilyExpenses(
    List<Transaction> transactions,
    DateTime yearMonth,
    int familyCount,
  ) {
    // Pega ocorrências sem divisão (familyCount=1) e sem filtro
    final raw = getOccurrencesForMonth(transactions, yearMonth, 1);
    // O amount já está sem divisão; apenas some tudo
    return raw.fold(0.0, (s, o) => s + o.amount);
  }

  // Últimos N meses a partir de uma data base
  static List<DateTime> lastNMonths(DateTime base, int n) {
    return List.generate(n, (i) {
      final offset = n - 1 - i;
      var month = base.month - offset;
      var year = base.year;
      while (month <= 0) { month += 12; year--; }
      return DateTime(year, month);
    });
  }
}
