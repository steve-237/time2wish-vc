import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/messaging_service.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glowing_badge.dart';
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagingService>().fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagingService = Provider.of<MessagingService>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Messagerie STOMP 💬',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Discussions directes & groupes secrets',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMutedDark),
                    ),
                  ],
                ),
                if (messagingService.totalUnread > 0)
                  GlowingBadge(
                    label: '${messagingService.totalUnread} non-lus',
                    icon: Icons.mark_email_unread_outlined,
                    color: AppColors.primaryCyan,
                    isSelected: true,
                  ),
              ],
            ),
          ),

          // Conversation List
          Expanded(
            child: messagingService.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : messagingService.conversations.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textMutedDark),
                            SizedBox(height: 12),
                            Text('Aucune discussion', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => messagingService.fetchConversations(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: messagingService.conversations.length,
                          itemBuilder: (context, index) {
                            final conv = messagingService.conversations[index];
                            return _buildConversationItem(context, conv);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(BuildContext context, ConversationModel conv) {
    final String initial = conv.name.isNotEmpty ? conv.name[0].toUpperCase() : '?';
    final hasUnread = conv.unreadCount > 0;
    final String timeStr = conv.lastMessageAt != null
        ? DateFormat('HH:mm').format(conv.lastMessageAt!)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GlassCard(
        onTap: () => context.push('/chat/${conv.id}'),
        child: Row(
          children: [
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: conv.isBirthday
                          ? [AppColors.wishCoinsAmber, AppColors.accentPink]
                          : conv.isGroup
                              ? [AppColors.accentPurple, AppColors.primaryBlue]
                              : [AppColors.primaryBlue, AppColors.cyanLight],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      conv.isBirthday ? '🎂' : initial,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: conv.isBirthday ? 22 : 20,
                      ),
                    ),
                  ),
                ),
                if (conv.isBirthday || conv.isGroup)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundDeep,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      conv.isBirthday ? Icons.card_giftcard : Icons.groups,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: hasUnread ? AppColors.cyanLight : AppColors.textMutedDark,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage ?? 'Commencer la discussion...',
                          style: TextStyle(
                            color: hasUnread ? Colors.white : AppColors.textMutedDark,
                            fontSize: 13,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        GlowingBadge(
                          label: '${conv.unreadCount}',
                          color: AppColors.primaryCyan,
                          isSelected: true,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
