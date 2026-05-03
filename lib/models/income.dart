import 'package:hive/hive.dart';

part 'income.g.dart';

@HiveType(typeId: 1)
class Income extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String description;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late DateTime date;

  @HiveField(4)
  late bool recurring;

  Income({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.recurring = false,
  });

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: json['id'] as String,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        recurring: json['recurring'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String().split('T').first,
        'recurring': recurring,
      };
}
