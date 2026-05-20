import 'package:hive/hive.dart';

part 'achievement.g.dart';

@HiveType(typeId: 10)
class Achievement extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late int stars;

  @HiveField(4)
  late bool hidden;

  @HiveField(5)
  late bool unlocked;

  @HiveField(6)
  DateTime? unlockedAt;

  @HiveField(7)
  late String criteria;

  @HiveField(8)
  int? progress;

  @HiveField(9)
  int? goal;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.stars,
    this.hidden = true,
    this.unlocked = false,
    this.unlockedAt,
    required this.criteria,
    this.progress,
    this.goal,
  });
}
