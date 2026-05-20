import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/bank.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/text_formatters.dart';
import '../utils/keyboard_restore_mixin.dart';

enum SubscriptionEditScope { fromStart, fromMonth }

class TransactionFormResult {
  final Transaction transaction;
  final SubscriptionEditScope subscriptionEditScope;

  const TransactionFormResult({
    required this.transaction,
    this.subscriptionEditScope = SubscriptionEditScope.fromStart,
  });
}

enum PaymentMode { cartao, pix, dinheiro }

// Rascunho persistente — sobrevive entre aberturas do formulário no mesmo processo
class _FormDraft {
  final PaymentMode mode;
  final String groupId;
  final String description;
  final String amount;
  final String installments;
  final DateTime date;
  final String? bankId;
  final String categoryId;
  final bool familyMode;
  final DateTime? invoiceMonth;

  const _FormDraft({
    required this.mode,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.installments,
    required this.date,
    this.bankId,
    required this.categoryId,
    required this.familyMode,
    this.invoiceMonth,
  });
}

class AddTransactionForm extends StatefulWidget {
  final Transaction? editing;
  final FutureOr<void> Function(Transaction) onSave;
  final bool isDebit;
  final PaymentMode? initialMode;
  final String? initialGroupId;
  final DateTime? initialDate;
  final bool returnTransaction;
  final DateTime? subscriptionEditMonth;

  const AddTransactionForm({
    super.key,
    this.editing,
    required this.onSave,
    this.isDebit = false,
    this.initialMode,
    this.initialGroupId,
    this.initialDate,
    this.returnTransaction = false,
    this.subscriptionEditMonth,
  });

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm>
    with WidgetsBindingObserver, KeyboardRestoreMixin {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _installCtrl = TextEditingController(text: '1');
  final _descFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _installFocus = FocusNode();

  // Rascunho estático — persiste entre aberturas do formulário
  static _FormDraft? _draft;
  bool _draftRestored = false;

  PaymentMode _mode = PaymentMode.cartao;
  String _groupId = 'avista'; // usado apenas quando _mode == cartao
  String _categoryId = 'outros';
  String? _bankId;
  DateTime _date = DateTime.now();
  bool _familyMode = false;
  DateTime? _invoiceMonth;
  SubscriptionEditScope _subscriptionEditScope = SubscriptionEditScope.fromMonth;

  // ── Derivados ──────────────────────────────────────────────────────────────
  bool get _isCartao => _mode == PaymentMode.cartao;
  bool get _isCartaoCredit => _isCartao && _groupId != 'debito';
  bool get _hasBank => _mode != PaymentMode.dinheiro;
  bool get _showFatura => _isCartaoCredit && _groupId != 'assinatura';

  Color get _modeColor => switch (_mode) {
        PaymentMode.cartao => AppColors.accent,
        PaymentMode.pix => AppColors.pixBlue,
        PaymentMode.dinheiro => AppColors.income,
      };

  @override
  void initState() {
    super.initState(); // KeyboardRestoreMixin.initState registra o observer
    final e = widget.editing;
    if (e != null) {
      _descCtrl.text = e.description;
      _amountCtrl.text =
          e.totalAmount.toStringAsFixed(2).replaceAll('.', ',');
      _installCtrl.text = e.installments.toString();
      _categoryId = e.categoryId;
      _bankId = e.bankId;
      _date = e.startDate;
      _familyMode = e.familyMode;
      _invoiceMonth = e.invoiceMonth;
      _initModeFromEditing(e);
    } else {
      _mode = widget.initialMode ??
          (widget.isDebit ? PaymentMode.pix : PaymentMode.cartao);
      _groupId = widget.initialGroupId ?? 'avista';
      _date = widget.initialDate ?? DateTime.now();
      _categoryId = DatabaseService.getCategoryDefault() ?? 'outros';
      // Restaura rascunho se houver dados não salvos
      final draft = _draft;
      if (draft != null) {
        _mode = draft.mode;
        _groupId = draft.groupId;
        _descCtrl.text = draft.description;
        _amountCtrl.text = draft.amount;
        _installCtrl.text = draft.installments;
        _date = draft.date;
        _bankId = draft.bankId;
        _categoryId = draft.categoryId;
        _familyMode = draft.familyMode;
        _invoiceMonth = draft.invoiceMonth;
        _draftRestored = true;
      }
    }
    // Registra focus nodes para restauração do teclado (KeyboardRestoreMixin)
    registerFocusNode(_descFocus);
    registerFocusNode(_amountFocus);
    registerFocusNode(_installFocus);
    // Salva rascunho em mudanças de texto que não passam por setState
    _descCtrl.addListener(_saveDraftIfNew);
  }

  void _saveDraftIfNew() {
    if (widget.editing == null && mounted) _saveDraft();
  }

  void _saveDraft() {
    _draft = _FormDraft(
      mode: _mode,
      groupId: _groupId,
      description: _descCtrl.text,
      amount: _amountCtrl.text,
      installments: _installCtrl.text,
      date: _date,
      bankId: _bankId,
      categoryId: _categoryId,
      familyMode: _familyMode,
      invoiceMonth: _invoiceMonth,
    );
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (widget.editing == null && mounted) _saveDraft();
  }

  void _initModeFromEditing(Transaction e) {
    if (e.paymentSubtype == 'pix' && e.groupId == 'debito') {
      _mode = PaymentMode.pix;
      _groupId = 'avista';
    } else if (e.paymentSubtype == 'pix') {
      _mode = PaymentMode.cartao;
      _groupId = 'pix';
    } else if (e.paymentSubtype == 'dinheiro') {
      _mode = PaymentMode.dinheiro;
      _groupId = 'avista';
    } else if (e.groupId == 'debito') {
      _mode = PaymentMode.cartao;
      _groupId = 'debito';
    } else {
      _mode = PaymentMode.cartao;
      _groupId = e.groupId; // avista, parcelamento, assinatura
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _installCtrl.dispose();
    _descFocus.dispose();
    _amountFocus.dispose();
    _installFocus.dispose();
    super.dispose(); // KeyboardRestoreMixin.dispose remove o observer
  }

  (String effectiveGroupId, String? effectiveSubtype) _computeGroupAndSubtype() {
    return switch (_mode) {
      PaymentMode.pix => ('debito', 'pix'),
      PaymentMode.dinheiro => ('debito', 'dinheiro'),
      PaymentMode.cartao => switch (_groupId) {
          'debito' => ('debito', 'debito_direto'),
          'pix'    => ('avista', 'pix'),
          _        => (_groupId, null),
        },
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final rawAmount = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(rawAmount) ?? 0;
    final id = widget.editing?.id ?? const Uuid().v4();

    final (effectiveGroupId, effectiveSubtype) = _computeGroupAndSubtype();
    final effectiveBankId = _hasBank ? _bankId : null;

    final applyClosureDateVal = _isCartaoCredit
        ? (widget.editing?.applyClosureDate ?? true)
        : false;

    final t = Transaction(
      id: id,
      groupId: effectiveGroupId,
      categoryId: _categoryId,
      description: _descCtrl.text.trim(),
      totalAmount: amount,
      installments: (effectiveGroupId == 'parcelamento')
          ? (int.tryParse(_installCtrl.text) ?? 1)
          : 1,
      startDate: (effectiveGroupId == 'assinatura' && widget.editing != null)
          ? widget.editing!.startDate
          : _date,
      isSubscription: effectiveGroupId == 'assinatura',
      bankId: effectiveBankId,
      familyMode: _familyMode,
      cancelledFrom: effectiveGroupId == 'assinatura'
          ? widget.editing?.cancelledFrom
          : null,
      createdAt: widget.editing?.createdAt ?? DateTime.now(),
      subscriptionSeriesId: effectiveGroupId == 'assinatura'
          ? (widget.editing?.subscriptionSeriesId ?? id)
          : null,
      paymentSubtype: effectiveSubtype,
      applyClosureDate: applyClosureDateVal,
      invoiceMonth: _showFatura ? _invoiceMonth : null,
    );

    // Rascunho cumprido — limpa
    _draft = null;

    final navigator = Navigator.of(context);
    if (widget.returnTransaction) {
      navigator.pop(TransactionFormResult(
        transaction: t,
        subscriptionEditScope: _subscriptionEditScope,
      ));
      return;
    }
    await widget.onSave(t);
    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final rawAmount = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final totalAmt = double.tryParse(rawAmount) ?? 0;
    final installCount = int.tryParse(_installCtrl.text) ?? 1;
    final parcAmt =
        (installCount > 0 && totalAmt > 0) ? totalAmt / installCount : 0.0;
    String endMonthLabel = '';
    if (_groupId == 'parcelamento' && installCount > 1) {
      final endDate = DateTime(_date.year, _date.month + installCount - 1);
      endMonthLabel = formatMonth(endDate);
    }

    final bool showSubscriptionScope = _isCartao &&
        _groupId == 'assinatura' &&
        widget.editing != null &&
        widget.subscriptionEditMonth != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              // ── Drag handle ──────────────────────────────────────────────
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
              const SizedBox(height: 14),

              // ── Título ───────────────────────────────────────────────────
              Text(
                widget.editing == null
                    ? 'Novo Lançamento'
                    : 'Editar Lançamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // ── Banner de rascunho restaurado ────────────────────────────
              if (_draftRestored) ...[
                _DraftBanner(
                  onDismiss: () => setState(() => _draftRestored = false),
                  onClear: () => setState(() {
                    _draft = null;
                    _draftRestored = false;
                    _descCtrl.clear();
                    _amountCtrl.clear();
                    _installCtrl.text = '1';
                    _mode = widget.initialMode ??
                        (widget.isDebit ? PaymentMode.pix : PaymentMode.cartao);
                    _groupId = widget.initialGroupId ?? 'avista';
                    _date = widget.initialDate ?? DateTime.now();
                    _bankId = null;
                    _categoryId =
                        DatabaseService.getCategoryDefault() ?? 'outros';
                    _familyMode = false;
                    _invoiceMonth = null;
                  }),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),

              // ── 1. Forma de pagamento ────────────────────────────────────
              Row(
                children: [
                  _ModeChip(
                    icon: Icons.credit_card_rounded,
                    label: 'Cartão',
                    selected: _mode == PaymentMode.cartao,
                    activeColor: AppColors.accent,
                    onTap: () => setState(() {
                      _mode = PaymentMode.cartao;
                      _invoiceMonth = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _ModeChip(
                    icon: Icons.qr_code_2_rounded,
                    label: 'Pix',
                    selected: _mode == PaymentMode.pix,
                    activeColor: AppColors.pixBlue,
                    onTap: () => setState(() {
                      _mode = PaymentMode.pix;
                      _invoiceMonth = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _ModeChip(
                    icon: Icons.payments_rounded,
                    label: 'Dinheiro',
                    selected: _mode == PaymentMode.dinheiro,
                    activeColor: AppColors.income,
                    onTap: () => setState(() {
                      _mode = PaymentMode.dinheiro;
                      _invoiceMonth = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── 2. Sub-tipo Cartão ───────────────────────────────────────
              if (_isCartao) ...[
                Text(
                  'Tipo',
                  style: TextStyle(
                      color: context.kTextSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TypeChip('À Vista', 'avista', _groupId,
                          (v) => setState(() {
                                _groupId = v;
                                _invoiceMonth = null;
                              })),
                      const SizedBox(width: 6),
                      _TypeChip('Parcelado', 'parcelamento', _groupId,
                          (v) => setState(() {
                                _groupId = v;
                                _invoiceMonth = null;
                              })),
                      const SizedBox(width: 6),
                      _TypeChip('Assinatura', 'assinatura', _groupId,
                          (v) => setState(() {
                                _groupId = v;
                                _invoiceMonth = null;
                              })),
                      const SizedBox(width: 6),
                      _TypeChip('Débito', 'debito', _groupId,
                          (v) => setState(() {
                                _groupId = v;
                                _invoiceMonth = null;
                              })),
                      const SizedBox(width: 6),
                      _TypeChip('Pix', 'pix', _groupId,
                          (v) => setState(() {
                                _groupId = v;
                                _invoiceMonth = null;
                              }),
                          color: AppColors.pixBlue),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── 3. Descrição ─────────────────────────────────────────────
              TextFormField(
                controller: _descCtrl,
                focusNode: _descFocus,
                style: TextStyle(color: context.kTextPrimary),
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [CapitalizeFirstFormatter()],
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // ── 4. Valor ─────────────────────────────────────────────────
              TextFormField(
                controller: _amountCtrl,
                focusNode: _amountFocus,
                style: TextStyle(
                  color: context.kTextPrimary,
                  fontFamily: 'JetBrainsMono',
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  prefixText: 'R\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                ],
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final parsed = double.tryParse(
                      v.replaceAll('.', '').replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ── 5. Parcelas (Cartão Parcelado) ───────────────────────────
              if (_isCartao && _groupId == 'parcelamento') ...[
                TextFormField(
                  controller: _installCtrl,
                  focusNode: _installFocus,
                  style: TextStyle(color: context.kTextPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Número de parcelas'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                if (totalAmt > 0 && installCount > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.info_outline,
                              size: 14, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            '${installCount}x de ${formatCurrency(parcAmt)}',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ]),
                        if (endMonthLabel.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Última parcela: $endMonthLabel',
                            style: TextStyle(
                              color: context.kTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],

              // ── 6. Data (oculta ao editar assinatura) ───────────────────
              if (!(_isCartao &&
                  _groupId == 'assinatura' &&
                  widget.editing != null))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Data',
                    style: TextStyle(
                        color: context.kTextSecondary, fontSize: 12),
                  ),
                  subtitle: Text(
                    formatDate(_date),
                    style: TextStyle(color: context.kTextPrimary),
                  ),
                  trailing:
                      Icon(Icons.calendar_today, color: _modeColor, size: 18),
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
              const SizedBox(height: 4),

              // ── 7. Banco (não aparece para Dinheiro) ─────────────────────
              if (_hasBank) ...[
                const SizedBox(height: 8),
                Text(
                  'Banco',
                  style: TextStyle(
                      color: context.kTextSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String?>(
                  initialValue: _bankId,
                  dropdownColor: context.kCard,
                  style: TextStyle(color: context.kTextPrimary),
                  decoration: const InputDecoration(),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Sem banco')),
                    ...getVisibleBanks().map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Row(children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: b.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(b.name),
                          ]),
                        )),
                  ],
                  onChanged: (v) => setState(() => _bankId = v),
                ),
                const SizedBox(height: 12),
              ],

              // ── 8. Entrará na fatura ─────────────────────────────────────
              // Aparece apenas para Cartão crédito (avista/parcelado), não assinatura/débito
              if (_showFatura) ...[
                _InvoiceMonthRow(
                  date: _date,
                  bankId: _bankId,
                  groupId: _groupId,
                  invoiceMonth: _invoiceMonth,
                  onClear: () => setState(() => _invoiceMonth = null),
                  onPick: (picked) => setState(() => _invoiceMonth = picked),
                ),
                const SizedBox(height: 12),
              ],

              // ── 9. Categoria ─────────────────────────────────────────────
              Text(
                'Categoria',
                style: TextStyle(
                    color: context.kTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                dropdownColor: context.kCard,
                style: TextStyle(color: context.kTextPrimary),
                decoration: const InputDecoration(),
                items: () {
                  final visible = getOrderedVisibleCategories();
                  final hasCurrentId =
                      visible.any((c) => c.id == _categoryId);
                  final all = hasCurrentId
                      ? visible
                      : [
                          ...getAllCategories()
                              .where((c) => c.id == _categoryId),
                          ...visible,
                        ];
                  return all
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(children: [
                              Icon(c.icon, color: c.color, size: 18),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ]),
                          ))
                      .toList();
                }(),
                onChanged: (v) => setState(() => _categoryId = v!),
              ),
              const SizedBox(height: 12),

              // ── 10. Modo família ─────────────────────────────────────────
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Modo família (dividir valor)',
                  style: TextStyle(
                      color: context.kTextPrimary, fontSize: 14),
                ),
                activeThumbColor: _modeColor,
                value: _familyMode,
                onChanged: (v) => setState(() => _familyMode = v),
              ),

              // ── 11. Escopo de edição de assinatura ───────────────────────
              if (showSubscriptionScope) ...[
                const SizedBox(height: 8),
                Text(
                  'Aplicar alteração',
                  style: TextStyle(
                      color: context.kTextSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                _ScopeOption(
                  title:
                      'A partir de ${formatMonth(widget.subscriptionEditMonth!)}',
                  subtitle:
                      'Preserva os meses anteriores e cria uma nova versão.',
                  selected: _subscriptionEditScope ==
                      SubscriptionEditScope.fromMonth,
                  onTap: () => setState(() =>
                      _subscriptionEditScope = SubscriptionEditScope.fromMonth),
                ),
                const SizedBox(height: 8),
                _ScopeOption(
                  title: 'Desde o início',
                  subtitle: 'Altera todo o período desta assinatura.',
                  selected: _subscriptionEditScope ==
                      SubscriptionEditScope.fromStart,
                  onTap: () => setState(() =>
                      _subscriptionEditScope = SubscriptionEditScope.fromStart),
                ),
              ],

              const SizedBox(height: 24),

              // ── 12. Salvar ───────────────────────────────────────────────
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _modeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submit,
                child: const Text(
                  'Salvar',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Seletor principal de modo de pagamento ────────────────────────────────────
class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: 0.12)
                : context.kCardBorder.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? activeColor : context.kTextSecondary,
                size: 22,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? activeColor : context.kTextSecondary,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-tipo de cartão (À Vista / Parcelado / Assinatura / Débito / Pix) ──────
class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final void Function(String) onTap;
  final Color? color;

  const _TypeChip(this.label, this.value, this.selected, this.onTap, {this.color});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    final activeColor = color ?? AppColors.accent;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : context.kCardBorder.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : context.kTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Opção de escopo de assinatura ─────────────────────────────────────────────
class _ScopeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : context.kCardBorder.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : context.kCardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.accent : context.kTextSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? AppColors.accent : context.kTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                        color: context.kTextSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner de rascunho restaurado ─────────────────────────────────────────────
class _DraftBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onClear;

  const _DraftBanner({required this.onDismiss, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.restore_rounded, size: 15, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rascunho restaurado',
              style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Limpar',
              style: TextStyle(
                  color: context.kTextSecondary,
                  fontSize: 11,
                  decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, size: 14, color: context.kTextSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Entrará na fatura ─────────────────────────────────────────────────────────
class _InvoiceMonthRow extends StatelessWidget {
  final DateTime date;
  final String? bankId;
  final String groupId;
  final DateTime? invoiceMonth;
  final VoidCallback onClear;
  final void Function(DateTime) onPick;

  const _InvoiceMonthRow({
    required this.date,
    required this.bankId,
    required this.groupId,
    required this.invoiceMonth,
    required this.onClear,
    required this.onPick,
  });

  DateTime _autoMonth() {
    final dummy = Transaction(
      id: '_preview',
      groupId: groupId,
      categoryId: 'outros',
      description: '',
      totalAmount: 0,
      startDate: date,
      createdAt: DateTime.now(),
      bankId: bankId,
      applyClosureDate: true,
    );
    return FinanceCalculator.getBillingMonth(dummy);
  }

  DateTime _billingDate(DateTime billingMonth) {
    final lastDay = DateTime(billingMonth.year, billingMonth.month + 1, 0).day;
    return DateTime(
        billingMonth.year, billingMonth.month, date.day.clamp(1, lastDay));
  }

  @override
  Widget build(BuildContext context) {
    final isManual = invoiceMonth != null;
    final displayMonth = isManual ? invoiceMonth! : _autoMonth();
    final label = formatDate(_billingDate(displayMonth));

    final accentColor = isManual ? AppColors.warning : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isManual ? Icons.edit_calendar_rounded : Icons.receipt_long_rounded,
              size: 22,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isManual ? 'FATURA AJUSTADA' : 'ENTRARÁ NA FATURA',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: context.kTextPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _showMonthPicker(context, displayMonth),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Alterar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (isManual) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onClear,
                  child: Text(
                    'Usar automático',
                    style: TextStyle(
                      color: context.kTextSecondary,
                      fontSize: 9,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context, DateTime current) {
    final now = DateTime.now();
    final months = List.generate(25, (i) {
      final offset = i - 12;
      return DateTime(now.year, now.month + offset);
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: context.kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: ctx.kCardBorder,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Escolher fatura',
              style: TextStyle(
                  color: ctx.kTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: months.length,
              itemBuilder: (_, i) {
                final m = months[i];
                final isSel =
                    m.year == current.year && m.month == current.month;
                return ListTile(
                  dense: true,
                  title: Text(
                    formatMonth(m),
                    style: TextStyle(
                      color:
                          isSel ? AppColors.accent : ctx.kTextPrimary,
                      fontWeight:
                          isSel ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSel
                      ? const Icon(Icons.check,
                          color: AppColors.accent, size: 18)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onPick(m);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
