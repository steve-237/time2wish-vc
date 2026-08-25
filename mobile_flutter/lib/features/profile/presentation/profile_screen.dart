import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glowing_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(color: AppColors.textMutedDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textMutedDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              authService.logout();
              context.go('/login');
            },
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            // Profile Header Card
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryCyan.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  GlowingBadge(
                    label: '${user.planType} MEMBER',
                    icon: Icons.workspace_premium,
                    color: AppColors.accentPurple,
                    isSelected: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Row Cards
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
                    iconColor: AppColors.primaryCyan,
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

            const SizedBox(height: 28),

            // Menu Section
            const Text(
              'Paramètres du compte',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: AppColors.primaryCyan),
                    title: const Text('Modifier le profil', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMutedDark),
                    onTap: () => context.push('/profile/edit'),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined, color: AppColors.accentPurple),
                    title: const Text('Notifications locales', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Actives (J-7, J-3, Jour J)', style: TextStyle(color: AppColors.textMutedDark, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMutedDark),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rappels locaux actifs 🔔'),
                          backgroundColor: AppColors.primaryCyan,
                        ),
                      );
                    },
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined, color: AppColors.wishCoinsAmber),
                    title: const Text('Mode sombre Glassmorphic', style: TextStyle(color: Colors.white)),
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeTrackColor: AppColors.primaryCyan,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            GlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white70),
                title: const Text('Version de l\'application', style: TextStyle(color: Colors.white)),
                trailing: const Text('1.8.0 (Offline-First)', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPink.withValues(alpha: 0.15),
                foregroundColor: AppColors.accentPink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.accentPink.withValues(alpha: 0.4)),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () => _showLogoutDialog(context, authService),
            ),
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
          Icon(icon, color: iconColor, size: 26),
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
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
