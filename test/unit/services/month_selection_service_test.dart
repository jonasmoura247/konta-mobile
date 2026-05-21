import 'package:flutter_test/flutter_test.dart';
import 'package:konta/services/month_selection_service.dart';

void main() {
  test('normalizes shared selected month to the first day of the month', () {
    MonthSelectionService.setActiveMonth(DateTime(2026, 8, 22, 15, 30));
    expect(MonthSelectionService.activeMonth.value, DateTime(2026, 8));
  });

  test('setActiveMonth strips time component', () {
    MonthSelectionService.setActiveMonth(DateTime(2026, 12, 31, 23, 59));
    expect(MonthSelectionService.activeMonth.value, DateTime(2026, 12));
  });

  test('normalize returns first day of month', () {
    final result = MonthSelectionService.normalize(DateTime(2026, 3, 15, 10, 30));
    expect(result, DateTime(2026, 3));
  });

  test('setActiveMonth with first day of month stays unchanged', () {
    MonthSelectionService.setActiveMonth(DateTime(2025, 1, 1));
    expect(MonthSelectionService.activeMonth.value, DateTime(2025, 1));
  });
}
