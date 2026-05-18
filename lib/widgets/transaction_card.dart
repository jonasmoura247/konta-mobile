import 'package:flutter/material.dart';
import '../models/bank.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../services/finance_calculator.dart';

class TransactionCard extends StatelessWidget {
  final TransactionOccurrence occurrence;
  final String currency;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Widget? dragHandle;

  const TransactionCard({
    super.key,
    required this.occurrence,
    this.currency = 'BRL',
    this.onEdit,
    this.onDelete,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final t = occurrence.transaction;
    final cat = getCategoryById(t.categoryId);

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.kCardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícone da categoria
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
            const SizedBox(width: 12),

            // Descrição + badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.description,
                    style: TextStyle(
                      color: context.kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDate(occurrence.billingDate),
                    style: TextStyle(
                      color: context.kTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _Badge(label: cat.name, color: cat.color),
                      // Group badge — só para cartão (não para pix/dinheiro)
                      if (t.paymentSubtype != 'pix' &&
                          t.paymentSubtype != 'dinheiro')
                        _Badge(
                            label: groupLabel(t.groupId),
                            color: AppColors.accent),
                      if (t.groupId == 'parcelamento')
                        _Badge(
                          label:
                              '${occurrence.installmentIndex}/${occurrence.installmentTotal}',
                          color: context.kTextSecondary,
                        ),
                      if (t.bankId != null)
                        _Badge(
                            label: getBankById(t.bankId)?.name ?? t.bankId!,
                            color: getBankById(t.bankId)?.color ?? AppColors.neonCyan),
                      if (t.familyMode)
                        _Badge(
                          label: t.familyMember != null &&
                                  t.familyMember!.isNotEmpty
                              ? '👨‍👩‍👧 ${t.familyMember}'
                              : '👨‍👩‍👧 Família',
                          color: AppColors.warning,
                        ),
                      // Pix badge
                      if (t.paymentSubtype == 'pix')
                        _Badge(label: 'Pix', color: AppColors.pixBlue),
                      // Dinheiro badge
                      if (t.paymentSubtype == 'dinheiro')
                        _Badge(label: 'Dinheiro', color: AppColors.income),
                      // Crédito badge — só para Pix feito no cartão de crédito
                      if (t.paymentSubtype == 'pix' && t.groupId != 'debito')
                        _Badge(label: 'Crédito', color: AppColors.accent),
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
                  formatCurrency(occurrence.amount, currency: currency),
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: Icon(Icons.more_vert,
                          color: context.kTextSecondary, size: 18),
                      color: context.kCard,
                      onSelected: (v) {
                        Future<void>.delayed(const Duration(milliseconds: 180), () {
                          if (v == 'edit') onEdit?.call();
                          if (v == 'delete') onDelete?.call();
                        });
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar',
                                style: TextStyle(color: context.kTextPrimary))),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text('Excluir',
                                style: TextStyle(color: AppColors.expense))),
                      ],
                    ),
                    if (dragHandle != null) dragHandle!,
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
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      );
}

