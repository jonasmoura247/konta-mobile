import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';

enum BackupRuleType { manual, onSave, scheduled, weekly }

class BackupRule {
  final String id;
  final BackupRuleType type;
  final int? scheduledHour;
  final int? scheduledMinute;
  final int? weekday; // DateTime.monday=1 .. DateTime.sunday=7
  final bool enabled;

  const BackupRule({
    required this.id,
    required this.type,
    this.scheduledHour,
    this.scheduledMinute,
    this.weekday,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'scheduled_hour': scheduledHour,
    'scheduled_minute': scheduledMinute,
    'weekday': weekday,
    'enabled': enabled,
  };

  factory BackupRule.fromJson(Map<String, dynamic> j) => BackupRule(
    id: j['id'] as String,
    type: BackupRuleType.values.firstWhere(
      (e) => e.name == j['type'],
      orElse: () => BackupRuleType.manual,
    ),
    scheduledHour: j['scheduled_hour'] as int?,
    scheduledMinute: j['scheduled_minute'] as int?,
    weekday: j['weekday'] as int?,
    enabled: j['enabled'] as bool? ?? true,
  );

  BackupRule copyWith({bool? enabled}) => BackupRule(
    id: id,
    type: type,
    scheduledHour: scheduledHour,
    scheduledMinute: scheduledMinute,
    weekday: weekday,
    enabled: enabled ?? this.enabled,
  );

  String get displayLabel {
    switch (type) {
      case BackupRuleType.manual:
        return 'Manual';
      case BackupRuleType.onSave:
        return 'A cada salvamento';
      case BackupRuleType.scheduled:
        final h = (scheduledHour ?? 0).toString().padLeft(2, '0');
        final m = (scheduledMinute ?? 0).toString().padLeft(2, '0');
        return 'Diário às $h:$m';
      case BackupRuleType.weekly:
        const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
        final day = days[(weekday ?? 1) - 1];
        final h = (scheduledHour ?? 0).toString().padLeft(2, '0');
        final m = (scheduledMinute ?? 0).toString().padLeft(2, '0');
        return 'Toda $day às $h:$m';
    }
  }
}

class BackupConfig {
  final String? backupFolderPath;
  final List<BackupRule> rules;
  final DateTime? lastBackupAt;
  final bool firstRunDone;

  const BackupConfig({
    this.backupFolderPath,
    this.rules = const [],
    this.lastBackupAt,
    this.firstRunDone = false,
  });

  Map<String, dynamic> toJson() => {
    'backup_folder_path': backupFolderPath,
    'rules': rules.map((r) => r.toJson()).toList(),
    'last_backup_at': lastBackupAt?.toIso8601String(),
    'first_run_done': firstRunDone,
  };

  factory BackupConfig.fromJson(Map<String, dynamic> j) => BackupConfig(
    backupFolderPath: j['backup_folder_path'] as String?,
    rules: (j['rules'] as List<dynamic>? ?? [])
        .map((r) => BackupRule.fromJson(r as Map<String, dynamic>))
        .toList(),
    lastBackupAt: j['last_backup_at'] != null
        ? DateTime.tryParse(j['last_backup_at'] as String)
        : null,
    firstRunDone: j['first_run_done'] as bool? ?? false,
  );

  BackupConfig copyWith({
    String? backupFolderPath,
    List<BackupRule>? rules,
    DateTime? lastBackupAt,
    bool? firstRunDone,
    bool clearFolderPath = false,
  }) => BackupConfig(
    backupFolderPath:
        clearFolderPath ? null : (backupFolderPath ?? this.backupFolderPath),
    rules: rules ?? this.rules,
    lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    firstRunDone: firstRunDone ?? this.firstRunDone,
  );
}

class BackupService {
  static bool _initialized = false;
  static bool _isBackingUp = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;
    DatabaseService.dataVersion.addListener(_onDataChanged);
    _checkScheduledRules();
  }

  // ── Config ────────────────────────────────────────────────────────────

  static BackupConfig getConfig() {
    final raw = DatabaseService.getRawBackupConfig();
    if (raw == null) return const BackupConfig();
    try {
      return BackupConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const BackupConfig();
    }
  }

  static Future<void> saveConfig(BackupConfig config) async {
    await DatabaseService.saveRawBackupConfig(jsonEncode(config.toJson()));
  }

  // ── Listeners ────────────────────────────────────────────────────────

  static void _onDataChanged() {
    if (_isBackingUp) return;
    final config = getConfig();
    final hasOnSave = config.rules.any(
      (r) => r.type == BackupRuleType.onSave && r.enabled,
    );
    if (hasOnSave) {
      performBackup(config).ignore();
    }
  }

  static Future<void> _checkScheduledRules() async {
    final config = getConfig();
    final now = DateTime.now();

    for (final rule in config.rules) {
      if (!rule.enabled) continue;
      final hour = rule.scheduledHour ?? 0;
      final minute = rule.scheduledMinute ?? 0;

      if (rule.type == BackupRuleType.scheduled) {
        final scheduled = DateTime(now.year, now.month, now.day, hour, minute);
        if (now.isAfter(scheduled)) {
          final last = config.lastBackupAt;
          if (last == null || last.isBefore(scheduled)) {
            await performBackup(config);
            return;
          }
        }
      } else if (rule.type == BackupRuleType.weekly) {
        final day = rule.weekday ?? DateTime.monday;
        if (now.weekday == day) {
          final scheduled =
              DateTime(now.year, now.month, now.day, hour, minute);
          if (now.isAfter(scheduled)) {
            final last = config.lastBackupAt;
            if (last == null || last.isBefore(scheduled)) {
              await performBackup(config);
              return;
            }
          }
        }
      }
    }
  }

  // ── Backup ────────────────────────────────────────────────────────────

  static Future<String> _defaultFolderPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  static Future<String?> selectBackupFolder() async {
    return FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Escolher pasta para backup',
    );
  }

  /// Realiza backup e retorna true se salvou com sucesso.
  static Future<bool> performBackup(BackupConfig config) async {
    if (_isBackingUp) return false;
    _isBackingUp = true;
    try {
      String folderPath =
          config.backupFolderPath ?? await _defaultFolderPath();

      bool success = await _writeToFolder(folderPath);

      // Se a pasta personalizada não funcionou, usa o diretório padrão do app
      if (!success && config.backupFolderPath != null) {
        folderPath = await _defaultFolderPath();
        success = await _writeToFolder(folderPath);
      }

      if (success) {
        // Recarrega config para não sobrescrever mudanças feitas durante o backup
        final current = getConfig();
        await saveConfig(current.copyWith(lastBackupAt: DateTime.now()));
      }
      return success;
    } finally {
      _isBackingUp = false;
    }
  }

  static Future<bool> _writeToFolder(String folderPath) async {
    try {
      final dir = Directory(folderPath);
      if (!await dir.exists()) return false;
      final file = File('$folderPath/konta_backup.json');
      await file.writeAsString(DatabaseService.exportToJson(), flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String newRuleId() => const Uuid().v4();
}
