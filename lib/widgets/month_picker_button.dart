import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Botão compacto de seleção de mês.
/// Mostra "◁ Mês Ano ▷" e ao toque longo / toque central abre
/// um bottom-sheet para escolha rápida de ano + mês.
class MonthPickerButton extends StatelessWidget {
  final DateTime activeMonth;
  final ValueChanged<DateTime> onChanged;
  final double iconSize;
  final double fontSize;

  const MonthPickerButton({
    super.key,
    required this.activeMonth,
    required this.onChanged,
    this.iconSize = 18,
    this.fontSize = 12,
  });

  void _prevMonth() => onChanged(DateTime(activeMonth.year, activeMonth.month - 1));
  void _nextMonth() => onChanged(DateTime(activeMonth.year, activeMonth.month + 1));

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MonthPickerSheet(current: activeMonth),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.kCardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: _prevMonth,
              icon: Icon(Icons.chevron_left, color: context.kTextSecondary, size: iconSize),
            ),
          ),
          GestureDetector(
            onTap: () => _pickMonth(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                formatMonth(activeMonth),
                style: TextStyle(
                  color: context.kTextPrimary,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: context.kTextSecondary,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: _nextMonth,
              icon: Icon(Icons.chevron_right, color: context.kTextSecondary, size: iconSize),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet interno ──────────────────────────────────────────────────────
class _MonthPickerSheet extends StatefulWidget {
  final DateTime current;
  const _MonthPickerSheet({required this.current});

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;
  late int _month;

  static const _months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril',
    'Maio', 'Junho', 'Julho', 'Agosto',
    'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _year  = widget.current.year;
    _month = widget.current.month; // 1-12
  }

  void _confirm() => Navigator.pop(context, DateTime(_year, _month));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: context.kCardBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          // Seletor de ano
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _year--),
                icon: Icon(Icons.chevron_left, color: context.kTextSecondary),
              ),
              Text(
                _year.toString(),
                style: TextStyle(
                  color: context.kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
              IconButton(
                onPressed: _year < now.year + 1 ? () => setState(() => _year++) : null,
                icon: Icon(Icons.chevron_right, color: context.kTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Grid de meses
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (_, i) {
              final m = i + 1; // 1-12
              final isSelected = m == _month;
              final isCurrent = m == now.month && _year == now.year;

              return GestureDetector(
                onTap: () {
                  setState(() => _month = m);
                  Future.delayed(const Duration(milliseconds: 120), _confirm);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent
                        : isCurrent
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : context.kCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : isCurrent
                              ? AppColors.accent.withValues(alpha: 0.4)
                              : context.kCardBorder,
                      width: isSelected ? 0 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _months[i].substring(0, 3),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isCurrent
                                ? AppColors.accent
                                : context.kTextPrimary,
                        fontSize: 12,
                        fontWeight: isSelected || isCurrent ? FontWeight.bold : FontWeight.normal,
      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
