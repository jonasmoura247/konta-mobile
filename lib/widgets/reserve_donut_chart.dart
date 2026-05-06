import 'package:flutter/material.dart';
import '../models/reserve.dart';
import '../theme/app_theme.dart';
import 'donut_chart.dart';

const _typeColors = <String, Color>{
  'poupanca':    AppColors.income,
  'investimento': AppColors.accent,
  'emergencia':  AppColors.warning,
  'outro':       AppColors.textSecondary,
};

const _typeLabels = <String, String>{
  'poupanca':    'Poupança',
  'investimento': 'Investimento',
  'emergencia':  'Emergência',
  'outro':       'Outro',
};

class ReserveDonutChart extends StatelessWidget {
  final List<Reserve> reserves;
  final String currency;

  const ReserveDonutChart({
    super.key,
    required this.reserves,
    this.currency = 'BRL',
  });

  @override
  Widget build(BuildContext context) {
    if (reserves.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏦', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text('Nenhuma reserva cadastrada', style: TextStyle(color: context.kTextSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    final byType = <String, double>{};
    for (final r in reserves) {
      byType[r.type] = (byType[r.type] ?? 0) + r.amount;
    }

    final total = byType.values.fold(0.0, (s, v) => s + v);
    final segments = byType.entries.map((e) => DonutSegment(
      label: _typeLabels[e.key] ?? e.key,
      color: _typeColors[e.key] ?? AppColors.textSecondary,
      value: e.value,
    )).toList();

    return DonutChart(segments: segments, total: total, currency: currency);
  }
}

String reserveTypeLabel(String type) => _typeLabels[type] ?? type;
Color reserveTypeColor(String type) => _typeColors[type] ?? AppColors.textSecondary;
String reserveTypeEmoji(String type) {
  switch (type) {
    case 'poupanca':    return '🏦';
    case 'investimento': return '📈';
    case 'emergencia':  return '🛡️';
    default:            return '💰';
  }
}
