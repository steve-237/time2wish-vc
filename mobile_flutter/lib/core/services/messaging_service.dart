import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import 'api_service.dart';

class MessagingService extends ChangeNotifier {
  final ApiService _apiService;
  List<ConversationModel> _conversations = [];
  final Map<int, List<MessageModel>> _messagesCache = {};
  bool _isLoading = false;

  MessagingService(this._apiService);

  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;

  int get totalUnread {
    return _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/messaging/conversations');
      if (response.statusCode == 200 && response.data != null) {
        _conversations = (response.data as List)
            .map((json) => ConversationModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('[MessagingService] API offline, loading demo conversations: $e');
      _conversations = _getDemoConversations();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<MessageModel> getMessages(int conversationId) {
    return _messagesCache[conversationId] ?? _getDemoMessages(conversationId);
  }

  Future<void> fetchMessages(int conversationId) async {
    try {
      final response = await _apiService.dio.get('/messaging/conversations/$conversationId/messages');
      if (response.statusCode == 200 && response.data != null) {
        _messagesCache[conversationId] = (response.data as List)
            .map((json) => MessageModel.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[MessagingService] API offline message fetch fallback');
      if (!_messagesCache.containsKey(conversationId)) {
        _messagesCache[conversationId] = _getDemoMessages(conversationId);
        notifyListeners();
      }
    }
  }

  Future<void> sendMessage(int conversationId, String content, String senderName) async {
    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId,
      senderId: 1, // Current user
      senderName: senderName,
      content: content,
      createdAt: DateTime.now(),
    );

    // Update local state immediately for instant feedback
    if (!_messagesCache.containsKey(conversationId)) {
      _messagesCache[conversationId] = [];
    }
    _messagesCache[conversationId]!.add(newMessage);

    // Update conversation last message
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: content,
        lastMessageAt: DateTime.now(),
      );
    }
    notifyListeners();

    try {
      await _apiService.dio.post('/messaging/conversations/$conversationId/messages', data: {
        'content': content,
      });
    } catch (e) {
      debugPrint('[MessagingService] API offline message send fallback');
    }
  }

  Future<void> markAsRead(int conversationId) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1 && _conversations[index].unreadCount > 0) {
      _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
      notifyListeners();
      try {
        await _apiService.dio.put('/messaging/conversations/$conversationId/read');
      } catch (_) {}
    }
  }

  List<ConversationModel> _getDemoConversations() {
    final now = DateTime.now();
    return [
      ConversationModel(
        id: 1,
        name: 'Sophie Martin',
        type: 'PRIVATE',
        members: ['Sophie Martin', 'Vous'],
        lastMessage: 'Tu viens au resto samedi ? 🎂',
        lastMessageAt: now.subtract(const Duration(minutes: 15)),
        unreadCount: 2,
      ),
      ConversationModel(
        id: 2,
        name: '🎉 Anniv Surprise Alexandre',
        type: 'BIRTHDAY',
        birthdayId: 2,
        members: ['Sophie', 'Emma', 'Lucas', 'Vous'],
        lastMessage: 'On gère le gâteau au chocolat !',
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        unreadCount: 0,
      ),
      ConversationModel(
        id: 3,
        name: 'Emma Leroy',
        type: 'PRIVATE',
        members: ['Emma Leroy', 'Vous'],
        lastMessage: 'Merci pour le cadeau !! ❤️',
        lastMessageAt: now.subtract(const Duration(days: 1)),
        unreadCount: 0,
      ),
    ];
  }

  List<MessageModel> _getDemoMessages(int conversationId) {
    final now = DateTime.now();
    if (conversationId == 1) {
      return [
        MessageModel(
          id: 101,
          conversationId: 1,
          senderId: 101,
          senderName: 'Sophie Martin',
          content: 'Coucou ! J\'espère que tu vas bien !',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        MessageModel(
          id: 102,
          conversationId: 1,
          senderId: 1,
          senderName: 'Vous',
          content: 'Oui super ! Et toi ? Prête pour ton anniversaire ? 🎉',
          createdAt: now.subtract(const Duration(minutes: 45)),
        ),
        MessageModel(
          id: 103,
          conversationId: 1,
          senderId: 101,
          senderName: 'Sophie Martin',
          content: 'Carrément ! Tu viens au resto samedi ? 🎂',
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
      ];
    } else if (conversationId == 2) {
      return [
        MessageModel(
          id: 201,
          conversationId: 2,
          senderId: 103,
          senderName: 'Emma',
          content: 'Qui s\'occupe de la déco pour Alexandre ?',
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
        MessageModel(
          id: 202,
          conversationId: 2,
          senderId: 104,
          senderName: 'Lucas',
          content: 'Je peux prendre les ballons et les guirlandes !',
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        MessageModel(
          id: 203,
          conversationId: 2,
          senderId: 103,
          senderName: 'Emma',
          content: 'On gère le gâteau au chocolat !',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
      ];
    }
    return [
      MessageModel(
        id: 301,
        conversationId: conversationId,
        senderId: 103,
        senderName: 'Contact',
        content: 'Bonjour ! Bienvenue dans le chat.',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }
}
