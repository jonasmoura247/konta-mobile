import 'package:flutter/material.dart';
import '../models/bank.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../services/insights_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/horizontal_bar_chart.dart';
import '../widgets/insight_card.dart';
import '../widgets/month_picker_button.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with AutomaticKeepAliveClientMixin {
  DateTime _activeMonth = DateTime(DateTime.now().year, DateTime.now().month);
  MonthInsights? _monthInsights;
  YearInsights? _yearInsights;
  String _currency = 'BRL';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    DatabaseService.dataVersion.addListener(_recalculate);
    _recalculate();
  }

  @override
  void dispose() {
    DatabaseService.dataVersion.removeListener(_recalculate);
    super.dispose();
  }

  void _recalculate() {
    if (!mounted) return;
    final txs = DatabaseService.getAllTransactions();
    final incomes = DatabaseService.getAllIncomes();
    final settings = DatabaseService.getSettings();
    final familyCount = settings.familyMode ? settings.familyCount : 1;
    final currency = settings.currency;
    final prevMonth = DateTime(_activeMonth.year, _activeMonth.month - 1);

    final mi = InsightsService.computeMonthInsights(
      txs, incomes, _activeMonth, prevMonth, familyCount,
      currency: currency,
    );
    final yi = InsightsService.computeYearInsights(
      txs, incomes, _activeMonth.year, familyCount,
      currency: currency,
    );

    setState(() {
      _monthInsights = mi;
      _yearInsights = yi;
      _currency = currency;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mi = _monthInsights;
    final yi = _yearInsights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Análise do mês',
                style: TextStyle(
                  fontSize: 13,
                  color: context.kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              MonthPickerButton(
                activeMonth: _activeMonth,
                onChanged: (m) {
                  setState(() => _activeMonth = m);
                  _recalculate();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (mi == null || yi == null)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MonthBlock(insights: mi, currency: _currency, month: _activeMonth),
                  const SizedBox(height: 28),
                  _YearBlock(insights: yi, year: _activeMonth.year, currency: _currency),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Month Block ───────────────────────────────────────────────────────────────

class _MonthBlock extends StatelessWidget {
  final MonthInsights insights;
  final String currency;
  final DateTime month;

  const _MonthBlock({required this.insights, required this.currency, required this.month});

  @override
  Widget build(BuildContext context) {
    final hasData = insights.topCategories.isNotEmpty || insights.avgTicket > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Este mês',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: context.kTextPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          capitalize(formatMonth(month)),
          style: TextStyle(fontSize: 12, color: context.kTextSecondary),
        ),
        const SizedBox(height: 14),
        if (!hasData)
          _EmptyState(message: 'Nenhum lançamento em ${capitalize(formatMonth(month))}')
        else ...[
          if (insights.topCategories.isNotEmpty) ...[
            HorizontalBarChart(bars: insights.topCategories, currency: currency),
            const SizedBox(height: 16),
          ],
          _StatsGrid(children: _monthStats(context, insights, currency)),
          if (insights.insights.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._buildInsightCards(insights.insights),
          ],
        ],
      ],
    );
  }

  List<_StatItem> _monthStats(BuildContext context, MonthInsights mi, String currency) {
    final weekdayNames = ['', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    final bankName = mi.mostUsedBankId != null
        ? (getBankById(mi.mostUsedBankId)?.name ?? mi.mostUsedBankId!)
        : null;

    return [
      _StatItem(
        label: 'Maior compra',
        value: mi.biggestPurchase != null
            ? formatCurrency(mi.biggestPurchase!.amount, currency: currency)
            : '--',
        isMono: true,
      ),
      _StatItem(
        label: 'Maior à vista',
        value: mi.biggestCashPurchase != null
            ? formatCurrency(mi.biggestCashPurchase!.amount, currency: currency)
            : '--',
        isMono: true,
      ),
      _StatItem(
        label: 'Maior parcelada',
        value: mi.biggestInstallmentPurchase != null
            ? formatCurrency(mi.biggestInstallmentPurchase!.transaction.totalAmount, currency: currency)
            : '--',
        isMono: true,
      ),
      _StatItem(
        label: 'Ticket médio',
        value: mi.avgTicket > 0
            ? formatCurrency(mi.avgTicket, currency: currency)
            : '--',
        isMono: true,
      ),
      _StatItem(
        label: 'Média diária',
        value: mi.avgDailySpend > 0
            ? formatCurrency(mi.avgDailySpend, currency: currency)
            : '--',
        isMono: true,
      ),
      _StatItem(
        label: 'Dia que mais gasta',
        value: mi.topWeekday != null ? weekdayNames[mi.topWeekday!] : '--',
      ),
      _StatItem(
        label: 'Parcelas ativas',
        value: mi.activeInstallmentCount > 0 ? '${mi.activeInstallmentCount}' : '--',
      ),
      _StatItem(
        label: 'Total pendente',
        value: mi.totalPendingInstallments > 0
            ? formatCurrency(mi.totalPendingInstallments, currency: currency)
            : '--',
        isMono: true,
      ),
      if (bankName != null)
        _StatItem(label: 'Cartão mais usado', value: bankName),
      _StatItem(
        label: 'Renda comprometida',
        value: mi.incomeCommittedPercent > 0
            ? '${mi.incomeCommittedPercent.toStringAsFixed(0)}%'
            : '--',
      ),
      _StatItem(
        label: 'Próxima fatura',
        value: mi.nextMonthTotal > 0
            ? formatCurrency(mi.nextMonthTotal, currency: currency)
            : '--',
        isMono: true,
      ),
    ];
  }
}

// ── Year Block ────────────────────────────────────────────────────────────────

class _YearBlock extends StatelessWidget {
  final YearInsights insights;
  final int year;
  final String currency;

  const _YearBlock({required this.insights, required this.year, required this.currency});

  @override
  Widget build(BuildContext context) {
    final hasData = insights.totalYearSpend > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Este ano',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: context.kTextPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          '$year',
          style: TextStyle(fontSize: 12, color: context.kTextSecondary),
        ),
        const SizedBox(height: 14),
        if (!hasData)
          const _EmptyState(message: 'Sem dados para o ano atual')
        else ...[
          if (insights.topCategories.isNotEmpty) ...[
            HorizontalBarChart(bars: insights.topCategories, currency: currency),
            const SizedBox(height: 16),
          ],
          if (insights.biggestInstallmentOfYear != null || insights.biggestCashOfYear != null) ...[
            _BigPurchasesRow(
              installment: insights.biggestInstallmentOfYear,
              cash: insights.biggestCashOfYear,
              currency: currency,
            ),
            const SizedBox(height: 16),
          ],
          _StatsGrid(children: _yearStats(insights, currency)),
          if (insights.insights.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._buildInsightCards(insights.insights),
          ],
        ],
      ],
    );
  }

  List<_StatItem> _yearStats(YearInsights yi, String currency) {
    final bankName = yi.mostUsedBankId != null
        ? (getBankById(yi.mostUsedBankId)?.name ?? yi.mostUsedBankId!)
        : null;

    return [
      _StatItem(
        label: 'Mês mais econômico',
        value: yi.mostEconomicMonth != null
            ? capitalize(formatMonthShort(yi.mostEconomicMonth!))
            : '--',
      ),
      _StatItem(
        label: 'Mês mais caro',
        value: yi.mostExpensiveMonth != null
            ? capitalize(formatMonthShort(yi.mostExpensiveMonth!))
            : '--',
      ),
      _StatItem(
        label: 'Ticket médio',
        value: yi.avgTicket > 0 ? formatCurrency(yi.avgTicket, currency: currency) : '--',
        isMono: true,
      ),
      _StatItem(
        label: 'Média mensal',
        value: yi.avgMonthlySpend > 0
            ? formatCurrency(yi.avgMonthlySpend, currency: currency)
            : '--',
        isMono: true,
      ),
      _StatItem(
        label: 'Total gasto',
        value: formatCurrency(yi.totalYearSpend, currency: currency),
        isMono: true,
      ),
      _StatItem(
        label: 'Total em cartão',
        value: formatCurrency(yi.totalYearCard, currency: currency),
        isMono: true,
      ),
      _StatItem(
        label: 'Total à vista',
        value: yi.totalYearCash > 0
            ? formatCurrency(yi.totalYearCash, currency: currency)
            : '--',
        isMono: true,
      ),
      _StatItem(
        label: 'Total parcelado',
        value: yi.totalYearInstallments > 0
            ? formatCurrency(yi.totalYearInstallments, currency: currency)
            : '--',
        isMono: true,
      ),
      _StatItem(
        label: 'Meses c/ parcelas',
        value: yi.monthsWithFutureInstallments > 0
            ? '${yi.monthsWithFutureInstallments}'
            : '--',
      ),
      if (bankName != null) _StatItem(label: 'Banco mais usado', value: bankName),
    ];
  }
}

// ── Big Purchases Row ─────────────────────────────────────────────────────────

class _BigPurchasesRow extends StatelessWidget {
  final TransactionOccurrence? installment;
  final TransactionOccurrence? cash;
  final String currency;

  const _BigPurchasesRow({this.installment, this.cash, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (installment != null)
          Expanded(
            child: _BigPurchaseCard(
              label: 'Maior parcelada',
              occ: installment!,
              displayAmount: installment!.transaction.totalAmount,
              currency: currency,
            ),
          ),
        if (installment != null && cash != null) const SizedBox(width: 8),
        if (cash != null)
          Expanded(
            child: _BigPurchaseCard(
              label: 'Maior à vista',
              occ: cash!,
              displayAmount: cash!.amount,
              currency: currency,
            ),
          ),
      ],
    );
  }
}

class _BigPurchaseCard extends StatelessWidget {
  final String label;
  final TransactionOccurrence occ;
  final double displayAmount;
  final String currency;

  const _BigPurchaseCard({
    required this.label,
    required this.occ,
    required this.displayAmount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: context.kTextSecondary)),
          const SizedBox(height: 6),
          Text(
            occ.transaction.description,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.kTextPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(displayAmount, currency: currency),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.expense,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatDateShort(occ.transaction.startDate),
            style: TextStyle(fontSize: 11, color: context.kTextSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────────────────

class _StatItem {
  final String label;
  final String value;
  final bool isMono;
  const _StatItem({required this.label, required this.value, this.isMono = false});
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> children;
  const _StatsGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.4,
      ),
      itemCount: children.length,
      itemBuilder: (_, i) {
        final item = children[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.kCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.label,
                style: TextStyle(fontSize: 11, color: context.kTextSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.kTextPrimary,
                  fontFamily: item.isMono ? 'JetBrainsMono' : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

List<Widget> _buildInsightCards(List<String> insights) {
  return insights.map((text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InsightCard(text: text, icon: _iconForInsight(text)),
    );
  }).toList();
}

IconData _iconForInsight(String text) {
  final t = text.toLowerCase();
  if (t.contains('economiz') || t.contains('caiu')) return Icons.trending_down;
  if (t.contains('a mais que')) return Icons.trending_up;
  if (t.contains('maior gasto') || t.contains('maior parcelada')) return Icons.star_border;
  if (t.contains('segunda') || t.contains('terça') || t.contains('quarta') ||
      t.contains('quinta') || t.contains('sexta') || t.contains('sábado') ||
      t.contains('domingo')) { return Icons.calendar_today_outlined; }
  if (t.contains('manhã') || t.contains('tarde') || t.contains('noite')) {
    return Icons.access_time_outlined;
  }
  if (t.contains('parcela')) return Icons.credit_card_outlined;
  if (t.contains('renda')) return Icons.account_balance_wallet_outlined;
  if (t.contains('padrão') || t.contains('acima')) return Icons.warning_amber_outlined;
  if (t.contains('semestre')) return Icons.bar_chart;
  if (t.contains('principal categoria')) return Icons.category_outlined;
  if (t.contains('econômico')) return Icons.savings_outlined;
  if (t.contains('saldo')) return Icons.account_balance_outlined;
  if (t.contains('total gasto')) return Icons.receipt_long_outlined;
  return Icons.tips_and_updates_outlined;
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 13, color: context.kTextSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
