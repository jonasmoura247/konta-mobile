import 'package:flutter/material.dart';
import '../models/reserve.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/reserve_donut_chart.dart';

class ReserveCard extends StatelessWidget {
  final Reserve reserve;
  final String currency;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReserveCard({
    super.key,
    required this.reserve,
    this.currency = 'BRL',
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = reserveTypeColor(reserve.type);
    final emoji = reserveTypeEmoji(reserve.type);
    final label = reserveTypeLabel(reserve.type);

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),

            // Descrição + tipo + data
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reserve.description,
                    style: TextStyle(
                      color: context.kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatDate(reserve.date),
                        style: TextStyle(color: context.kTextSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Valor + menu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(reserve.amount, currency: currency),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(Icons.more_vert, color: context.kTextSecondary, size: 18),
                  color: context.kCard,
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text('Editar', style: TextStyle(color: context.kTextPrimary))),
                    const PopupMenuItem(value: 'delete', child: Text('Excluir', style: TextStyle(color: AppColors.expense))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
