import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 5)
class Reminder extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime date;

  @HiveField(2)
  late int hour;

  @HiveField(3)
  late int minute;

  @HiveField(4)
  late String description;

  @HiveField(5)
  late String? categoryId;

  @HiveField(6)
  late String? bankId;

  Reminder({
    required this.id,
    required this.date,
    required this.hour,
    required this.minute,
    required this.description,
    this.categoryId,
    this.bankId,
  });
}
