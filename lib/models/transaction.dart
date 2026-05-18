import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String groupId; // 'avista', 'parcelamento', 'assinatura'

  @HiveField(2)
  late String categoryId;

  @HiveField(3)
  late String description;

  @HiveField(4)
  late double totalAmount;

  @HiveField(5)
  late int installments;

  @HiveField(6)
  late DateTime startDate;

  @HiveField(7)
  late bool isSubscription;

  @HiveField(8)
  String? bankId; // 'itau', 'nubank', 'inter'

  @HiveField(9)
  late bool familyMode;

  @HiveField(10)
  String? familyMember;

  @HiveField(11)
  DateTime? cancelledFrom;

  @HiveField(12)
  late DateTime createdAt;

  @HiveField(13)
  String? subscriptionSeriesId;

  /// Subtipo de pagamento: 'pix', 'dinheiro', 'debito_direto'
  /// Usado em lançamentos À Vista e Débito para indicar a forma de pagamento.
  @HiveField(14)
  String? paymentSubtype;

  /// Indica se este lançamento deve usar a data de fechamento do cartão
  /// para calcular o mês de cobrança.
  /// false em lançamentos antigos (não afeta o histórico já ajustado manualmente).
  @HiveField(15)
  bool applyClosureDate;

  /// Mês de fatura definido manualmente pelo usuário (ex.: 2026-04-01).
  /// Quando não nulo, tem PRIORIDADE ABSOLUTA sobre qualquer cálculo automático.
  /// O lançamento aparece exatamente neste mês, sem ser movido para o seguinte.
  @HiveField(16)
  DateTime? invoiceMonth;

  Transaction({
    required this.id,
    required this.groupId,
    required this.categoryId,
    required this.description,
    required this.totalAmount,
    this.installments = 1,
    required this.startDate,
    this.isSubscription = false,
    this.bankId,
    this.familyMode = false,
    this.familyMember,
    this.cancelledFrom,
    required this.createdAt,
    this.subscriptionSeriesId,
    this.paymentSubtype,
    this.applyClosureDate = false,
    this.invoiceMonth,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        categoryId: json['categoryId'] as String,
        description: json['description'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        installments: (json['installments'] as num?)?.toInt() ?? 1,
        startDate: DateTime.parse(json['startDate'] as String),
        isSubscription: json['isSubscription'] as bool? ?? false,
        bankId: json['bankId'] as String?,
        familyMode: json['familyMode'] as bool? ?? false,
        familyMember: json['familyMember'] as String?,
        cancelledFrom: json['cancelledFrom'] != null
            ? DateTime.parse(json['cancelledFrom'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        subscriptionSeriesId: json['subscriptionSeriesId'] as String?,
        paymentSubtype: json['paymentSubtype'] as String?,
        applyClosureDate: json['applyClosureDate'] as bool? ?? false,
        invoiceMonth: json['invoiceMonth'] != null
            ? DateTime.parse(json['invoiceMonth'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'categoryId': categoryId,
        'description': description,
        'totalAmount': totalAmount,
        'installments': installments,
        'startDate': startDate.toIso8601String().split('T').first,
        'isSubscription': isSubscription,
        'bankId': bankId,
        'familyMode': familyMode,
        'familyMember': familyMember,
        'cancelledFrom': cancelledFrom?.toIso8601String().split('T').first,
        'createdAt': createdAt.toIso8601String(),
        'subscriptionSeriesId': subscriptionSeriesId,
        'paymentSubtype': paymentSubtype,
        'applyClosureDate': applyClosureDate,
        'invoiceMonth': invoiceMonth?.toIso8601String().split('T').first,
      };
}
