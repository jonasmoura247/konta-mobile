import 'package:hive/hive.dart';

part 'streak_data.g.dart';

@HiveType(typeId: 11)
class StreakData extends HiveObject {
  @HiveField(0)
  late int currentStreak;

  @HiveField(1)
  late int longestStreak;

  @HiveField(2)
  DateTime? lastActiveDay;

  StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDay,
  });
}
