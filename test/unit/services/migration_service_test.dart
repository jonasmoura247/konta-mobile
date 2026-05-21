import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:konta/services/database_service.dart';
import 'package:konta/services/migration_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('migration_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    if (!Hive.isBoxOpen('meta')) {
      await Hive.openBox<String>('meta');
    }
  });

  tearDown(() async {
    await DatabaseService.metaBox.clear();
  });

  test('starts at version null when meta box is empty', () {
    expect(DatabaseService.metaBox.get('schema_version'), isNull);
  });

  test('runIfNeeded saves current schema version', () async {
    await MigrationService.runIfNeeded();
    expect(DatabaseService.metaBox.get('schema_version'), '1');
  });

  test('runIfNeeded does not re-run if already at current version', () async {
    await MigrationService.runIfNeeded();
    await MigrationService.runIfNeeded();
    expect(DatabaseService.metaBox.get('schema_version'), '1');
  });
}
