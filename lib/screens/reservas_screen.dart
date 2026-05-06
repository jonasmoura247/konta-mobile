import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/reserve.dart';
import '../models/reserve_snapshot.dart';
import '../models/goal.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/reserve_card.dart';
import '../widgets/reserve_donut_chart.dart';
import '../widgets/reserve_evolution_chart.dart';
import '../widgets/summary_card.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  List<Reserve> _reserves = [];
  List<Goal> _goals = [];
  List<DateTime> _months = [];
  List<double> _evolutionTotals = [];
  int _chartPage = 0;
  final _pageCtrl = PageController();

  static const _chartTitles = ['Por Tipo', 'Evolução 6 meses'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _load() {
    _reserves = DatabaseService.getAllReserves();
    _goals = DatabaseService.getAllGoals();
    _months = FinanceCalculator.lastNMonths(DateTime.now(), 6);
    _evolutionTotals = _months.map(_totalReservedAtEndOfMonth).toList();
    setState(() {});
  }

  double _totalReservedAtEndOfMonth(DateTime month) {
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final snapshots = DatabaseService.getAllSnapshots();
    final latestByReserve = <String, ReserveSnapshot>{};
    for (final snap in snapshots) {
      if (!snap.date.isAfter(endOfMonth)) {
        final existing = latestByReserve[snap.reserveId];
        if (existing == null || snap.date.isAfter(existing.date)) {
          latestByReserve[snap.reserveId] = snap;
        }
      }
    }
    return latestByReserve.values.fold(0.0, (s, snap) => s + snap.amount);
  }

  double get _totalReserved =>
      _reserves.fold(0.0, (s, r) => s + r.amount) +
      _goals.fold(0.0, (s, g) => s + g.savedAmount);

  void _openGoalForm({Goal? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalForm(
        editing: editing,
        onSave: (g) async {
          if (editing != null) {
            await DatabaseService.updateGoal(g);
          } else {
            await DatabaseService.addGoal(g);
          }
          _load();
        },
      ),
    );
  }

  void _openGoalDeposit(Goal g) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GoalDepositSheet(
        goal: g,
        currency: DatabaseService.getSettings().currency,
        onDeposit: (amount) async {
          g.savedAmount += amount;
          await DatabaseService.updateGoal(g);
          _load();
        },
      ),
    );
  }

  void _confirmDeleteGoal(Goal g) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.kCard,
        title: Text('Excluir meta?', style: TextStyle(color: context.kTextPrimary)),
        content: Text(g.name, style: TextStyle(color: context.kTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteGoal(g);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              _load();
            },
            child: const Text('Excluir', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  void _openForm({Reserve? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReserveForm(
        editing: editing,
        onSave: (r) async {
          if (editing != null) {
            await DatabaseService.updateReserve(r);
          } else {
            await DatabaseService.addReserve(r);
          }
          _load();
        },
      ),
    );
  }

  void _confirmDelete(Reserve r) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.kCard,
        title: Text('Excluir reserva?', style: TextStyle(color: context.kTextPrimary)),
        content: Text(r.description, style: TextStyle(color: context.kTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteReserve(r);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              _load();
            },
            child: const Text('Excluir', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = DatabaseService.getSettings();
    final currency = settings.currency;

    return Scaffold(
      appBar: AppBar(title: const Text('Reservas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // ── Card total reservado ──────────────────────────────────────────
          SummaryCard(
            label: 'Total Reservado',
            value: _totalReserved,
            color: AppColors.income,
            icon: Icons.savings,
            currency: currency,
          ),
          // ── Seção de Metas ────────────────────────────────────────────────
          if (settings.goalsEnabled) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Metas', style: TextStyle(color: context.kTextPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _openGoalForm(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Adicionar meta'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.accent, padding: EdgeInsets.zero),
                ),
              ],
            ),
            if (_goals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Nenhuma meta ainda. Toque em "Adicionar meta".', style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
              )
            else
              ..._goals.map((g) => _GoalCard(
                goal: g,
                currency: currency,
                onEdit: () => _openGoalForm(editing: g),
                onDelete: () => _confirmDeleteGoal(g),
                onAddAmount: () => _openGoalDeposit(g),
              )),
          ],
          const SizedBox(height: 20),

          // ── Carrossel de gráficos ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _chartTitles[_chartPage],
                style: TextStyle(color: context.kTextPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Row(
                children: List.generate(2, (i) => GestureDetector(
                  onTap: () => _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(left: 6),
                    width: _chartPage == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _chartPage == i ? AppColors.accent : context.kCardBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 192,
            decoration: BoxDecoration(
              color: context.kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.kCardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _chartPage = i),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ReserveDonutChart(reserves: _reserves, currency: currency),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ReserveEvolutionChart(months: _months, totals: _evolutionTotals, currency: currency),
                  ),
                ],
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

          const SizedBox(height: 20),

          // ── Lista de reservas ─────────────────────────────────────────────
          Text('Minhas Reservas', style: TextStyle(color: context.kTextPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          if (_reserves.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Text('🏦', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma reserva ainda\nToque em + para adicionar',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.kTextSecondary, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_reserves.map((r) => ReserveCard(
              reserve: r,
              currency: currency,
              onEdit: () => _openForm(editing: r),
              onDelete: () => _confirmDelete(r),
            ))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Formulário de Reserva ────────────────────────────────────────────────────
class _ReserveForm extends StatefulWidget {
  final Reserve? editing;
  final void Function(Reserve) onSave;

  const _ReserveForm({this.editing, required this.onSave});

  @override
  State<_ReserveForm> createState() => _ReserveFormState();
}

class _ReserveFormState extends State<_ReserveForm> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  String _type = 'poupanca';
  DateTime _date = DateTime.now();

  static const _types = [
    ('poupanca',    'Poupança',    '🏦'),
    ('investimento','Investimento','📈'),
    ('emergencia',  'Emergência',  '🛡️'),
    ('outro',       'Outro',       '💰'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _descCtrl.text = e.description;
      _amountCtrl.text = e.amount.toStringAsFixed(2).replaceAll('.', ',');
      _type = e.type;
      _date = e.date;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final rawAmount = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(rawAmount) ?? 0;

    final r = Reserve(
      id: widget.editing?.id ?? const Uuid().v4(),
      description: _descCtrl.text.trim(),
      amount: amount,
      date: _date,
      type: _type,
    );
    widget.onSave(r);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.kCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
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
              Text(
                widget.editing == null ? 'Nova Reserva' : 'Editar Reserva',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.kTextPrimary),
              ),
              const SizedBox(height: 20),

              // Descrição
              TextFormField(
                controller: _descCtrl,
                style: TextStyle(color: context.kTextPrimary),
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // Valor
              TextFormField(
                controller: _amountCtrl,
                style: TextStyle(color: context.kTextPrimary, fontFamily: 'JetBrainsMono'),
                decoration: const InputDecoration(labelText: 'Valor guardado (R\$)', prefixText: 'R\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo
              Text('Tipo', style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((t) {
                  final (id, label, emoji) = t;
                  final selected = _type == id;
                  final color = reserveTypeColor(id);
                  return GestureDetector(
                    onTap: () => setState(() => _type = id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? color.withValues(alpha: 0.15) : context.kCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? color : context.kCardBorder,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        '$emoji $label',
                        style: TextStyle(
                          color: selected ? color : context.kTextPrimary,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Data
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Data do registro', style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
                subtitle: Text(formatDate(_date), style: TextStyle(color: context.kTextPrimary)),
                trailing: const Icon(Icons.calendar_today, color: AppColors.accent, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                child: const Text('Salvar'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card de Meta ─────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final Goal goal;
  final String currency;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onAddAmount;

  const _GoalCard({
    required this.goal,
    required this.currency,
    required this.onDelete,
    required this.onEdit,
    required this.onAddAmount,
  });

  @override
  Widget build(BuildContext context) {
    final saved = goal.savedAmount;
    final progress = goal.targetAmount > 0
        ? (saved / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);
    final reached = saved >= goal.targetAmount;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reached ? AppColors.income : AppColors.accent,
          width: reached ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(reached ? Icons.emoji_events : Icons.flag_outlined,
                  color: reached ? AppColors.income : AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.name,
                  style: TextStyle(color: context.kTextPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  color: reached ? AppColors.income : AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onEdit,
                child: Icon(Icons.edit_outlined, size: 16, color: context.kTextSecondary),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline, size: 16, color: AppColors.expense),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.kCardBorder,
              color: reached ? AppColors.income : AppColors.accent,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatCurrency(saved, currency: currency),
                style: TextStyle(color: context.kTextSecondary, fontSize: 11, fontFamily: 'JetBrainsMono'),
              ),
              Text(
                'Meta: ${formatCurrency(goal.targetAmount, currency: currency)}',
                style: TextStyle(color: context.kTextSecondary, fontSize: 11, fontFamily: 'JetBrainsMono'),
              ),
            ],
          ),
          if (reached) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.income.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Parabéns, você atingiu sua meta!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.income, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddAmount,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Adicionar valor', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sheet de depósito em meta ────────────────────────────────────────────────
class _GoalDepositSheet extends StatefulWidget {
  final Goal goal;
  final String currency;
  final void Function(double amount) onDeposit;

  const _GoalDepositSheet({
    required this.goal,
    required this.currency,
    required this.onDeposit,
  });

  @override
  State<_GoalDepositSheet> createState() => _GoalDepositSheetState();
}

class _GoalDepositSheetState extends State<_GoalDepositSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final raw = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(raw) ?? 0;
    widget.onDeposit(amount);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (widget.goal.targetAmount - widget.goal.savedAmount).clamp(0.0, double.infinity);

    return Container(
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: context.kCardBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Adicionar à meta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.kTextPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                widget.goal.name,
                style: TextStyle(color: AppColors.accent, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Faltam ${formatCurrency(remaining, currency: widget.currency)} para atingir a meta',
                style: TextStyle(color: context.kTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
                autofocus: true,
                style: TextStyle(color: context.kTextPrimary, fontFamily: 'JetBrainsMono'),
                decoration: const InputDecoration(labelText: 'Valor a adicionar (R\$)', prefixText: 'R\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

// ── Formulário de Meta ────────────────────────────────────────────────────────
class _GoalForm extends StatefulWidget {
  final Goal? editing;
  final void Function(Goal) onSave;

  const _GoalForm({this.editing, required this.onSave});

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _targetCtrl.text = e.targetAmount.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final raw = _targetCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final target = double.tryParse(raw) ?? 0;
    final g = Goal(
      id: widget.editing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      targetAmount: target,
      savedAmount: widget.editing?.savedAmount ?? 0.0,
    );
    widget.onSave(g);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.kCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
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
              Text(
                widget.editing == null ? 'Nova Meta' : 'Editar Meta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.kTextPrimary),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(color: context.kTextPrimary),
                decoration: const InputDecoration(labelText: 'Nome da meta (ex: Comprar um carro)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetCtrl,
                style: TextStyle(color: context.kTextPrimary, fontFamily: 'JetBrainsMono'),
                decoration: const InputDecoration(labelText: 'Valor alvo (R\$)', prefixText: 'R\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
