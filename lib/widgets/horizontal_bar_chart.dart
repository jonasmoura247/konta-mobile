import 'package:flutter/material.dart';
import '../services/insights_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class HorizontalBarChart extends StatefulWidget {
  final List<CategoryBar> bars;
  final String currency;
  final bool animate;

  const HorizontalBarChart({
    super.key,
    required this.bars,
    this.currency = 'BRL',
    this.animate = true,
  });

  @override
  State<HorizontalBarChart> createState() => _HorizontalBarChartState();
}

class _HorizontalBarChartState extends State<HorizontalBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(HorizontalBarChart old) {
    super.didUpdateWidget(old);
    if (old.bars != widget.bars) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bars.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Sem dados de categorias',
          style: TextStyle(fontSize: 13, color: context.kTextSecondary),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Column(
          children: widget.bars.map((bar) {
            final isMax = bar.fraction == 1.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Text(
                      bar.categoryName,
                      style: TextStyle(fontSize: 12, color: context.kTextSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final barWidth = bar.fraction * constraints.maxWidth * _animation.value;
                        return Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: bar.color.withValues(
                                    alpha: context.isDark ? 0.12 : 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Container(
                              height: 6,
                              width: barWidth,
                              decoration: BoxDecoration(
                                color: bar.color.withValues(alpha: isMax ? 1.0 : 0.85),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatCurrency(bar.amount, currency: widget.currency),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.kTextSecondary,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
