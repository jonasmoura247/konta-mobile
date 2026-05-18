import 'package:flutter/material.dart';
import '../models/card_due_date.dart';
import '../models/bank.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class CardDueDatesScreen extends StatefulWidget {
  const CardDueDatesScreen({super.key});

  @override
  State<CardDueDatesScreen> createState() => _CardDueDatesScreenState();
}

class _CardDueDatesScreenState extends State<CardDueDatesScreen> {
  late List<BankDef> _banks;
  late Map<String, CardDueDate> _dueDates;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _banks = getVisibleBanks();
    _dueDates = {
      for (final cdd in DatabaseService.getAllCardDueDates()) cdd.bankId: cdd
    };
  }

  void _openEdit(BankDef bank) {
    final existing = _dueDates[bank.id];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CardDueDateForm(
        bank: bank,
        current: existing,
        onSave: (cdd) async {
          await DatabaseService.saveCardDueDate(cdd);
          setState(_load);
        },
        onDelete: existing != null
            ? () async {
                await DatabaseService.deleteCardDueDate(bank.id);
                setState(_load);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kBg,
      appBar: AppBar(
        title: const Text('Vencimento de Cartões'),
        backgroundColor: context.kCard,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _banks.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: context.kCardBorder),
        itemBuilder: (ctx, i) {
          final bank = _banks[i];
          final cdd = _dueDates[bank.id];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: bank.color.withValues(alpha: 0.2),
              child: Text(
                bank.name[0],
                style: TextStyle(color: bank.color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(bank.name, style: TextStyle(color: context.kTextPrimary, fontWeight: FontWeight.w600)),
            subtitle: cdd != null
                ? Text(
                    'Fecha dia ${cdd.closureDay}  •  Paga dia ${cdd.paymentDay}',
                    style: TextStyle(color: context.kTextSecondary, fontSize: 12),
                  )
                : Text(
                    'Sem vencimento configurado',
                    style: TextStyle(color: context.kTextSecondary, fontSize: 12),
                  ),
            trailing: Icon(
              cdd != null ? Icons.edit_outlined : Icons.add_circle_outline,
              color: cdd != null ? AppColors.accent : context.kTextSecondary,
            ),
            onTap: () => _openEdit(bank),
          );
        },
      ),
    );
  }
}

class _CardDueDateForm extends StatefulWidget {
  final BankDef bank;
  final CardDueDate? current;
  final Future<void> Function(CardDueDate) onSave;
  final VoidCallback? onDelete;

  const _CardDueDateForm({
    required this.bank,
    this.current,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_CardDueDateForm> createState() => _CardDueDateFormState();
}

class _CardDueDateFormState extends State<_CardDueDateForm> {
  late int _closureDay;
  late int _paymentDay;

  @override
  void initState() {
    super.initState();
    _closureDay = widget.current?.closureDay ?? 1;
    _paymentDay = widget.current?.paymentDay ?? 10;
  }

  Future<void> _submit() async {
    final cdd = CardDueDate(
      bankId: widget.bank.id,
      closureDay: _closureDay,
      paymentDay: _paymentDay,
      overrideClosure: widget.current?.overrideClosure,
      overridePayment: widget.current?.overridePayment,
    );
    await widget.onSave(cdd);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.8,
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
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.kCardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cabeçalho
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: widget.bank.color.withValues(alpha: 0.2),
                      child: Text(
                        widget.bank.name[0],
                        style: TextStyle(color: widget.bank.color, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.bank.name,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.kTextPrimary),
                    ),
                  ],
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                    onPressed: () {
                      widget.onDelete!();
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Dia de Fechamento
            Text('Dia de Fechamento da Fatura', style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _DaySelector(
              value: _closureDay,
              onChanged: (v) => setState(() => _closureDay = v),
              label: 'Fecha todo dia',
            ),
            const SizedBox(height: 16),

            // Dia de Pagamento
            Text('Dia de Pagamento da Fatura', style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _DaySelector(
              value: _paymentDay,
              onChanged: (v) => setState(() => _paymentDay = v),
              label: 'Paga todo dia',
            ),
            const SizedBox(height: 8),
            Text(
              'Se o mês não tiver o dia configurado, o sistema usa o último dia do mês automaticamente.',
              style: TextStyle(color: context.kTextSecondary, fontSize: 11),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Salvar'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final String label;

  const _DaySelector({required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: context.kTextPrimary)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          color: AppColors.accent,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.kTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < 31 ? () => onChanged(value + 1) : null,
          color: AppColors.accent,
        ),
      ],
    );
  }
}
