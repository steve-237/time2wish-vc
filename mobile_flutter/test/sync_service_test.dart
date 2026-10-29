import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time2wish_mobile/core/models/sync_mutation.dart';
import 'package:time2wish_mobile/core/services/sync_service.dart';
import 'package:time2wish_mobile/core/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncMutation Unit Tests', () {
    test('SyncMutation serialization to and from JSON', () {
      final now = DateTime.now();
      final mutation = SyncMutation(
        id: 'mut_123',
        endpoint: '/birthdays',
        method: 'POST',
        data: {'name': 'Alice', 'category': 'AMIS'},
        createdAt: now,
      );

      final json = mutation.toJson();
      expect(json['id'], 'mut_123');
      expect(json['method'], 'POST');
      expect(json['endpoint'], '/birthdays');
      expect(json['data']['name'], 'Alice');

      final reconstructed = SyncMutation.fromJson(json);
      expect(reconstructed.id, mutation.id);
      expect(reconstructed.method, mutation.method);
      expect(reconstructed.endpoint, mutation.endpoint);
      expect(reconstructed.data?['name'], 'Alice');
    });

    test('SyncService queue management', () async {
      SharedPreferences.setMockInitialValues({});
      final apiService = ApiService();
      final syncService = SyncService(apiService);

      expect(syncService.pendingCount, 0);
      expect(syncService.hasPending, false);

      await syncService.enqueue(
        endpoint: '/birthdays/1',
        method: 'PUT',
        data: {'name': 'Bob'},
      );

      expect(syncService.pendingCount, 1);
      expect(syncService.hasPending, true);
      expect(syncService.queue.first.endpoint, '/birthdays/1');
      expect(syncService.queue.first.method, 'PUT');

      await syncService.clearQueue();
      expect(syncService.pendingCount, 0);
      expect(syncService.hasPending, false);
    });
  });
}
