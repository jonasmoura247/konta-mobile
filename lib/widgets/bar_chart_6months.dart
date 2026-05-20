import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class BarChart6Months extends StatefulWidget {
  final List<DateTime> months;
  final List<double> expenses;
  final List<double> incomes;
  final List<double> debits;
  final String currency;

  const BarChart6Months({
    super.key,
    required this.months,
    required this.expenses,
    required this.incomes,
    required this.debits,
    this.currency = 'BRL',
  });

  @override
  State<BarChart6Months> createState() => _BarChart6MonthsState();
}

class _BarChart6MonthsState extends State<BarChart6Months> {
  late final ScrollController _scrollCtrl;
  int? _touchedGroupIndex;
  int? _touchedRodIndex;

  static const _rodLabels = ['Cartão', 'Entradas', 'Débito'];
  static const _rodColors = [
    AppColors.expense,
    AppColors.income,
    AppColors.neonCyan,
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final n = widget.months.length;
      if (n <= 6) return;
      final maxScroll = _scrollCtrl.position.maxScrollExtent;
      final currentMonthIndex = DateTime.now().month - 1;
      final offset = (currentMonthIndex * maxScroll / (n - 6)).clamp(0.0, maxScroll);
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
    final maxVal = [
      ...widget.expenses,
      ...widget.incomes,
      ...widget.debits,
    ].fold(0.0, (a, b) => a > b ? a : b);

    final gridColor = context.kCardBorder;
    final n = widget.months.length;
    final currency = widget.currency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            _LegendDot(color: AppColors.expense, label: 'Cartão'),
            SizedBox(width: 16),
            _LegendDot(color: AppColors.income, label: 'Entradas'),
            SizedBox(width: 16),
            _LegendDot(color: AppColors.neonCyan, label: 'Débito'),
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
                            final value =
                                formatCurrency(rod.toY, currency: currency);
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
                      barGroups: List.generate(
                          n,
                          (i) => BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: widget.expenses[i],
                                    color: AppColors.expense,
                                    width: 12,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                  BarChartRodData(
                                    toY: widget.incomes[i],
                                    color: AppColors.income,
                                    width: 12,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                  BarChartRodData(
                                    toY: widget.debits[i],
                                    color: AppColors.neonCyan,
                                    width: 12,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ],
                                barsSpace: 4,
                              )),
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
                              return Text(
                                formatMonthAbbrev(widget.months[i]),
                                style: TextStyle(
                                    color: context.kTextSecondary,
                                    fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: gridColor, strokeWidth: 1),
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
              widget.expenses,
              widget.incomes,
              widget.debits,
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
            Text(' Arraste para ver todos os meses ',
                style: TextStyle(color: context.kTextSecondary, fontSize: 9)),
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
                  color: color, borderRadius: BorderRadius.circular(2))),
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
