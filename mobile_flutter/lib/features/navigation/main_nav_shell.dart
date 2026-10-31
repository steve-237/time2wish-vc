import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/messaging_service.dart';
import '../../core/services/settings_service.dart';
import '../birthdays/presentation/birthday_list_screen.dart';
import '../contacts/presentation/contacts_screen.dart';
import '../messaging/presentation/conversations_screen.dart';
import '../profile/presentation/profile_screen.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    BirthdayListScreen(),
    ContactsScreen(),
    ConversationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadMessages = context.watch<MessagingService>().totalUnread;
    final settings = context.watch<SettingsService>();
    final isDark = settings.isDarkMode;

    return Scaffold(
      extendBody: true,
      body: Container(
        color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: KeyedSubtree(
              key: ValueKey<int>(_currentIndex),
              child: _pages[_currentIndex],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, unreadMessages, settings),
    );
  }

  Widget _buildBottomNav(BuildContext context, int unreadMessages, SettingsService settings) {
    final isDark = settings.isDarkMode;

    final navBgColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Background Bar Container (Clean solid elevated bar - zero glassmorphism)
          Container(
            height: 66 + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom
                  : 6,
            ),
            decoration: BoxDecoration(
              color: navBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                top: BorderSide(color: borderColor, width: 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Item 1: Anniversaires / Accueil
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: Icons.cake_outlined,
                    activeIcon: Icons.cake_rounded,
                    label: settings.tr('birthdays'),
                    badgeCount: 0,
                    isDark: isDark,
                  ),
                ),

                // Item 2: Contacts
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    label: settings.tr('contacts'),
                    badgeCount: 0,
                    isDark: isDark,
                  ),
                ),

                // Middle spacer reserved for the central FAB
                const SizedBox(width: 68),

                // Item 3: Messages
                Expanded(
                  child: _buildNavItem(
                    index: 2,
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: settings.tr('messages'),
                    badgeCount: unreadMessages,
                    isDark: isDark,
                  ),
                ),

                // Item 4: Profil
                Expanded(
                  child: _buildNavItem(
                    index: 3,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: settings.tr('profile'),
                    badgeCount: 0,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),

          // Central Floating Action Button (Elevated clean primary button)
          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: () {
                context.push('/birthday/new');
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4F46E5), // Indigo
                      Color(0xFF6366F1), // Light Indigo
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isDark ? AppColors.darkCanvas : Colors.white,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int badgeCount,
    required bool isDark,
  }) {
    final bool isSelected = _currentIndex == index;
    final activeColor = isDark ? AppColors.indigoLight : AppColors.primaryIndigo;
    final inactiveColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: isSelected ? 1.12 : 1.0,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentCoral,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
