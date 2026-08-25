import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

class ContactService extends ChangeNotifier {
  final ApiService _apiService;
  final LocalStorageService _storageService = LocalStorageService();
  List<ContactModel> _contacts = [];
  List<ContactModel> _pendingRequests = [];
  bool _isLoading = false;

  ContactService(this._apiService) {
    _initLocalStorage();
  }

  List<ContactModel> get contacts => _contacts;
  List<ContactModel> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;

  Future<void> _initLocalStorage() async {
    _contacts = await _storageService.loadContacts();
    if (_contacts.isEmpty) {
      _contacts = _getDemoContacts();
      await _storageService.saveContacts(_contacts);
    }
    _pendingRequests = _getDemoPendingRequests();
    notifyListeners();
  }

  Future<void> fetchContacts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/contacts');
      if (response.statusCode == 200 && response.data != null) {
        _contacts = (response.data as List)
            .map((json) => ContactModel.fromJson(json))
            .toList();
        await _storageService.saveContacts(_contacts);
      }
      await fetchPendingRequests();
    } catch (e) {
      debugPrint('[ContactService] Offline mode loading local contacts: $e');
      _contacts = await _storageService.loadContacts();
      if (_contacts.isEmpty) {
        _contacts = _getDemoContacts();
        await _storageService.saveContacts(_contacts);
      }
      _pendingRequests = _getDemoPendingRequests();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingRequests() async {
    try {
      final response = await _apiService.dio.get('/contacts/pending');
      if (response.statusCode == 200 && response.data != null) {
        _pendingRequests = (response.data as List)
            .map((json) => ContactModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('[ContactService] Offline pending requests fallback');
    }
  }

  Future<bool> acceptRequest(int contactId) async {
    final index = _pendingRequests.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      final accepted = _pendingRequests.removeAt(index);
      final newContact = ContactModel(
        id: accepted.id,
        userId: accepted.userId,
        fullName: accepted.fullName,
        email: accepted.email,
        status: 'ACCEPTED',
      );
      _contacts.add(newContact);
      await _storageService.saveContacts(_contacts);
      notifyListeners();
    }

    try {
      await _apiService.dio.put('/contacts/$contactId/accept');
    } catch (_) {}
    return true;
  }

  Future<bool> rejectRequest(int contactId) async {
    _pendingRequests.removeWhere((c) => c.id == contactId);
    notifyListeners();

    try {
      await _apiService.dio.put('/contacts/$contactId/reject');
    } catch (_) {}
    return true;
  }

  Future<bool> sendContactRequest(String email) async {
    final newContact = ContactModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: DateTime.now().millisecondsSinceEpoch,
      fullName: email.split('@').first,
      email: email,
      status: 'ACCEPTED',
    );
    _contacts.add(newContact);
    await _storageService.saveContacts(_contacts);
    notifyListeners();

    try {
      await _apiService.dio.post('/contacts/request/by-email', data: {'email': email});
    } catch (_) {}
    return true;
  }

  List<ContactModel> _getDemoContacts() {
    return [
      ContactModel(
        id: 1,
        userId: 101,
        fullName: 'Sophie Martin',
        email: 'sophie.martin@example.com',
        status: 'ACCEPTED',
      ),
      ContactModel(
        id: 2,
        userId: 102,
        fullName: 'Alexandre Dubois',
        email: 'alex.dubois@example.com',
        status: 'ACCEPTED',
      ),
      ContactModel(
        id: 3,
        userId: 103,
        fullName: 'Emma Leroy',
        email: 'emma.leroy@example.com',
        status: 'ACCEPTED',
      ),
      ContactModel(
        id: 4,
        userId: 104,
        fullName: 'Lucas Bernard',
        email: 'lucas.b@example.com',
        status: 'ACCEPTED',
      ),
    ];
  }

  List<ContactModel> _getDemoPendingRequests() {
    return [
      ContactModel(
        id: 10,
        userId: 105,
        fullName: 'Julie Moreau',
        email: 'julie.moreau@example.com',
        status: 'PENDING',
      ),
      ContactModel(
        id: 11,
        userId: 106,
        fullName: 'Thomas Petit',
        email: 'thomas.petit@example.com',
        status: 'PENDING',
      ),
    ];
  }
}
