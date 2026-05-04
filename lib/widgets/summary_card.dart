import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final String currency;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.currency = 'BRL',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label, style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
              ),
              if (onTap != null)
                GestureDetector(
                  onTap: onTap,
                  child: Icon(Icons.add_circle_outline, color: color, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(value, currency: currency),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}
