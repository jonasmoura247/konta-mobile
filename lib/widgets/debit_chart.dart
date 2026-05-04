import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import 'donut_chart.dart';

class DebitChart extends StatelessWidget {
  final Map<String, double> byCategory;
  final double totalDebit;
  final String currency;

  const DebitChart({
    super.key,
    required this.byCategory,
    required this.totalDebit,
    this.currency = 'BRL',
  });

  @override
  Widget build(BuildContext context) {
    if (totalDebit == 0 || byCategory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💳', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'Nenhum débito neste mês',
              style: TextStyle(color: context.kTextSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final segments = byCategory.entries.map((e) {
      final cat = getCategoryById(e.key);
      return DonutSegment(label: cat.name, color: cat.color, value: e.value);
    }).toList();

    return DonutChart(segments: segments, total: totalDebit, currency: currency);
  }
}
