import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/summary_card.dart';
import '../widgets/donut_chart.dart';
import '../widgets/bar_chart_6months.dart';
import '../widgets/add_transaction_form.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime _activeMonth = DateTime.now();
  late MonthSummary _summary;
  late List<DateTime> _last6Months;
  late List<double> _last6Expenses;
  late List<double> _last6Incomes;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  void _recalculate() {
    final settings = DatabaseService.getSettings();
    final transactions = DatabaseService.getAllTransactions();
    final incomes = DatabaseService.getAllIncomes();

    _summary = FinanceCalculator.summarize(
      transactions, incomes, _activeMonth, settings.familyMode ? settings.familyCount : 1,
    );

    _last6Months = FinanceCalculator.lastNMonths(_activeMonth, 6);
    _last6Expenses = _last6Months.map((m) {
      final s = FinanceCalculator.summarize(transactions, incomes, m, settings.familyMode ? settings.familyCount : 1);
      return s.totalExpenses;
    }).toList();
    _last6Incomes = _last6Months.map((m) {
      final s = FinanceCalculator.summarize(transactions, incomes, m, settings.familyMode ? settings.familyCount : 1);
      return s.totalIncome;
    }).toList();
  }

  void _changeMonth(int delta) {
    setState(() {
      _activeMonth = DateTime(_activeMonth.year, _activeMonth.month + delta);
      _recalculate();
    });
  }

  void _openAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionForm(
        onSave: (t) async {
          await DatabaseService.addTransaction(t);
          setState(_recalculate);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = DatabaseService.getSettings();
    final currency = settings.currency;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Farmas', style: TextStyle(color: AppColors.accent, fontSize: 22, fontWeight: FontWeight.bold)),
                            Text('Controle Financeiro', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
                          child: Row(
                            children: [
                              IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary), iconSize: 20),
                              Text(formatMonth(_activeMonth), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                              IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary), iconSize: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Cards de resumo
                    Row(
                      children: [
                        Expanded(child: SummaryCard(label: 'Gastos', value: _summary.totalExpenses, color: AppColors.expense, icon: Icons.trending_down, currency: currency)),
                        const SizedBox(width: 10),
                        Expanded(child: SummaryCard(label: 'Entradas', value: _summary.totalIncome, color: AppColors.income, icon: Icons.trending_up, currency: currency)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SummaryCard(
                      label: 'Saldo',
                      value: _summary.balance,
                      color: _summary.balance >= 0 ? AppColors.income : AppColors.expense,
                      icon: _summary.balance >= 0 ? Icons.account_balance_wallet : Icons.warning_amber,
                      currency: currency,
                    ),
                    const SizedBox(height: 24),

                    // Donut chart
                    const Text('Gastos por Categoria', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
                      child: SizedBox(
                        height: 160,
                        child: DonutChart(data: _summary.byCategory, total: _summary.totalExpenses, currency: currency),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gráfico 6 meses
                    const Text('Histórico 6 meses', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
                      child: BarChart6Months(months: _last6Months, expenses: _last6Expenses, incomes: _last6Incomes),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}
