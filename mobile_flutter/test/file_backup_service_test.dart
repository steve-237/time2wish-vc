import 'package:flutter_test/flutter_test.dart';
import 'package:time2wish_mobile/core/services/file_backup_service.dart';

void main() {
  group('FileBackupService Tests', () {
    test('downloadJsonFile runs gracefully without throwing', () {
      expect(
        () => FileBackupService.downloadJsonFile(
          filename: 'test_backup.json',
          content: '{"test": true}',
        ),
        returnsNormally,
      );
    });

    test('pickJsonFile completes gracefully', () async {
      final result = await FileBackupService.pickJsonFile();
      expect(result == null || result is String, isTrue);
    });
  });
}
