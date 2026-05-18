import 'package:hive/hive.dart';

part 'card_due_date.g.dart';

@HiveType(typeId: 7)
class CardDueDate extends HiveObject {
  @HiveField(0)
  late String bankId;

  @HiveField(1)
  late int closureDay; // dia de fechamento da fatura: 1–31

  @HiveField(2)
  late int paymentDay; // dia de pagamento da fatura: 1–31

  // Overrides por mês: chave "YYYYMM", valor = dia de fechamento daquele mês
  @HiveField(3)
  Map<String, int>? overrideClosure;

  // Overrides de pagamento por mês: chave "YYYYMM", valor = dia de pagamento
  @HiveField(4)
  Map<String, int>? overridePayment;

  CardDueDate({
    required this.bankId,
    required this.closureDay,
    required this.paymentDay,
    this.overrideClosure,
    this.overridePayment,
  });

  /// Retorna a chave de mês no formato "YYYYMM"
  static String monthKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}';

  /// Dia de fechamento real para o mês informado.
  /// Se o dia configurado não existe no mês, usa o último dia do mês.
  int closureDayFor(DateTime month) {
    final key = monthKey(month);
    final day = overrideClosure?[key] ?? closureDay;
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return day.clamp(1, lastDay);
  }

  /// Dia de pagamento real para o mês informado.
  int paymentDayFor(DateTime month) {
    final key = monthKey(month);
    final day = overridePayment?[key] ?? paymentDay;
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return day.clamp(1, lastDay);
  }

  /// Data de fechamento real para o mês informado.
  DateTime closureDateFor(DateTime month) =>
      DateTime(month.year, month.month, closureDayFor(month));

  /// Data de pagamento real para o mês informado.
  DateTime paymentDateFor(DateTime month) =>
      DateTime(month.year, month.month, paymentDayFor(month));

  /// Sobrescreve o dia de fechamento apenas para um mês específico.
  void setClosureOverride(DateTime month, int day) {
    overrideClosure ??= {};
    overrideClosure![monthKey(month)] = day;
  }

  /// Sobrescreve o dia de pagamento apenas para um mês específico.
  void setPaymentOverride(DateTime month, int day) {
    overridePayment ??= {};
    overridePayment![monthKey(month)] = day;
  }

  Map<String, dynamic> toJson() => {
        'bankId': bankId,
        'closureDay': closureDay,
        'paymentDay': paymentDay,
        'overrideClosure': overrideClosure,
        'overridePayment': overridePayment,
      };

  factory CardDueDate.fromJson(Map<String, dynamic> json) => CardDueDate(
        bankId: json['bankId'] as String,
        closureDay: (json['closureDay'] as num).toInt(),
        paymentDay: (json['paymentDay'] as num).toInt(),
        overrideClosure: (json['overrideClosure'] as Map?)
            ?.map((key, value) => MapEntry(key.toString(), (value as num).toInt())),
        overridePayment: (json['overridePayment'] as Map?)
            ?.map((key, value) => MapEntry(key.toString(), (value as num).toInt())),
      );
}
