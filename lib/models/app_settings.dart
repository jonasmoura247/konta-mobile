import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  late String currency;

  @HiveField(1)
  late String theme;

  @HiveField(2)
  late bool familyMode;

  @HiveField(3)
  late int familyCount;

  @HiveField(4)
  late List<String> familyNames;

  @HiveField(5)
  late bool carryoverMode;

  @HiveField(6)
  late bool goalsEnabled;

  AppSettings({
    this.currency = 'BRL',
    this.theme = 'dark',
    this.familyMode = false,
    this.familyCount = 2,
    List<String>? familyNames,
    this.carryoverMode = false,
    this.goalsEnabled = false,
  }) : familyNames = familyNames ?? ['Eu', 'Parceiro(a)'];
}
