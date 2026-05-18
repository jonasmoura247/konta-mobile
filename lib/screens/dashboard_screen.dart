import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../services/month_selection_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/summary_card.dart';
import '../widgets/charts_carousel.dart';
import '../widgets/annual_control_section.dart';
import '../widgets/month_picker_button.dart';
import '../widgets/add_transaction_form.dart';
import '../widgets/incomes_list_sheet.dart';
import '../services/pdf_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime _activeMonth = MonthSelectionService.activeMonth.value;
  bool _familyView = false;

  // Resumo da visão ativa (normal ou família)
  late MonthSummary _summary;

  late YearSummary _yearSummary;
  YearComparison? _yearComparison;
  List<int> _yearsWithData = [];
  int _compareYear = DateTime.now().year - 1;

  @override
  void initState() {
    super.initState();
    DatabaseService.dataVersion.addListener(_onDataChanged);
    MonthSelectionService.activeMonth.addListener(_onSelectedMonthChanged);
    _recalculate();
  }

  @override
  void dispose() {
    DatabaseService.dataVersion.removeListener(_onDataChanged);
    MonthSelectionService.activeMonth.removeListener(_onSelectedMonthChanged);
    super.dispose();
  }

  void _onDataChanged() => setState(_recalculate);

  void _onSelectedMonthChanged() {
    final selected = MonthSelectionService.activeMonth.value;
    if (selected == _activeMonth) return;
    setState(() {
      _activeMonth = selected;
      _recalculate();
    });
  }

  void _recalculate() {
    MonthSelectionService.setActiveMonth(_activeMonth);
    final settings = DatabaseService.getSettings();
    final transactions = DatabaseService.getAllTransactions();
    final incomes = DatabaseService.getAllIncomes();
    final familyCount = settings.familyMode ? settings.familyCount : 1;

    final carryover = settings.carryoverMode
        ? FinanceCalculator.getCarryover(
            transactions, incomes, _activeMonth, familyCount)
        : 0.0;

    // Visão ativa: normal = todos, família = só familyMode=true
    _summary = FinanceCalculator.summarize(
      transactions,
      incomes,
      _activeMonth,
      familyCount,
      familyOnly: _familyView,
      carryover: carryover,
    );

    final year = DateTime.now().year;

    // Controle anual
    _yearsWithData = FinanceCalculator.getYearsWithData(transactions, incomes);
    _yearSummary = FinanceCalculator.summarizeYear(
      transactions,
      incomes,
      year,
      familyCount,
      familyOnly: _familyView,
    );
    _yearComparison =
        _yearsWithData.contains(_compareYear) && _compareYear < year
            ? FinanceCalculator.compareYears(
                transactions,
                incomes,
                year,
                _compareYear,
                familyCount,
                familyOnly: _familyView,
              )
            : null;

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
        initialDate: _activeMonth,
        onSave: (t) async {
          await DatabaseService.addTransaction(t);
          setState(_recalculate);
        },
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
        child: RefreshIndicator(
          onRefresh: () async => setState(_recalculate),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                                    Text('Konta',
                                        style: const TextStyle(
                                            color: AppColors.accent,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: Icon(Icons.settings_outlined,
                                          size: 22,
                                          color: AppColors.accent),
                                    ),
                                  ],
                                ),
                                if (_familyView)
                                  Text(
                                    '👨‍👩‍👧 Vista Família',
                                    style: const TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _familyView
                                      ? AppColors.warning.withValues(alpha: 0.2)
                                      : context.kCard,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _familyView
                                        ? AppColors.warning
                                        : context.kCardBorder,
                                    width: _familyView ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.group,
                                        size: 14,
                                        color: _familyView
                                            ? AppColors.warning
                                            : context.kTextSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Família',
                                      style: TextStyle(
                                        color: _familyView
                                            ? AppColors.warning
                                            : context.kTextSecondary,
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
                              _activeMonth = MonthSelectionService.normalize(m);
                              MonthSelectionService.setActiveMonth(
                                  _activeMonth);
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppColors.warning.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.group,
                                  color: AppColors.warning, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Exibindo apenas lançamentos compartilhados · $familyCount pessoas · valor por pessoa',
                                  style: const TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
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
                            Expanded(
                                child: SummaryCard(
                              label: 'Cartão',
                              value: _summary.totalExpenses,
                              color: AppColors.expense,
                              icon: Icons.credit_card,
                              currency: currency,
                                            )),
                            const SizedBox(width: 10),
                            Expanded(
                                child: SummaryCard(
                              label: 'Entradas',
                              value: _summary.totalIncome,
                              color: AppColors.income,
                              icon: Icons.trending_up,
                              currency: currency,
                              onTap: _openIncomesList,
                                            )),
                          ],
                        ),
                        if (_summary.familyIncomeForMonth > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people_outline, color: Colors.purple, size: 16),
                                const SizedBox(width: 8),
                                Text('Entradas Família (não somam no saldo)',
                                    style: TextStyle(color: Colors.purple, fontSize: 12)),
                                const Spacer(),
                                Text(
                                  formatCurrency(_summary.familyIncomeForMonth, currency: currency),
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (_summary.totalDebit > 0) ...[
                          SummaryCard(
                            label: 'Débito',
                            value: _summary.totalDebit,
                            color: AppColors.neonCyan,
                            icon: Icons.payment,
                            currency: currency,
                                        ),
                          const SizedBox(height: 10),
                        ],
                        SummaryCard(
                          label: 'Saldo',
                          value: _summary.balance,
                          color: _summary.balance >= 0
                              ? AppColors.income
                              : AppColors.expense,
                          icon: _summary.balance >= 0
                              ? Icons.account_balance_wallet
                              : Icons.warning_amber,
                          currency: currency,
                                    ),
                        if (_summary.carryover != 0.0) ...[
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_summary.carryover >= 0
                                      ? AppColors.income
                                      : AppColors.expense)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: (_summary.carryover >= 0
                                          ? AppColors.income
                                          : AppColors.expense)
                                      .withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.history,
                                    color: _summary.carryover >= 0
                                        ? AppColors.income
                                        : AppColors.expense,
                                    size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  _summary.carryover >= 0
                                      ? '↑ inclui ${formatCurrency(_summary.carryover, currency: currency)} acumulado de meses anteriores'
                                      : '↓ déficit de ${formatCurrency(_summary.carryover.abs(), currency: currency)} de meses anteriores',
                                  style: TextStyle(
                                    color: _summary.carryover >= 0
                                        ? AppColors.income
                                        : AppColors.expense,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      // ── Cartões Vista Família ─────────────────────────────────
                      if (_familyView) ...[
                        Row(
                          children: [
                            Expanded(
                                child: SummaryCard(
                              label: 'Total Familiar',
                              value: _summary.totalExpenses * familyCount,
                              color: AppColors.warning,
                              icon: Icons.group,
                              currency: currency,
                                            )),
                            const SizedBox(width: 10),
                            Expanded(
                                child: SummaryCard(
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

                      // ── Controle anual ────────────────────────────────────────
                      AnnualControlSection(
                        yearSummary: _yearSummary,
                        yearComparison: _yearComparison,
                        compareYear: _compareYear,
                        availableCompareYears: _yearsWithData
                            .where((y) => y < DateTime.now().year)
                            .toList(),
                        onCompareYearChanged: (y) => setState(() {
                          _compareYear = y;
                          _recalculate();
                        }),
                        currency: currency,
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}
