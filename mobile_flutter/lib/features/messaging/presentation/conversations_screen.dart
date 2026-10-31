import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/messaging_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glowing_badge.dart';
import '../../../core/widgets/animated_list_item.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
    final settings = Provider.of<SettingsService>(context);
    final isDark = settings.isDarkMode;

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
                    Text(
                      'Messagerie STOMP 💬',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Discussions directes & groupes secrets',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                if (messagingService.totalUnread > 0)
                  GlowingBadge(
                    label: '${messagingService.totalUnread} non-lus',
                    icon: Icons.mark_email_unread_outlined,
                    color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                    isSelected: true,
                  ),
              ],
            ),
          ),

          // Conversation List
          Expanded(
            child: messagingService.isLoading
                ? Center(child: SpinKitThreeBounce(color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, size: 28))
                : messagingService.conversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune discussion',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textMainLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Démarrez une discussion avec vos contacts',
                              style: TextStyle(
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                fontSize: 13,
                              ),
                            ),
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
                            return AnimatedListItem(index: index, child: _buildConversationItem(context, conv, isDark));
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(BuildContext context, ConversationModel conv, bool isDark) {
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
                              ? [AppColors.accentPurple, isDark ? AppColors.indigoLight : AppColors.primaryIndigo]
                              : [const Color(0xFF4F46E5), const Color(0xFF0EA5E9)],
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
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCanvas : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      conv.isBirthday ? Icons.card_giftcard : Icons.groups,
                      size: 14,
                      color: isDark ? Colors.white : AppColors.textMainLight,
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
                            color: isDark ? Colors.white : AppColors.textMainLight,
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
                            color: hasUnread
                                ? (isDark ? AppColors.indigoLight : AppColors.primaryIndigo)
                                : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                            fontSize: 11,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
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
                            color: hasUnread
                                ? (isDark ? Colors.white : AppColors.textMainLight)
                                : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
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
                          color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
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
