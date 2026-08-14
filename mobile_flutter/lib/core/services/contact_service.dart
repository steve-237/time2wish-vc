import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import 'api_service.dart';

class ContactService extends ChangeNotifier {
  final ApiService _apiService;
  List<ContactModel> _contacts = [];
  List<ContactModel> _pendingRequests = [];
  bool _isLoading = false;

  ContactService(this._apiService);

  List<ContactModel> get contacts => _contacts;
  List<ContactModel> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;

  Future<void> fetchContacts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/contacts');
      if (response.statusCode == 200 && response.data != null) {
        _contacts = (response.data as List)
            .map((json) => ContactModel.fromJson(json))
            .toList();
      }
      await fetchPendingRequests();
    } catch (e) {
      debugPrint('[ContactService] API offline, loading demo contacts: $e');
      _contacts = _getDemoContacts();
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
      debugPrint('[ContactService] API offline pending requests fallback');
    }
  }

  Future<bool> acceptRequest(int contactId) async {
    try {
      final response = await _apiService.dio.put('/contacts/$contactId/accept');
      if (response.statusCode == 200) {
        final accepted = _pendingRequests.firstWhere((c) => c.id == contactId);
        _pendingRequests.removeWhere((c) => c.id == contactId);
        _contacts.add(ContactModel(
          id: accepted.id,
          userId: accepted.userId,
          fullName: accepted.fullName,
          email: accepted.email,
          avatarUrl: accepted.avatarUrl,
          status: 'ACCEPTED',
        ));
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[ContactService] API offline accept fallback');
      final index = _pendingRequests.indexWhere((c) => c.id == contactId);
      if (index != -1) {
        final accepted = _pendingRequests.removeAt(index);
        _contacts.add(ContactModel(
          id: accepted.id,
          userId: accepted.userId,
          fullName: accepted.fullName,
          email: accepted.email,
          status: 'ACCEPTED',
        ));
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<bool> rejectRequest(int contactId) async {
    try {
      await _apiService.dio.put('/contacts/$contactId/reject');
    } catch (_) {}
    _pendingRequests.removeWhere((c) => c.id == contactId);
    notifyListeners();
    return true;
  }

  Future<bool> sendContactRequest(String email) async {
    try {
      await _apiService.dio.post('/contacts/request/by-email', data: {'email': email});
      return true;
    } catch (e) {
      // Local demo mock response
      return true;
    }
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
