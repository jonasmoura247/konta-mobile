import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class BarChart6Months extends StatelessWidget {
  final List<DateTime> months;
  final List<double> expenses;
  final List<double> incomes;

  const BarChart6Months({
    super.key,
    required this.months,
    required this.expenses,
    required this.incomes,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = [...expenses, ...incomes].fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            _LegendDot(color: AppColors.expense, label: 'Gastos'),
            SizedBox(width: 16),
            _LegendDot(color: AppColors.income, label: 'Entradas'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxVal * 1.2,
              barGroups: List.generate(months.length, (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(toY: expenses[i], color: AppColors.expense, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  BarChartRodData(toY: incomes[i], color: AppColors.income, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                ],
                barsSpace: 4,
              )),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(
                      formatMonthShort(months[v.toInt()]),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.cardBorder, strokeWidth: 1),
                drawVerticalLine: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      );
}
