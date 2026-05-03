import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../services/finance_calculator.dart';

class TransactionCard extends StatelessWidget {
  final TransactionOccurrence occurrence;
  final String currency;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.occurrence,
    this.currency = 'BRL',
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = occurrence.transaction;
    final cat = getCategoryById(t.categoryId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cat.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(cat.icon, color: cat.color, size: 20),
        ),
        title: Text(
          t.description,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            _Badge(label: cat.name, color: cat.color),
            const SizedBox(width: 6),
            _Badge(label: groupLabel(t.groupId), color: AppColors.accent),
            if (t.groupId == 'parcelamento') ...[
              const SizedBox(width: 4),
              Text(
                '${occurrence.installmentIndex}/${occurrence.installmentTotal}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatCurrency(occurrence.amount, currency: currency),
              style: const TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.bold,
                fontFamily: 'JetBrainsMono',
                fontSize: 14,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 18),
              color: AppColors.card,
              onSelected: (v) {
                if (v == 'edit') onEdit?.call();
                if (v == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar', style: TextStyle(color: AppColors.textPrimary))),
                const PopupMenuItem(value: 'delete', child: Text('Excluir', style: TextStyle(color: AppColors.expense))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}
