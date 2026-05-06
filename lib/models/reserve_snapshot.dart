import 'package:hive/hive.dart';

part 'reserve_snapshot.g.dart';

@HiveType(typeId: 4)
class ReserveSnapshot extends HiveObject {
  @HiveField(0)
  late String reserveId;

  @HiveField(1)
  late double amount;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late String type;

  ReserveSnapshot({
    required this.reserveId,
    required this.amount,
    required this.date,
    required this.type,
  });
}
