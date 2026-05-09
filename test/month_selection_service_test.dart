import 'package:flutter_test/flutter_test.dart';
import 'package:konta/services/month_selection_service.dart';

void main() {
  test('normalizes shared selected month to the first day of the month', () {
    MonthSelectionService.setActiveMonth(DateTime(2026, 8, 22, 15, 30));

    expect(MonthSelectionService.activeMonth.value, DateTime(2026, 8));
  });
}
