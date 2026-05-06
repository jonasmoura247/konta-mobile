import 'package:flutter/material.dart';
import '../services/finance_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'summary_card.dart';
import 'annual_comparison_chart.dart';

class AnnualControlSection extends StatelessWidget {
  final YearSummary yearSummary;
  final YearComparison? yearComparison;
  final int compareYear;
  final List<int> availableCompareYears;
  final ValueChanged<int> onCompareYearChanged;
  final String currency;

  const AnnualControlSection({
    super.key,
    required this.yearSummary,
    required this.compareYear,
    required this.availableCompareYears,
    required this.onCompareYearChanged,
    required this.currency,
    this.yearComparison,
  });

  static const _monthNames = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  String _periodLabel() {
    final until = yearSummary.untilMonth;
    final year = yearSummary.year;
    if (until <= 1) return 'Janeiro de $year';
    if (until >= 12) return 'Janeiro a dezembro de $year';
    return 'Janeiro a ${_monthNames[until - 1]} de $year';
  }

  double _monthBalance(DateTime month) {
    final s = yearSummary.monthSummaries[month.month - 1];
    return s.totalIncome - s.totalExpenses - s.totalDebit;
  }

  @override
  Widget build(BuildContext context) {
    final year = yearSummary.year;
    final incomes =
        yearSummary.monthSummaries.map((s) => s.totalIncome).toList();
    final outflows = yearSummary.monthSummaries
        .map((s) => s.totalExpenses + s.totalDebit)
        .toList();

    final hasBest = yearSummary.bestMonth != null;
    final hasWorst = yearSummary.worstMonth != null &&
        yearSummary.worstMonth != yearSummary.bestMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controle anual $year',
              style: TextStyle(
                color: context.kTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _periodLabel(),
              style: TextStyle(color: context.kTextSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Cards 2x2
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                label: 'Entradas no ano',
                value: yearSummary.totalIncome,
                color: AppColors.income,
                icon: Icons.trending_up,
                currency: currency,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                label: 'Saídas no ano',
                value: yearSummary.totalOutflow,
                color: AppColors.expense,
                icon: Icons.trending_down,
                currency: currency,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                label: 'Saldo anual',
                value: yearSummary.annualBalance,
                color: yearSummary.annualBalance >= 0
                    ? AppColors.income
                    : AppColors.expense,
                icon: yearSummary.annualBalance >= 0
                    ? Icons.account_balance_wallet
                    : Icons.warning_amber,
                currency: currency,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                label: 'Média mensal',
                value: yearSummary.monthlyAverage,
                color: AppColors.accent,
                icon: Icons.bar_chart,
                currency: currency,
              ),
            ),
          ],
        ),

        // Melhor / pior mês
        if (hasBest || hasWorst) ...[
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.kCardBorder),
            ),
            child: Row(
              children: [
                if (hasBest)
                  Expanded(
                    child: _MonthInsight(
                      label: 'Melhor mês',
                      month: yearSummary.bestMonth!,
                      balance: _monthBalance(yearSummary.bestMonth!),
                      color: AppColors.income,
                      currency: currency,
                    ),
                  ),
                if (hasBest && hasWorst)
                  Container(
                    width: 1,
                    height: 36,
                    color: context.kCardBorder,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                if (hasWorst)
                  Expanded(
                    child: _MonthInsight(
                      label: 'Pior mês',
                      month: yearSummary.worstMonth!,
                      balance: _monthBalance(yearSummary.worstMonth!),
                      color: AppColors.expense,
                      currency: currency,
                    ),
                  ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Gráfico comparativo anual
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.kCardBorder),
          ),
          child: AnnualComparisonChart(
            months: yearSummary.months,
            incomes: incomes,
            outflows: outflows,
            currency: currency,
            untilMonth: yearSummary.untilMonth,
          ),
        ),

        // Seção de comparação com ano anterior
        if (availableCompareYears.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ComparisonSection(
            yearComparison: yearComparison,
            compareYear: compareYear,
            availableYears: availableCompareYears,
            onYearChanged: onCompareYearChanged,
            currency: currency,
            currentYear: year,
            untilMonth: yearSummary.untilMonth,
          ),
        ],
      ],
    );
  }
}

class _MonthInsight extends StatelessWidget {
  final String label;
  final DateTime month;
  final double balance;
  final Color color;
  final String currency;

  const _MonthInsight({
    required this.label,
    required this.month,
    required this.balance,
    required this.color,
    required this.currency,
  });

  static const _months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  @override
  Widget build(BuildContext context) {
    final monthName = _months[month.month - 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: context.kTextSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              monthName,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                formatCurrency(balance, currency: currency),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontFamily: 'JetBrainsMono',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  final YearComparison? yearComparison;
  final int compareYear;
  final List<int> availableYears;
  final ValueChanged<int> onYearChanged;
  final String currency;
  final int currentYear;
  final int untilMonth;

  const _ComparisonSection({
    required this.yearComparison,
    required this.compareYear,
    required this.availableYears,
    required this.onYearChanged,
    required this.currency,
    required this.currentYear,
    required this.untilMonth,
  });

  static const _months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  String get _untilLabel => _months[untilMonth - 1];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seletor de ano
          Row(
            children: [
              Text(
                'Comparar com:',
                style: TextStyle(color: context.kTextSecondary, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableYears.map((y) {
                      final selected = y == compareYear;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => onYearChanged(y),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.accent.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppColors.accent
                                    : context.kCardBorder,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              '$y',
                              style: TextStyle(
                                color: selected
                                    ? AppColors.accent
                                    : context.kTextSecondary,
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (yearComparison == null)
            Text(
              'Ainda não há dados suficientes para comparar anos.\nContinue registrando seus lançamentos para ver a evolução anual.',
              style: TextStyle(color: context.kTextSecondary, fontSize: 12),
            )
          else
            _buildInsights(context, yearComparison!),
        ],
      ),
    );
  }

  Widget _buildInsights(BuildContext context, YearComparison cmp) {
    final better = cmp.balanceDiff >= 0;
    final balanceColor = better ? AppColors.income : AppColors.expense;
    final balanceText = better
        ? 'Você está ${formatCurrency(cmp.balanceDiff.abs(), currency: currency)} melhor que $compareYear até $_untilLabel.'
        : 'Você está ${formatCurrency(cmp.balanceDiff.abs(), currency: currency)} pior que $compareYear até $_untilLabel.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InsightRow(
          icon: better ? Icons.trending_up : Icons.trending_down,
          color: balanceColor,
          text: balanceText,
        ),
        const SizedBox(height: 8),
        _InsightRow(
          icon: cmp.incomePercent >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
          color: cmp.incomePercent >= 0 ? AppColors.income : AppColors.expense,
          text: _pctText('Entradas', cmp.incomePercent),
        ),
        const SizedBox(height: 6),
        _InsightRow(
          icon: cmp.outflowPercent >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
          color: cmp.outflowPercent >= 0 ? AppColors.expense : AppColors.income,
          text: _pctText('Saídas', cmp.outflowPercent),
        ),
      ],
    );
  }

  String _pctText(String label, double pct) {
    final rounded = pct.abs().toStringAsFixed(1);
    final direction = pct >= 0 ? 'subiram' : 'caíram';
    return '$label $direction $rounded%.';
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InsightRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: context.kTextPrimary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
