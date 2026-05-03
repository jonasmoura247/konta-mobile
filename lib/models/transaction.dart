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
      };
}
