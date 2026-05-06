import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder.dart';
import '../models/category.dart';
import '../models/bank.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _activeMonth = DateTime.now();
  List<TransactionOccurrence> _occurrences = [];
  List<Reminder> _monthReminders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final settings = DatabaseService.getSettings();
    final allReminders = DatabaseService.getAllReminders();
    setState(() {
      _occurrences = FinanceCalculator.getOccurrencesForMonth(
        DatabaseService.getAllTransactions(),
        _activeMonth,
        settings.familyMode ? settings.familyCount : 1,
      );
      _monthReminders = allReminders
          .where((r) => r.date.year == _activeMonth.year && r.date.month == _activeMonth.month)
          .toList();
    });
  }

  Map<int, double> get _dailyTotals {
    final map = <int, double>{};
    for (final o in _occurrences) {
      final day = o.transaction.startDate.day;
      map[day] = (map[day] ?? 0) + o.amount;
    }
    return map;
  }

  Set<int> get _daysWithReminders =>
      _monthReminders.map((r) => r.date.day).toSet();

  void _onDayTap(int dayNum) {
    final day = DateTime(_activeMonth.year, _activeMonth.month, dayNum);
    final reminders = DatabaseService.getRemindersForDay(day);
    _showDayModal(day, reminders);
  }

  void _showDayModal(DateTime day, List<Reminder> reminders) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayModal(
        day: day,
        reminders: reminders,
        // Callbacks fazem apenas a operação de dados; o modal fecha a si mesmo
        onAdd: (r) async {
          await DatabaseService.addReminder(r);
          try {
            final scheduled = DateTime(r.date.year, r.date.month, r.date.day, r.hour, r.minute);
            await NotificationService.scheduleReminder(
              id: NotificationService.idFromUuid(r.id),
              body: r.description,
              scheduledDate: scheduled,
            );
          } catch (_) {}
          _load();
        },
        onDelete: (r) async {
          await DatabaseService.deleteReminder(r);
          try {
            await NotificationService.cancelReminder(NotificationService.idFromUuid(r.id));
          } catch (_) {}
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = firstDayOfMonth(_activeMonth);
    final lastDay = lastDayOfMonth(_activeMonth);
    final startWeekday = firstDay.weekday % 7; // 0=Dom
    final totalCells = startWeekday + lastDay.day;
    final rows = (totalCells / 7).ceil();
    final dailyTotals = _dailyTotals;
    final reminderDays = _daysWithReminders;
    final currency = DatabaseService.getSettings().currency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () { _activeMonth = DateTime(_activeMonth.year, _activeMonth.month - 1); _load(); },
          ),
          Center(child: Text(formatMonth(_activeMonth), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () { _activeMonth = DateTime(_activeMonth.year, _activeMonth.month + 1); _load(); },
          ),
        ],
      ),
      body: Column(
        children: [
          // Dias da semana
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
                  .map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)))))
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          // Grade de dias
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.75),
              itemCount: rows * 7,
              itemBuilder: (ctx, i) {
                final dayNum = i - startWeekday + 1;
                if (dayNum < 1 || dayNum > lastDay.day) return const SizedBox.shrink();
                final amount = dailyTotals[dayNum];
                final hasReminder = reminderDays.contains(dayNum);
                final isToday = DateTime.now().year == _activeMonth.year &&
                    DateTime.now().month == _activeMonth.month &&
                    DateTime.now().day == dayNum;
                return GestureDetector(
                  onTap: () => _onDayTap(dayNum),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.accent.withValues(alpha: 0.15) : (amount != null ? AppColors.expense.withValues(alpha: 0.08) : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isToday ? AppColors.accent : AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$dayNum', style: TextStyle(color: isToday ? AppColors.accent : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        if (amount != null)
                          Text(
                            formatCurrency(amount, currency: currency).replaceAll('R\$ ', '').replaceAll('\$', '').replaceAll('€', ''),
                            style: const TextStyle(color: AppColors.expense, fontSize: 8),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (hasReminder)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modal do dia ─────────────────────────────────────────────────────────────
class _DayModal extends StatefulWidget {
  final DateTime day;
  final List<Reminder> reminders;
  final Future<void> Function(Reminder) onAdd;
  final Future<void> Function(Reminder) onDelete;

  const _DayModal({
    required this.day,
    required this.reminders,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<_DayModal> createState() => _DayModalState();
}

class _DayModalState extends State<_DayModal> {
  bool _adding = false;

  // Campos do novo lembrete
  int _hour = TimeOfDay.now().hour;
  int _minute = TimeOfDay.now().minute;
  final _descCtrl = TextEditingController();
  String? _selectedCat;
  String? _selectedBank;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked != null) setState(() { _hour = picked.hour; _minute = picked.minute; });
  }

  Future<void> _saveReminder() async {
    if (_descCtrl.text.trim().isEmpty) return;
    final r = Reminder(
      id: const Uuid().v4(),
      date: widget.day,
      hour: _hour,
      minute: _minute,
      description: _descCtrl.text.trim(),
      categoryId: _selectedCat,
      bankId: _selectedBank,
    );
    await widget.onAdd(r);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final allCats = getAllCategories();
    final allBanks = getAllBanks();
    final dateLabel = '${widget.day.day}/${widget.day.month}/${widget.day.year}';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.kCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: context.kCardBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateLabel, style: TextStyle(color: context.kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => _adding = !_adding),
                  icon: Icon(_adding ? Icons.close : Icons.add, size: 16),
                  label: Text(_adding ? 'Cancelar' : 'Lembrete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Formulário de novo lembrete
            if (_adding) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.kBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Horário
                    GestureDetector(
                      onTap: _pickTime,
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.accent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono'),
                          ),
                          const SizedBox(width: 6),
                          Text('Toque para alterar', style: TextStyle(color: context.kTextSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Descrição
                    TextField(
                      controller: _descCtrl,
                      style: TextStyle(color: context.kTextPrimary),
                      decoration: InputDecoration(
                        labelText: 'Lembrete (ex: Aluguel vence hoje)',
                        labelStyle: TextStyle(color: context.kTextSecondary, fontSize: 12),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Categoria
                    Text('Categoria', style: TextStyle(color: context.kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(label: 'Nenhuma', selected: _selectedCat == null, onTap: () => setState(() => _selectedCat = null)),
                        ...allCats.take(8).map((c) => _Chip(
                          label: c.name,
                          selected: _selectedCat == c.id,
                          onTap: () => setState(() => _selectedCat = c.id),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Banco
                    Text('Conta / Banco', style: TextStyle(color: context.kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(label: 'Nenhum', selected: _selectedBank == null, onTap: () => setState(() => _selectedBank = null)),
                        ...allBanks.take(6).map((b) => _Chip(
                          label: b.name,
                          selected: _selectedBank == b.id,
                          onTap: () => setState(() => _selectedBank = b.id),
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveReminder,
                        icon: const Icon(Icons.notifications_active, size: 16),
                        label: const Text('Salvar e agendar notificação'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Lista de lembretes existentes
            if (widget.reminders.isEmpty && !_adding) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Nenhum lembrete para este dia.\nToque em "+ Lembrete" para adicionar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.kTextSecondary, fontSize: 13, height: 1.6),
                ),
              ),
            ] else ...[
              if (widget.reminders.isNotEmpty)
                Text('Lembretes', style: TextStyle(color: context.kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...widget.reminders.map((r) {
                final timeLabel = '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.kBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.kCardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_outlined, color: AppColors.accent, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.description, style: TextStyle(color: context.kTextPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                            Text(timeLabel, style: const TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'JetBrainsMono')),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expense),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              backgroundColor: context.kCard,
                              title: Text('Excluir lembrete?', style: TextStyle(color: context.kTextPrimary)),
                              content: Text(r.description, style: TextStyle(color: context.kTextSecondary)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(dialogCtx);
                                    await widget.onDelete(r);
                                    if (mounted) Navigator.of(context).pop();
                                  },
                                  child: const Text('Excluir', style: TextStyle(color: AppColors.expense)),
                                ),
                              ],
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: 0.15) : context.kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.accent : context.kCardBorder, width: selected ? 1.5 : 1),
          ),
          child: Text(
            label,
            style: TextStyle(color: selected ? AppColors.accent : context.kTextPrimary, fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.normal),
          ),
        ),
      );
}
