import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sync_mutation.dart';
import 'api_service.dart';

class SyncService extends ChangeNotifier {
  static const _syncQueueKey = 't2w_sync_queue';
  final ApiService _apiService;

  List<SyncMutation> _queue = [];
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncError;

  SyncService(this._apiService) {
    _loadQueue();
  }

  List<SyncMutation> get queue => List.unmodifiable(_queue);
  int get pendingCount => _queue.length;
  bool get hasPending => _queue.isNotEmpty;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;

  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_syncQueueKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr);
        _queue = list.map((item) => SyncMutation.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to load sync queue: $e');
    }
  }

  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _queue.map((m) => m.toJson()).toList();
      await prefs.setString(_syncQueueKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[SyncService] Failed to persist sync queue: $e');
    }
  }

  /// Add a mutation to the synchronization queue
  Future<void> enqueue({
    required String endpoint,
    required String method,
    Map<String, dynamic>? data,
  }) async {
    final mutation = SyncMutation(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_queue.length}',
      endpoint: endpoint,
      method: method.toUpperCase(),
      data: data,
      createdAt: DateTime.now(),
    );

    _queue.add(mutation);
    await _saveQueue();
    notifyListeners();
    debugPrint('[SyncService] Mutation enqueued: ${mutation.method} ${mutation.endpoint} (Queue: ${_queue.length})');
  }

  /// Replay and execute all pending offline mutations to the backend
  Future<bool> syncAll() async {
    if (_isSyncing || _queue.isEmpty) return true;

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    debugPrint('[SyncService] Starting sync for ${_queue.length} pending mutations...');
    bool allSucceeded = true;

    final List<SyncMutation> pendingList = List.from(_queue);

    for (final mutation in pendingList) {
      try {
        Response response;
        switch (mutation.method) {
          case 'POST':
            response = await _apiService.dio.post(mutation.endpoint, data: mutation.data);
            break;
          case 'PUT':
            response = await _apiService.dio.put(mutation.endpoint, data: mutation.data);
            break;
          case 'DELETE':
            response = await _apiService.dio.delete(mutation.endpoint);
            break;
          default:
            throw UnsupportedError('Unknown method: ${mutation.method}');
        }

        if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
          debugPrint('[SyncService] Synchronized: ${mutation.method} ${mutation.endpoint}');
          _queue.removeWhere((m) => m.id == mutation.id);
          await _saveQueue();
        }
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final currentIdx = _queue.indexWhere((m) => m.id == mutation.id);
        final currentRetries = currentIdx != -1 ? _queue[currentIdx].retryCount + 1 : mutation.retryCount + 1;

        if (statusCode == 400 || statusCode == 401 || statusCode == 403 || statusCode == 404 || statusCode == 409 || currentRetries >= 3) {
          debugPrint('[SyncService] Discarding mutation (${mutation.method} ${mutation.endpoint}) after status $statusCode or $currentRetries retries');
          _queue.removeWhere((m) => m.id == mutation.id);
          await _saveQueue();
        } else if (currentIdx != -1) {
          _queue[currentIdx] = _queue[currentIdx].copyWith(retryCount: currentRetries);
          await _saveQueue();
          debugPrint('[SyncService] Network error during sync (${e.type}): halting queue processing');
          allSucceeded = false;
          _lastSyncError = 'Serveur inaccessible ou hors-ligne';
          break;
        } else {
          allSucceeded = false;
          _lastSyncError = 'Serveur inaccessible ou hors-ligne';
          break;
        }
      } catch (e) {
        debugPrint('[SyncService] Unexpected error during mutation replay: $e');
        allSucceeded = false;
        _lastSyncError = e.toString();
        break;
      }
    }

    _isSyncing = false;
    _lastSyncTime = DateTime.now();
    notifyListeners();
    return allSucceeded;
  }

  /// Clear any stuck mutations
  Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
    notifyListeners();
  }
}
