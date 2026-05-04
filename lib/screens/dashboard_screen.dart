import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/income.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/summary_card.dart';
import '../widgets/charts_carousel.dart';
import '../widgets/bar_chart_6months.dart';
import '../widgets/month_picker_button.dart';
import '../widgets/add_transaction_form.dart';
import '../widgets/add_income_form.dart';
import '../widgets/incomes_list_sheet.dart';
import '../services/pdf_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime _activeMonth = DateTime.now();
  bool _familyView = false;

  // Resumo da visão ativa (normal ou família)
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
    final familyCount = settings.familyMode ? settings.familyCount : 1;

    // Visão ativa: normal = todos, família = só familyMode=true
    _summary = FinanceCalculator.summarize(
      transactions, incomes, _activeMonth, familyCount,
      familyOnly: _familyView,
    );

    _last6Months = FinanceCalculator.lastNMonths(_activeMonth, 6);
    _last6Expenses = _last6Months.map((m) {
      return FinanceCalculator.summarize(transactions, incomes, m, familyCount, familyOnly: _familyView).totalExpenses;
    }).toList();
    _last6Incomes = _last6Months.map((m) {
      return FinanceCalculator.summarize(transactions, incomes, m, familyCount, familyOnly: _familyView).totalIncome;
    }).toList();
  }

  void _changeMonth(int delta) {
    setState(() {
      _activeMonth = DateTime(_activeMonth.year, _activeMonth.month + delta);
      _recalculate();
    });
  }

  void _toggleFamilyView() {
    setState(() {
      _familyView = !_familyView;
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

  void _openAddIncome({Income? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddIncomeForm(
        editing: editing,
        onSave: (inc) async {
          if (editing != null) {
            await DatabaseService.updateIncome(inc);
          } else {
            await DatabaseService.addIncome(inc);
          }
          setState(_recalculate);
        },
        onDelete: editing != null
            ? () async {
                await DatabaseService.deleteIncome(editing);
                setState(_recalculate);
              }
            : null,
      ),
    );
  }

  void _openIncomesList() {
    final incomes = DatabaseService.getAllIncomes();
    final settings = DatabaseService.getSettings();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncomesListSheet(
        activeMonth: _activeMonth,
        incomes: incomes,
        currency: settings.currency,
        onSave: (inc) async {
          if (incomes.any((e) => e.id == inc.id)) {
            await DatabaseService.updateIncome(inc);
          } else {
            await DatabaseService.addIncome(inc);
          }
          setState(_recalculate);
        },
        onDelete: (inc) async {
          await DatabaseService.deleteIncome(inc);
          setState(_recalculate);
        },
      ),
    );
  }

  Future<void> _generateFamilyPdf() async {
    await PdfService.generateFamilyReport(_activeMonth);
  }

  @override
  Widget build(BuildContext context) {
    final settings = DatabaseService.getSettings();
    final currency = settings.currency;
    final hasFamilyMode = settings.familyMode;
    final familyCount = settings.familyCount;

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
                    // ── Header ──────────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // "Konta" + ícone de config → abre Settings
                        GestureDetector(
                          onTap: () => context.push('/settings'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Konta', style: const TextStyle(color: AppColors.accent, fontSize: 22, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 6),
                                  Icon(Icons.settings_outlined, size: 15, color: AppColors.accent.withValues(alpha: 0.6)),
                                ],
                              ),
                              Text(
                                _familyView ? '👨‍👩‍👧 Vista Família' : 'Controle Financeiro',
                                style: TextStyle(
                                  color: _familyView ? AppColors.warning : context.kTextSecondary,
                                  fontSize: 12,
                                  fontWeight: _familyView ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Toggle família (apenas quando familyMode está ativo)
                        if (hasFamilyMode) ...[
                          GestureDetector(
                            onTap: _toggleFamilyView,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _familyView ? AppColors.warning.withValues(alpha: 0.2) : context.kCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _familyView ? AppColors.warning : context.kCardBorder,
                                  width: _familyView ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.group, size: 14, color: _familyView ? AppColors.warning : context.kTextSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Família',
                                    style: TextStyle(
                                      color: _familyView ? AppColors.warning : context.kTextSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Seletor de mês — compacto e responsivo
                        MonthPickerButton(
                          activeMonth: _activeMonth,
                          onChanged: (m) => setState(() {
                            _activeMonth = m;
                            _recalculate();
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Banner Vista Família ─────────────────────────────────
                    if (_familyView) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.group, color: AppColors.warning, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Exibindo apenas lançamentos compartilhados · $familyCount pessoas · valor por pessoa',
                                style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Cards de resumo ──────────────────────────────────────
                    if (!_familyView) ...[
                      Row(
                        children: [
                          Expanded(child: SummaryCard(
                            label: 'Gastos',
                            value: _summary.totalExpenses,
                            color: AppColors.expense,
                            icon: Icons.trending_down,
                            currency: currency,
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: SummaryCard(
                            label: 'Entradas',
                            value: _summary.totalIncome,
                            color: AppColors.income,
                            icon: Icons.trending_up,
                            currency: currency,
                            onTap: _openIncomesList,
                          )),
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
                    ],

                    // ── Cartões Vista Família ─────────────────────────────────
                    if (_familyView) ...[
                      Row(
                        children: [
                          Expanded(child: SummaryCard(
                            label: 'Total Familiar',
                            value: _summary.totalExpenses * familyCount,
                            color: AppColors.warning,
                            icon: Icons.group,
                            currency: currency,
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: SummaryCard(
                            label: 'Por Pessoa',
                            value: _summary.totalExpenses,
                            color: AppColors.accent,
                            icon: Icons.person,
                            currency: currency,
                          )),
                        ],
                      ),
                    ],

                    // ── Botão PDF família (apenas na vista família) ───────────
                    if (hasFamilyMode && _familyView) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('Gerar PDF Família'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            side: const BorderSide(color: AppColors.warning),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: _generateFamilyPdf,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Carrossel de gráficos ────────────────────────────────
                    ChartsCarousel(summary: _summary, currency: currency),
                    const SizedBox(height: 24),

                    // ── Gráfico 6 meses ──────────────────────────────────────
                    Text('Histórico 6 meses', style: TextStyle(color: context.kTextPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: context.kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.kCardBorder)),
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

