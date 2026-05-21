import 'database_service.dart';

/// Controla versões de schema do Hive e roda migrações na inicialização.
///
/// Como adicionar uma migração futura:
/// 1. Incremente [_currentSchemaVersion] de N para N+1.
/// 2. Adicione `case N+1:` no switch de [_runMigration].
/// 3. Escreva a lógica de seed/conversão dos dados existentes no novo campo.
class MigrationService {
  static const int _currentSchemaVersion = 1;
  static const String _versionKey = 'schema_version';

  /// Deve ser chamado após todos os boxes estarem abertos, antes dos seeds.
  static Future<void> runIfNeeded() async {
    final savedVersion = int.tryParse(
          DatabaseService.metaBox.get(_versionKey, defaultValue: '0')!,
        ) ??
        0;

    if (savedVersion >= _currentSchemaVersion) return;

    for (var v = savedVersion + 1; v <= _currentSchemaVersion; v++) {
      await _runMigration(v);
    }

    await DatabaseService.metaBox.put(
      _versionKey,
      '$_currentSchemaVersion',
    );
  }

  static Future<void> _runMigration(int version) async {
    switch (version) {
      case 1:
        // v1: migração inicial — null-safety aplicada nos adapters, nada a migrar.
        break;
    }
  }
}
