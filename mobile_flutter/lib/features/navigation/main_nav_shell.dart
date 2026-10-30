import 'dart:ui';
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
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.backgroundGradient : null,
          color: isDark ? null : AppColors.backgroundLight,
        ),
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
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

    // Background color matching screenshot: deep dark slate / navy glass
    final navBgColor = isDark
        ? const Color(0xFF0C1322).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.95);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Background Bar Container
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 68 + MediaQuery.of(context).padding.bottom,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom > 0
                      ? MediaQuery.of(context).padding.bottom
                      : 6,
                ),
                decoration: BoxDecoration(
                  color: navBgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  border: Border(
                    top: BorderSide(color: borderColor, width: 1.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
                      blurRadius: 25,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Item 1: Anniversaires
                    Expanded(
                      child: _buildNavItem(
                        index: 0,
                        icon: Icons.cake_outlined,
                        activeIcon: Icons.cake_rounded,
                        label: settings.tr('birthdays'),
                        badgeCount: 0,
                      ),
                    ),

                    // Item 2: Contacts
                    Expanded(
                      child: _buildNavItem(
                        index: 1,
                        icon: Icons.people_alt_outlined,
                        activeIcon: Icons.people_alt_rounded,
                        label: settings.tr('contacts'),
                        badgeCount: 0,
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Central Floating Action Button (Elevated + Gradient)
          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: () {
                context.push('/birthday/new');
              },
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1), // Indigo
                      Color(0xFFA855F7), // Purple / Violet
                      Color(0xFFEC4899), // Pink / Magenta
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isDark ? const Color(0xFF0C1322) : Colors.white,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.55),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 32,
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
  }) {
    final bool isSelected = _currentIndex == index;
    const activeColor = Color(0xFF38BDF8); // Cyan highlight from screenshot
    final inactiveColor = Colors.white.withValues(alpha: 0.58);

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
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(isSelected ? 1.15 : 1.0),
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
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
