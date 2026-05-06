import 'package:hive/hive.dart';

part 'reserve.g.dart';

@HiveType(typeId: 3)
class Reserve extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String description;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late DateTime date;

  @HiveField(4)
  late String type; // 'poupanca' | 'investimento' | 'emergencia' | 'outro'

  Reserve({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });
}
