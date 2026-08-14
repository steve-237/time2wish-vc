import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(color: AppColors.textMutedDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              authService.logout();
              context.go('/login');
            },
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanBadge(String? planType) {
    Color badgeColor;
    String badgeText;
    switch (planType?.toUpperCase()) {
      case 'PREMIUM':
        badgeColor = AppColors.accentPurple;
        badgeText = 'PREMIUM';
        break;
      case 'PLUS':
        badgeColor = AppColors.primaryBlue;
        badgeText = 'PLUS';
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = 'BASIC';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final birthdayService = context.watch<BirthdayService>();
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    final String initial = user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Hero Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.accentPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.textMutedDark,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPlanBadge(user.planType),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total',
                    value: '${birthdayService.birthdays.length}',
                    icon: Icons.cake,
                    iconColor: AppColors.accentPink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Ce mois',
                    value: '${birthdayService.upcomingThisMonth}',
                    icon: Icons.calendar_month,
                    iconColor: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'WishCoins',
                    value: '${user.coins}',
                    icon: Icons.monetization_on,
                    iconColor: AppColors.wishCoinsAmber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Menu
            const Text(
              'Général',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.white),
                    title: const Text('Modifier le profil', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMutedDark),
                    onTap: () => context.push('/profile/edit'),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.white),
                    title: const Text('Notifications', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMutedDark),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Bientôt disponible'),
                          backgroundColor: AppColors.accentPurple.withValues(alpha: 0.8),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                  ListTile(
                    leading: const Icon(Icons.dark_mode, color: Colors.white),
                    title: const Text('Thème sombre', style: TextStyle(color: Colors.white)),
                    trailing: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeColor: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Autre',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text('Version', style: TextStyle(color: Colors.white)),
                trailing: const Text('1.0.0', style: TextStyle(color: AppColors.textMutedDark)),
              ),
            ),
            const SizedBox(height: 32),

            // Logout
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.2),
                foregroundColor: Colors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () => _showLogoutDialog(context, authService),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMutedDark,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
