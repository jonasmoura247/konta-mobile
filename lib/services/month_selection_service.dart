import 'package:flutter/foundation.dart';

class MonthSelectionService {
  static final activeMonth =
      ValueNotifier<DateTime>(_monthStart(DateTime.now()));

  static DateTime normalize(DateTime date) => _monthStart(date);

  static void setActiveMonth(DateTime date) {
    activeMonth.value = _monthStart(date);
  }

  static DateTime _monthStart(DateTime date) => DateTime(date.year, date.month);
}
