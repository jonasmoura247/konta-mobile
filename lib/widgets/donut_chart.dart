import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class DonutChart extends StatefulWidget {
  final Map<String, double> data;
  final double total;
  final String currency;

  const DonutChart({super.key, required this.data, required this.total, this.currency = 'BRL'});

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty || widget.total == 0) {
      return const Center(
        child: Text('Sem dados neste mês', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final entries = widget.data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (e, res) => setState(() {
                    _touched = (e.isInterestedForInteractions && res?.touchedSection != null)
                        ? res!.touchedSection!.touchedSectionIndex
                        : -1;
                  }),
                ),
                sections: entries.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = getCategoryById(entry.value.key);
                  final pct = entry.value.value / widget.total * 100;
                  final isTouched = i == _touched;
                  return PieChartSectionData(
                    value: entry.value.value,
                    color: cat.color,
                    radius: isTouched ? 55 : 45,
                    title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.take(6).map((e) {
              final cat = getCategoryById(e.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(cat.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis)),
                    Text(formatCurrency(e.value, currency: widget.currency), style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontFamily: 'JetBrainsMono')),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
