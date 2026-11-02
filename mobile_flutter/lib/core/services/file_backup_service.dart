import 'file_backup_stub.dart'
    if (dart.library.js_interop) 'file_backup_web.dart';

class FileBackupService {
  static void downloadJsonFile({
    required String filename,
    required String content,
  }) {
    downloadFilePlatform(filename, content, 'application/json;charset=utf-8');
  }

  static Future<String?> pickJsonFile() async {
    return await pickJsonFilePlatform();
  }
}
