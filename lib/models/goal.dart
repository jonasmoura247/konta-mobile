import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 6)
class Goal extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double targetAmount;

  @HiveField(3)
  late double savedAmount;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0.0,
  });
}
