import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ReserveEvolutionChart extends StatelessWidget {
  final List<DateTime> months;
  final List<double> totals;
  final String currency;

  const ReserveEvolutionChart({
    super.key,
    required this.months,
    required this.totals,
    this.currency = 'BRL',
  });

  @override
  Widget build(BuildContext context) {
    final hasData = totals.any((t) => t > 0);

    if (!hasData) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📈', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'Adicione reservas para ver a evolução',
              style: TextStyle(color: context.kTextSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final maxVal = totals.fold(0.0, (a, b) => a > b ? a : b);
    final gridColor = context.kCardBorder;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= months.length) return const SizedBox.shrink();
                return Text(
                  formatMonthAbbrev(months[i]),
                  style: TextStyle(color: context.kTextSecondary, fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              months.length,
              (i) => FlSpot(i.toDouble(), totals[i]),
            ),
            isCurved: true,
            color: AppColors.income,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.income.withValues(alpha: 0.12),
            ),
          ),
        ],
        minX: 0,
        maxX: (months.length - 1).toDouble(),
        minY: 0,
        maxY: maxVal * 1.25 < 1 ? 1 : maxVal * 1.25,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      formatCurrency(s.y, currency: currency),
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
