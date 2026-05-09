import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'database_service.dart';

class ImportService {
  static Future<ImportResult?> importJsonFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.first.bytes;
    String jsonString;
    if (bytes != null) {
      jsonString = utf8.decode(bytes);
    } else {
      final path = result.files.first.path;
      if (path == null) return null;
      jsonString = await File(path).readAsString(encoding: utf8);
    }

    return DatabaseService.importFromJson(jsonString);
  }

  static Future<String?> exportJsonWithPicker() async {
    final jsonString = DatabaseService.exportToJson();
    final bytes = Uint8List.fromList(utf8.encode(jsonString));

    return FilePicker.platform.saveFile(
      dialogTitle: 'Salvar backup',
      fileName: 'konta.json',
      bytes: bytes,
    );
  }
}
