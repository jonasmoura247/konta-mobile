import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AnnualComparisonChart extends StatefulWidget {
  final List<DateTime> months;
  final List<double> incomes;
  final List<double> outflows;
  final String currency;
  final int untilMonth;

  const AnnualComparisonChart({
    super.key,
    required this.months,
    required this.incomes,
    required this.outflows,
    required this.currency,
    required this.untilMonth,
  });

  @override
  State<AnnualComparisonChart> createState() => _AnnualComparisonChartState();
}

class _AnnualComparisonChartState extends State<AnnualComparisonChart> {
  late final ScrollController _scrollCtrl;
  int? _touchedGroupIndex;
  int? _touchedRodIndex;

  static const _rodLabels = ['Entradas', 'Saídas'];
  static const _rodColors = [AppColors.income, AppColors.expense];

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final n = widget.months.length;
      if (n <= 6) return;
      final maxScroll = _scrollCtrl.position.maxScrollExtent;
      final targetIndex = (widget.untilMonth - 1).clamp(0, n - 1);
      final offset = (targetIndex * maxScroll / (n - 6)).clamp(0.0, maxScroll);
      _scrollCtrl.jumpTo(offset);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = [...widget.incomes, ...widget.outflows]
        .fold(0.0, (a, b) => a > b ? a : b);
    final n = widget.months.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: AppColors.income, label: 'Entradas'),
            const SizedBox(width: 16),
            _LegendDot(color: AppColors.expense, label: 'Saídas'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth / 6 * n;
              return SingleChildScrollView(
                controller: _scrollCtrl,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalWidth,
                  child: BarChart(
                    BarChartData(
                      maxY: maxVal * 1.25 < 1 ? 1 : maxVal * 1.25,
                      barTouchData: BarTouchData(
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions ||
                              response?.spot == null) {
                            return;
                          }
                          setState(() {
                            _touchedGroupIndex =
                                response!.spot!.touchedBarGroupIndex;
                            _touchedRodIndex =
                                response.spot!.touchedRodDataIndex;
                          });
                        },
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) =>
                              AppColors.card.withValues(alpha: 0.95),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final label = _rodLabels[rodIndex];
                            final value = formatCurrency(rod.toY,
                                currency: widget.currency);
                            return BarTooltipItem(
                              '$label\n$value',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'JetBrainsMono',
                              ),
                            );
                          },
                        ),
                      ),
                      barGroups: List.generate(n, (i) {
                        final isFuture = i >= widget.untilMonth;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: widget.incomes[i],
                              color: isFuture
                                  ? AppColors.income.withValues(alpha: 0.2)
                                  : AppColors.income,
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: widget.outflows[i],
                              color: isFuture
                                  ? AppColors.expense.withValues(alpha: 0.2)
                                  : AppColors.expense,
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                          barsSpace: 4,
                        );
                      }),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= n) {
                                return const SizedBox.shrink();
                              }
                              final isFuture = i >= widget.untilMonth;
                              return Text(
                                formatMonthAbbrev(widget.months[i]),
                                style: TextStyle(
                                  color: isFuture
                                      ? context.kTextSecondary
                                          .withValues(alpha: 0.4)
                                      : context.kTextSecondary,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: context.kCardBorder, strokeWidth: 1),
                        drawVerticalLine: false,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_touchedGroupIndex != null && _touchedRodIndex != null) ...[
          const SizedBox(height: 8),
          _SelectedBarValue(
            month: widget.months[_touchedGroupIndex!],
            label: _rodLabels[_touchedRodIndex!],
            value: [
              widget.incomes,
              widget.outflows,
            ][_touchedRodIndex!][_touchedGroupIndex!],
            color: _rodColors[_touchedRodIndex!],
            currency: widget.currency,
          ),
        ],
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chevron_left, size: 12, color: context.kTextSecondary),
            Text(
              ' arraste para ver todos os meses ',
              style: TextStyle(color: context.kTextSecondary, fontSize: 9),
            ),
            Icon(Icons.chevron_right, size: 12, color: context.kTextSecondary),
          ],
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
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
        ],
      );
}

class _SelectedBarValue extends StatelessWidget {
  final DateTime month;
  final String label;
  final double value;
  final Color color;
  final String currency;

  const _SelectedBarValue({
    required this.month,
    required this.label,
    required this.value,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${formatMonthShort(month)} · $label',
              style: TextStyle(color: context.kTextSecondary, fontSize: 11),
            ),
          ),
          Text(
            formatCurrency(value, currency: currency),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
