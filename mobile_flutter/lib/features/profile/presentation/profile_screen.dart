import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glowing_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, AuthService authService, SettingsService settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundDialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(settings.tr('logout'), style: const TextStyle(color: Colors.white)),
        content: Text(
          settings.language == 'en'
              ? 'Are you sure you want to log out?'
              : settings.language == 'de'
                  ? 'Möchten Sie sich wirklich abmelden?'
                  : 'Voulez-vous vraiment vous déconnecter ?',
          style: const TextStyle(color: AppColors.textMutedDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(settings.tr('cancel'), style: const TextStyle(color: AppColors.textMutedDark)),
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
            child: Text(settings.tr('logout'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final birthdayService = context.watch<BirthdayService>();
    final settings = context.watch<SettingsService>();
    final user = authService.currentUser;
    final isDark = settings.isDarkMode;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            'Utilisateur non trouvé',
            style: TextStyle(color: AppColors.textMutedDark, fontSize: 16),
          ),
        ),
      );
    }

    final String initial = user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // Profile Header Card
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, animVal, child) => Transform.scale(
                      scale: 0.8 + (0.2 * animVal),
                      child: Opacity(
                        opacity: animVal,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: const [
                                AppColors.primaryCyan,
                                AppColors.accentPurple,
                                AppColors.accentPink,
                                AppColors.primaryCyan,
                              ],
                              transform: GradientRotation(animVal * 3.14),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? AppColors.backgroundDark : Colors.white,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryCyan.withValues(alpha: 0.35),
                                        blurRadius: 18,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.fullName,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textMainLight,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      fontSize: 13,
                    ),
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

            const SizedBox(height: 18),

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
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    title: settings.language == 'en'
                        ? 'This Month'
                        : settings.language == 'de'
                            ? 'Diesen Monat'
                            : 'Ce mois',
                    value: '${birthdayService.upcomingThisMonth}',
                    icon: Icons.calendar_month,
                    iconColor: AppColors.primaryCyan,
                  ),
                ),
                const SizedBox(width: 10),
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

            const SizedBox(height: 24),

            // --- SECTION 1: LANGUE & AFFICHAGE (PROMINENT LANGUAGE SELECTOR) ---
            Text(
              settings.tr('language'),
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textMainLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, color: AppColors.primaryCyan, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        settings.tr('select_language'),
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textMainLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 3 Interactive Language Selector Pills
                  Row(
                    children: [
                      Expanded(
                        child: _LanguageOptionCard(
                          code: 'fr',
                          label: 'Français',
                          flag: '🇫🇷',
                          isSelected: settings.language == 'fr',
                          onTap: () => settings.setLanguage('fr'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _LanguageOptionCard(
                          code: 'en',
                          label: 'English',
                          flag: '🇬🇧',
                          isSelected: settings.language == 'en',
                          onTap: () => settings.setLanguage('en'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _LanguageOptionCard(
                          code: 'de',
                          label: 'Deutsch',
                          flag: '🇩🇪',
                          isSelected: settings.language == 'de',
                          onTap: () => settings.setLanguage('de'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- SECTION 2: APPARENCE & THÈME (DARK / LIGHT THEME TOGGLE) ---
            Text(
              settings.tr('appearance'),
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textMainLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            GlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? AppColors.wishCoinsAmber : Colors.orangeAccent,
                ),
                title: Text(
                  isDark ? settings.tr('dark_mode') : settings.tr('light_mode'),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textMainLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => settings.toggleDarkMode(),
                  activeTrackColor: AppColors.primaryCyan,
                  activeThumbColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- SECTION 3: COMPTE & PARAMÈTRES ---
            Text(
              settings.tr('settings'),
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textMainLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_rounded, color: AppColors.primaryCyan),
                    title: Text(
                      settings.language == 'en'
                          ? 'Edit Profile'
                          : settings.language == 'de'
                              ? 'Profil bearbeiten'
                              : 'Modifier le profil',
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMutedDark),
                    onTap: () => context.push('/profile/edit'),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined, color: AppColors.accentPurple),
                    title: Text(
                      settings.language == 'en'
                          ? 'Notifications & Reminders'
                          : settings.language == 'de'
                              ? 'Benachrichtigungen'
                              : 'Notifications locales',
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
                    ),
                    subtitle: Text(
                      settings.language == 'en'
                          ? 'Active (D-7, D-3, D-Day)'
                          : settings.language == 'de'
                              ? 'Aktiv (T-7, T-3, Tag X)'
                              : 'Actives (J-7, J-3, Jour J)',
                      style: const TextStyle(color: AppColors.textMutedDark, fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMutedDark),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rappels locaux programmés (J-7, J-3, Jour J) 🔔'),
                          backgroundColor: AppColors.primaryCyan,
                        ),
                      );
                    },
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.white70),
                    title: Text(
                      settings.language == 'en'
                          ? 'App Version'
                          : settings.language == 'de'
                              ? 'App-Version'
                              : 'Version de l\'application',
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
                    ),
                    trailing: const Text(
                      'v1.9.2 (Offline & WebSockets)',
                      style: TextStyle(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPink.withValues(alpha: 0.15),
                foregroundColor: AppColors.accentPink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.accentPink.withValues(alpha: 0.4)),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: Text(
                settings.tr('logout'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showLogoutDialog(context, authService, settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  final String code;
  final String label;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOptionCard({
    required this.code,
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryCyan.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryCyan : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryCyan.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textMutedDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              const Icon(Icons.check_circle, color: AppColors.primaryCyan, size: 14),
            ],
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
    final settings = context.watch<SettingsService>();
    final isDark = settings.isDarkMode;

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMutedDark,
            ),
          ),
        ],
      ),
    );
  }
}
