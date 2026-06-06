import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';

class BackupService {
  static Future<String?> exportBackup(AppProvider provider) async {
    try {
      final data = await provider.exportData();
      final jsonStr = jsonEncode(data);

      final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final file = File('${dir.path}/ashwini_khata_backup_$timestamp.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'अश्विनी खाता बॅकअप',
        text: 'अश्विनी खाता बॅकअप फाइल',
      );

      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> importBackup(AppProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return false;

      final file = File(result.files.first.path!);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      await provider.importData(data);
      return true;
    } catch (e) {
      return false;
    }
  }
}
