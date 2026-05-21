import 'package:flutter_test/flutter_test.dart';
import 'package:konta/services/backup_service.dart';

void main() {
  group('BackupRule serialization', () {
    test('round-trip for manual type', () {
      final rule = BackupRule(id: 'abc', type: BackupRuleType.manual);
      final restored = BackupRule.fromJson(rule.toJson());
      expect(restored.id, 'abc');
      expect(restored.type, BackupRuleType.manual);
      expect(restored.enabled, true);
    });

    test('round-trip for onSave type', () {
      final rule = BackupRule(id: 'onsave', type: BackupRuleType.onSave);
      final restored = BackupRule.fromJson(rule.toJson());
      expect(restored.type, BackupRuleType.onSave);
    });

    test('round-trip for scheduled type with hour and minute', () {
      final rule = BackupRule(
        id: 'sched',
        type: BackupRuleType.scheduled,
        scheduledHour: 22,
        scheduledMinute: 30,
        enabled: true,
      );
      final restored = BackupRule.fromJson(rule.toJson());
      expect(restored.scheduledHour, 22);
      expect(restored.scheduledMinute, 30);
      expect(restored.type, BackupRuleType.scheduled);
    });

    test('round-trip for weekly type with weekday', () {
      final rule = BackupRule(
        id: 'weekly',
        type: BackupRuleType.weekly,
        weekday: DateTime.monday,
      );
      final restored = BackupRule.fromJson(rule.toJson());
      expect(restored.weekday, DateTime.monday);
      expect(restored.type, BackupRuleType.weekly);
    });

    test('fromJson defaults enabled to true when field absent', () {
      final json = BackupRule(id: 'x', type: BackupRuleType.manual).toJson()
        ..remove('enabled');
      final restored = BackupRule.fromJson(json);
      expect(restored.enabled, true);
    });

    test('unknown type falls back to manual', () {
      final json = {'id': 'z', 'type': 'tipo_inexistente', 'enabled': true};
      final restored = BackupRule.fromJson(json);
      expect(restored.type, BackupRuleType.manual);
    });

    test('disabled rule round-trips correctly', () {
      final rule = BackupRule(
        id: 'dis',
        type: BackupRuleType.manual,
        enabled: false,
      );
      final restored = BackupRule.fromJson(rule.toJson());
      expect(restored.enabled, false);
    });
  });
}
