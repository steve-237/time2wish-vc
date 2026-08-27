import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/messaging_service.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messagingService = context.read<MessagingService>();
      messagingService.fetchMessages(widget.conversationId);
      messagingService.markAsRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final messagingService = context.read<MessagingService>();
    messagingService.sendMessage(widget.conversationId, text, 'Vous');
    _messageController.clear();

    // Scroll to bottom after message sent
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagingService = Provider.of<MessagingService>(context);
    final messages = messagingService.getMessages(widget.conversationId);
    
    ConversationModel? conversation;
    try {
      conversation = messagingService.conversations.firstWhere((c) => c.id == widget.conversationId);
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDeep,
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.primaryBlue, AppColors.accentPurple]),
              ),
              child: Center(
                child: Text(
                  conversation?.name[0] ?? 'C',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation?.name ?? 'Salon de discussion',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'En ligne via WebSocket STOMP',
                    style: TextStyle(color: AppColors.successGreen, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [AppColors.backgroundDeep, AppColors.backgroundDialogDark],
          ),
        ),
        child: Column(
          children: [
            // Messages stream
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text('Aucun message. Dites bonjour ! 👋', style: TextStyle(color: AppColors.textMutedDark)),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderName == 'Vous' || msg.senderId == 1;
                        final timeStr = DateFormat('HH:mm').format(msg.createdAt);

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              gradient: isMe
                                  ? const LinearGradient(colors: [AppColors.primaryBlue, AppColors.accentPurple])
                                  : null,
                              color: isMe ? null : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                              border: Border.all(
                                color: isMe ? Colors.transparent : Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    msg.senderName,
                                    style: const TextStyle(color: AppColors.cyanLight, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                Text(
                                  msg.content,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    timeStr,
                                    style: TextStyle(
                                      color: isMe ? Colors.white70 : AppColors.textMutedDark,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundDeep.withValues(alpha: 0.95),
                border: const Border(top: BorderSide(color: Colors.white10)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Écrire un message...',
                            hintStyle: TextStyle(color: AppColors.textMutedDark, fontSize: 14),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primaryBlue, AppColors.accentPurple]),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
