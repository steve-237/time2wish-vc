import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../birthdays/presentation/birthday_list_screen.dart';
import '../profile/presentation/profile_screen.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BirthdayListScreen(),
    const ContactsPlaceholder(),
    const MessagingPlaceholder(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
          border: const Border(
            top: BorderSide(color: Colors.white10, width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF38BDF8),
          unselectedItemColor: AppColors.textMutedDark,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.cake_outlined),
              activeIcon: Icon(Icons.cake, color: Color(0xFF38BDF8)),
              label: 'Anniversaires',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group, color: Color(0xFF38BDF8)),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble, color: Color(0xFF38BDF8)),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: Color(0xFF38BDF8)),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class ContactsPlaceholder extends StatelessWidget {
  const ContactsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 64, color: AppColors.textMutedDark),
          SizedBox(height: 16),
          Text(
            'Liste des Contacts',
            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Vos contacts synchronisés s\'afficheront ici', style: TextStyle(color: AppColors.textMutedDark)),
        ],
      ),
    );
  }
}

class MessagingPlaceholder extends StatelessWidget {
  const MessagingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble, size: 64, color: AppColors.textMutedDark),
          SizedBox(height: 16),
          Text(
            'Messagerie STOMP',
            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Vos discussions de groupe et salons secrets', style: TextStyle(color: AppColors.textMutedDark)),
        ],
      ),
    );
  }
}
