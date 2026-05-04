import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class DonutSegment {
  final String label;
  final Color color;
  final double value;
  const DonutSegment({required this.label, required this.color, required this.value});
}

class DonutChart extends StatefulWidget {
  final List<DonutSegment> segments;
  final double total;
  final String currency;

  const DonutChart({super.key, required this.segments, required this.total, this.currency = 'BRL'});

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.segments.isEmpty || widget.total == 0) {
      return Center(
        child: Text('Sem dados neste mês', style: TextStyle(color: context.kTextSecondary)),
      );
    }

    final sorted = [...widget.segments]..sort((a, b) => b.value.compareTo(a.value));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => setState(() => _touched = -1),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, PieTouchResponse? res) {
                      if (event is FlTapUpEvent) {
                        final index = res?.touchedSection?.touchedSectionIndex ?? -1;
                        setState(() {
                          _touched = (_touched == index || index == -1) ? -1 : index;
                        });
                      }
                    },
                  ),
                  sections: sorted.asMap().entries.map((entry) {
                    final i = entry.key;
                    final seg = entry.value;
                    final pct = seg.value / widget.total * 100;
                    final isTouched = i == _touched;
                    return PieChartSectionData(
                      value: seg.value,
                      color: seg.color,
                      radius: isTouched ? 55 : 45,
                      title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                  centerSpaceRadius: 36,
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
              children: sorted.take(6).map((seg) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: seg.color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(seg.label, style: TextStyle(color: context.kTextSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        formatCurrency(seg.value, currency: widget.currency),
                        style: TextStyle(color: context.kTextPrimary, fontSize: 10, fontFamily: 'JetBrainsMono'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
