import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time2wish_mobile/core/services/api_service.dart';
import 'package:time2wish_mobile/core/services/messaging_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MessagingService Tests', () {
    late ApiService apiService;
    late MessagingService messagingService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      apiService = ApiService();
      messagingService = MessagingService(apiService);
    });

    tearDown(() {
      messagingService.dispose();
    });

    test('Initial state has empty conversations and not connected', () {
      expect(messagingService.conversations, isEmpty);
      expect(messagingService.isConnected, isFalse);
      expect(messagingService.activeConversationId, isNull);
    });

    test('Derives WebSocket URL accurately from ApiService baseUrl', () {
      final wsUrl = apiService.getWsUrl();
      expect(wsUrl, contains('ws://'));
      expect(wsUrl, endsWith('/ws/websocket'));
    });

    test('Demo fallback provides seed conversations and demo messages', () async {
      await messagingService.fetchConversations();
      expect(messagingService.conversations, isNotEmpty);
      expect(messagingService.conversations.first.name, equals('Sophie Martin'));

      final messages = messagingService.getMessages(1);
      expect(messages, isNotEmpty);
      expect(messages.first.senderName, equals('Sophie Martin'));
    });

    test('sendMessage creates optimistic local message and updates conversation last message', () async {
      await messagingService.fetchConversations();
      final initialCount = messagingService.getMessages(1).length;

      await messagingService.sendMessage(1, 'Hello from automated unit test!', 'Tester');

      final updatedMessages = messagingService.getMessages(1);
      expect(updatedMessages.length, equals(initialCount + 1));
      expect(updatedMessages.last.content, equals('Hello from automated unit test!'));
      expect(updatedMessages.last.senderName, equals('Tester'));

      final conv = messagingService.conversations.firstWhere((c) => c.id == 1);
      expect(conv.lastMessage, equals('Hello from automated unit test!'));
    });

    test('markAsRead resets unread count for conversation', () async {
      await messagingService.fetchConversations();
      expect(messagingService.conversations.first.unreadCount, equals(2));

      await messagingService.markAsRead(1);
      expect(messagingService.conversations.first.unreadCount, equals(0));
    });

    test('subscribeToConversation sets activeConversationId and unsubscribe cleans it up', () {
      messagingService.subscribeToConversation(42);
      expect(messagingService.activeConversationId, equals(42));

      messagingService.unsubscribeFromConversation(42);
      expect(messagingService.activeConversationId, isNull);
    });
  });
}
