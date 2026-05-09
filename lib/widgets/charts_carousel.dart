import 'package:flutter/material.dart';
import '../models/bank.dart';
import '../models/category.dart';
import '../services/finance_calculator.dart';
import '../theme/app_theme.dart';
import 'donut_chart.dart';

class ChartsCarousel extends StatefulWidget {
  final MonthSummary summary;
  final String currency;

  const ChartsCarousel({super.key, required this.summary, this.currency = 'BRL'});

  @override
  State<ChartsCarousel> createState() => _ChartsCarouselState();
}

class _ChartsCarouselState extends State<ChartsCarousel> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _titles = ['Gastos por Categoria', 'Gastos por Cartão', 'Gastos por Tipo', 'Total por Cartão'];

  static const _groupColors = <String, Color>{
    'avista': AppColors.neonCyan,
    'parcelamento': AppColors.warning,
    'assinatura': AppColors.accent,
  };
  static const _groupLabels = <String, String>{
    'avista': 'À Vista',
    'parcelamento': 'Parcelado',
    'assinatura': 'Assinatura',
  };


  List<DonutSegment> _categorySegments() => widget.summary.byCategory.entries.map((e) {
        final cat = getCategoryById(e.key);
        return DonutSegment(label: cat.name, color: cat.color, value: e.value);
      }).toList();

  List<DonutSegment> _groupSegments() => widget.summary.byGroup.entries.map((e) => DonutSegment(
        label: _groupLabels[e.key] ?? e.key,
        color: _groupColors[e.key] ?? AppColors.textSecondary,
        value: e.value,
      )).toList();

  List<DonutSegment> _bankSegments() => widget.summary.byBank.entries.map((e) {
        if (e.key == 'sem_banco') return DonutSegment(label: 'Sem banco', color: AppColors.textSecondary, value: e.value);
        final bank = getBankById(e.key);
        return DonutSegment(
          label: bank?.name ?? e.key,
          color: bank?.color ?? AppColors.textSecondary,
          value: e.value,
        );
      }).toList();

  List<DonutSegment> _bankGrossSegments() => widget.summary.byBankGross.entries.map((e) {
        if (e.key == 'sem_banco') return DonutSegment(label: 'Sem banco', color: AppColors.textSecondary, value: e.value);
        final bank = getBankById(e.key);
        return DonutSegment(
          label: bank?.name ?? e.key,
          color: bank?.color ?? AppColors.textSecondary,
          value: e.value,
        );
      }).toList();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.summary.totalExpenses;
    final grossTotal = widget.summary.byBankGross.values.fold(0.0, (s, v) => s + v);
    final charts = [
      DonutChart(segments: _categorySegments(), total: total, currency: widget.currency),
      DonutChart(segments: _bankSegments(), total: total, currency: widget.currency),
      DonutChart(segments: _groupSegments(), total: total, currency: widget.currency),
      DonutChart(segments: _bankGrossSegments(), total: grossTotal, currency: widget.currency),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _titles[_page],
              style: TextStyle(color: context.kTextPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Row(
              children: List.generate(4, (i) => GestureDetector(
                onTap: () => _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(left: 6),
                  width: _page == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.accent : context.kCardBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: context.kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.kCardBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _page = i),
              children: charts.map((c) => Padding(padding: const EdgeInsets.all(16), child: c)).toList(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chevron_left, size: 14, color: context.kTextSecondary),
            Text(' deslize para ver mais ', style: TextStyle(color: context.kTextSecondary, fontSize: 10)),
            Icon(Icons.chevron_right, size: 14, color: context.kTextSecondary),
          ],
        ),
      ],
    );
  }
}
