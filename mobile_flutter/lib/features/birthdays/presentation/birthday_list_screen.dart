import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_image.dart';
import 'ai_wish_dialog.dart';
import 'ai_gift_sheet.dart';
import 'reminder_settings_sheet.dart';
import 'birthday_import_export_sheet.dart';

class BirthdayListScreen extends StatefulWidget {
  const BirthdayListScreen({super.key});

  @override
  State<BirthdayListScreen> createState() => _BirthdayListScreenState();
}

class _BirthdayListScreenState extends State<BirthdayListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'TOUS';

  final List<String> _categories = ['TOUS', 'CE_MOIS', 'FAVORIS', 'AMIS', 'FAMILLE', 'TRAVAIL'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BirthdayService>().fetchBirthdays();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BirthdayModel> _getFilteredBirthdays(List<BirthdayModel> birthdays) {
    final now = DateTime.now();
    final result = birthdays.where((b) {
      final matchesSearch = _searchQuery.isEmpty ||
          b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.interests.any((i) => i.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      if (_selectedCategory == 'FAVORIS') return b.isFavorite;
      if (_selectedCategory == 'CE_MOIS') return b.birthdate.month == now.month;
      if (_selectedCategory != 'TOUS') return b.category.toUpperCase() == _selectedCategory;
      return true;
    }).toList();

    result.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return result;
  }

  void _showLanguageSelector(BuildContext context, SettingsService settings) {
    final isDark = settings.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.language_rounded, color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, size: 22),
                const SizedBox(width: 10),
                Text(
                  settings.tr('select_language'),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textMainLight,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLangTile(ctx, settings, 'fr', 'Français', '🇫🇷', isDark),
            _buildLangTile(ctx, settings, 'en', 'English', '🇬🇧', isDark),
            _buildLangTile(ctx, settings, 'de', 'Deutsch', '🇩🇪', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLangTile(BuildContext ctx, SettingsService settings, String code, String label, String flag, bool isDark) {
    final isSelected = settings.language == code;
    final primary = isDark ? AppColors.indigoLight : AppColors.primaryIndigo;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? primary.withValues(alpha: 0.12) : Colors.transparent,
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? primary : (isDark ? Colors.white : AppColors.textMainLight),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: primary, size: 20)
          : null,
      onTap: () {
        settings.setLanguage(code);
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$flag Langue : $label'),
            backgroundColor: primary,
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  void _showNotificationSheet(BuildContext context, BirthdayService birthdayService, SettingsService settings) {
    final upcomingList = birthdayService.upcoming.take(5).toList();
    final isDark = settings.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rappels & Notifications',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textMainLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (upcomingList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text(
                    'Aucun rappel pour le moment.',
                    style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: upcomingList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final b = upcomingList[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: Center(
                              child: Text(
                                b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.name,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.textMainLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  b.isToday
                                      ? '🎉 C\'est son anniversaire aujourd\'hui !'
                                      : 'Dans ${b.daysRemaining} jours 🎂',
                                  style: TextStyle(
                                    color: b.isToday
                                        ? AppColors.accentCoral
                                        : (isDark ? AppColors.cyanLight : AppColors.primaryCyan),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.push('/birthday/${b.id}');
                            },
                            child: Text(
                              settings.tr('see_details'),
                              style: TextStyle(
                                color: isDark ? AppColors.cyanLight : AppColors.primaryCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ReminderSettingsSheet.show(context);
                },
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text(
                  'Configurer les rappels & push ⚙️',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBirthdayQuickActionsModal(
    BuildContext context,
    BirthdayModel birthday,
    SettingsService settings,
    ApiService apiService,
    BirthdayService birthdayService,
  ) {
    final isDark = settings.isDarkMode;
    final localeStr = settings.language == 'en' ? 'en_US' : (settings.language == 'de' ? 'de_DE' : 'fr_FR');
    final initial = birthday.name.isNotEmpty ? birthday.name[0].toUpperCase() : '?';

    Color categoryColor;
    switch (birthday.category.toUpperCase()) {
      case 'FAMILLE':
        categoryColor = AppColors.accentCoral;
        break;
      case 'TRAVAIL':
        categoryColor = AppColors.accentEmerald;
        break;
      case 'AMIS':
        categoryColor = isDark ? AppColors.indigoLight : AppColors.primaryIndigo;
        break;
      default:
        categoryColor = isDark ? AppColors.cyanLight : AppColors.primaryCyan;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Profile Header Card
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.7),
                      width: 2.5,
                    ),
                  ),
                  child: birthday.photoUrl != null && birthday.photoUrl!.isNotEmpty
                      ? ClipOval(
                          child: AvatarImage(
                            photoUrl: birthday.photoUrl!,
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            fallback: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        birthday.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textMainLight,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              birthday.category,
                              style: TextStyle(
                                color: categoryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· ${birthday.nextAge} ${settings.tr('turning_age')} · ${DateFormat('d MMMM', localeStr).format(birthday.birthdate)}',
                            style: TextStyle(
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: birthday.isToday
                        ? AppColors.accentCoral.withValues(alpha: 0.15)
                        : (birthday.daysRemaining <= 7
                            ? AppColors.wishCoinsAmber.withValues(alpha: 0.14)
                            : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: birthday.isToday
                          ? AppColors.accentCoral.withValues(alpha: 0.4)
                          : (birthday.daysRemaining <= 7
                              ? AppColors.wishCoinsAmber.withValues(alpha: 0.3)
                              : Colors.transparent),
                    ),
                  ),
                  child: Text(
                    birthday.isToday
                        ? '🎂 ${settings.tr('today')}'
                        : (birthday.daysRemaining <= 1
                            ? settings.tr('in_day')
                            : '${settings.tr('in_days')} ${birthday.daysRemaining} j'),
                    style: TextStyle(
                      color: birthday.isToday
                          ? AppColors.accentCoral
                          : (birthday.daysRemaining <= 7
                              ? AppColors.wishCoinsAmber
                              : (isDark ? AppColors.cyanLight : AppColors.primaryIndigo)),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action 1: AI Wish Generator
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                AiWishDialog.show(context, birthday.id, apiService);
              },
              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              label: Text(
                'Générer un vœu IA pour ${birthday.name} ✨',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),

            // Action 2: AI Gift Ideas
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: AppColors.wishCoinsAmber.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                backgroundColor: AppColors.wishCoinsAmber.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                AiGiftSheet.show(context, birthday);
              },
              icon: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.wishCoinsAmber, size: 18),
              label: Text(
                'Idées cadeaux IA pour ${birthday.name} 💡',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textMainLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),

            // Action 3: View Full Details Screen
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.0,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final targetId = birthday.id;
                Navigator.of(ctx).pop();
                GoRouter.of(context).push('/birthday/$targetId');
              },
              icon: Icon(
                Icons.assignment_outlined,
                color: isDark ? AppColors.cyanLight : AppColors.primaryCyan,
                size: 18,
              ),
              label: Text(
                'Voir la fiche complète & liste de cadeaux 📋',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textMainLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Action 4: Edit & Favorite Quick Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/birthday/${birthday.id}/edit');
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Modifier ✏️', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: BorderSide(
                        color: birthday.isFavorite
                            ? AppColors.wishCoinsAmber
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      birthdayService.toggleFavorite(birthday.id);
                      Navigator.pop(ctx);
                    },
                    icon: Icon(
                      birthday.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.wishCoinsAmber,
                      size: 18,
                    ),
                    label: Text(
                      birthday.isFavorite ? 'En favori ⭐' : 'Ajouter favori',
                      style: TextStyle(
                        color: birthday.isFavorite ? AppColors.wishCoinsAmber : null,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWishCoinsModal(BuildContext context, int coins) {
    final settings = Provider.of<SettingsService>(context, listen: false);
    final isDark = settings.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.wishCoinsAmber.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.monetization_on, color: AppColors.wishCoinsAmber, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'WishCoins',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textMainLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.wishCoinsAmber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.wishCoinsAmber.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '$coins WishCoins 🪙',
                  style: const TextStyle(
                    color: AppColors.wishCoinsAmber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Avantages de vos WishCoins :',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textMainLight,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            _buildCoinPerk('✨ Vœux IA personnalisés', '1 crédit / vœu généré', isDark),
            const SizedBox(height: 6),
            _buildCoinPerk('💡 Idées cadeaux ciblées', 'Analyses de profils exclusives', isDark),
            const SizedBox(height: 6),
            _buildCoinPerk('🎁 Cagnottes collectives', 'Rechargement quotidien gratuit', isDark),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Compris', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinPerk(String title, String subtitle, bool isDark) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$title : ',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textMainLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: subtitle,
                  style: TextStyle(
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleManualSync(
    BuildContext context,
    SyncService syncService,
    BirthdayService birthdayService,
    SettingsService settings,
  ) async {
    final isDark = settings.isDarkMode;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Synchronisation en cours...'),
          ],
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkCardElevated : const Color(0xFF1E293B),
      ),
    );

    bool syncOk = true;
    if (syncService.hasPending) {
      syncOk = await syncService.syncAll();
    }
    await birthdayService.fetchBirthdays();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (syncOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 20),
              SizedBox(width: 10),
              Text('✓ Synchronisation terminée avec succès !'),
            ],
          ),
          backgroundColor: isDark ? AppColors.darkCardElevated : const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.wishCoinsAmber, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Synchronisé en local (serveur distant indisponible)')),
            ],
          ),
          action: SnackBarAction(
            label: 'Vider',
            textColor: AppColors.accentCoral,
            onPressed: () => syncService.clearQueue(),
          ),
          backgroundColor: isDark ? AppColors.darkCardElevated : const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final birthdayService = Provider.of<BirthdayService>(context);
    final syncService = Provider.of<SyncService>(context);
    final settings = Provider.of<SettingsService>(context);
    final apiService = Provider.of<ApiService>(context, listen: false);

    final user = authService.currentUser;
    final isDark = settings.isDarkMode;

    final filtered = _getFilteredBirthdays(birthdayService.upcoming);
    final BirthdayModel? nextBirthday = birthdayService.upcoming.isNotEmpty ? birthdayService.upcoming.first : null;

    final totalCount = birthdayService.birthdays.length;
    final urgentCount = birthdayService.birthdays.where((b) => b.daysRemaining <= 7).length;
    final firstName = user?.fullName.split(' ').first ?? 'Ami';

    final String langFlag = settings.language == 'en'
        ? '🇬🇧'
        : settings.language == 'de'
            ? '🇩🇪'
            : '🇫🇷';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      body: RefreshIndicator(
        color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        onRefresh: () async {
          if (syncService.hasPending) {
            await syncService.syncAll();
          }
          await birthdayService.fetchBirthdays();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. TOP EXECUTIVE HEADER WITH USER GREETING & UTILITIES
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // User Greeting & Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time2Wish',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.textMainLight,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bienvenue $firstName 👋',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Right header accessories
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // WishCoins chip
                        GestureDetector(
                          onTap: () => _showWishCoinsModal(context, user?.coins ?? 100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.wishCoinsAmber.withValues(alpha: isDark ? 0.16 : 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.wishCoinsAmber.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on, color: AppColors.wishCoinsAmber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${user?.coins ?? 100}',
                                  style: const TextStyle(
                                    color: AppColors.wishCoinsAmber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Language switcher chip
                        GestureDetector(
                          onTap: () => _showLanguageSelector(context, settings),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(langFlag, style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(
                                  settings.language.toUpperCase(),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.textMainLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Notification Bell
                        GestureDetector(
                          onTap: () => _showNotificationSheet(context, birthdayService, settings),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  color: isDark ? Colors.white : AppColors.textMainLight,
                                  size: 19,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentCoral,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Manual Sync Button
                        GestureDetector(
                          onTap: () => _handleManualSync(context, syncService, birthdayService, settings),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: syncService.isSyncing
                                  ? SpinKitRing(color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, size: 16, lineWidth: 2)
                                  : Icon(
                                      Icons.sync_rounded,
                                      color: isDark ? Colors.white : AppColors.textMainLight,
                                      size: 19,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Import / Export JSON Backup Button
                        GestureDetector(
                          onTap: () => BirthdayImportExportSheet.show(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.sync_alt_rounded,
                                color: isDark ? AppColors.cyanLight : AppColors.primaryCyan,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. VIBRANT STAT METRICS ROW (MATCHING EXECUTIVE DESIGN MOCKUP)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    // Stat 1: Total Suivis
                    Expanded(
                      child: _buildVibrantStatCard(
                        context: context,
                        isDark: isDark,
                        isSelected: _selectedCategory == 'TOUS',
                        icon: Icons.cake_rounded,
                        value: '$totalCount',
                        label: 'Total',
                        iconColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        iconBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                        onTap: () {
                          DeviceService.triggerLightHaptic();
                          setState(() => _selectedCategory = 'TOUS');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Stat 2: Prochain Anniversaire - Compte à rebours J-X
                    Expanded(
                      child: _buildVibrantStatCard(
                        context: context,
                        isDark: isDark,
                        isSelected: false,
                        icon: Icons.timer_rounded,
                        value: nextBirthday != null
                            ? (nextBirthday.isToday ? 'Jour J !' : '${nextBirthday.daysRemaining} j')
                            : '--',
                        label: nextBirthday != null ? 'Prochain : ${nextBirthday.name.split(' ').first}' : 'Prochain : --',
                        iconColor: const Color(0xFF06B6D4),
                        iconBgColor: isDark ? const Color(0xFF0E2F3E) : const Color(0xFFCFFAFE),
                        onTap: () {
                          if (nextBirthday != null) {
                            DeviceService.triggerLightHaptic();
                            context.push('/birthday/${nextBirthday.id}');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Stat 3: À Souhaiter Bientôt (< 7 jours)
                    Expanded(
                      child: _buildVibrantStatCard(
                        context: context,
                        isDark: isDark,
                        isSelected: false,
                        icon: Icons.bolt_rounded,
                        value: '$urgentCount',
                        label: 'Dans 7 jours',
                        iconColor: const Color(0xFFF59E0B),
                        iconBgColor: isDark ? const Color(0xFF332612) : const Color(0xFFFEF3C7),
                        onTap: () {
                          DeviceService.triggerLightHaptic();
                          setState(() => _selectedCategory = 'TOUS');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. SMART CELEBRATION HUB (STUDIO IA EXPRESS & HORIZON TIMELINE)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131826) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF222B3E) : AppColors.lightBorder,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Title Pill + WishCoins/Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Studio IA Célébrations',
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppColors.textMainLight,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.wishCoinsAmber.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on, color: AppColors.wishCoinsAmber, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  '${user?.coins ?? 100} Coins',
                                  style: const TextStyle(
                                    color: AppColors.wishCoinsAmber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (nextBirthday != null) ...[
                        // Context row: Focus on next birthday
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            DeviceService.triggerLightHaptic();
                            context.push('/birthday/${nextBirthday.id}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                // Small avatar
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
                                  ),
                                  child: nextBirthday.photoUrl != null && nextBirthday.photoUrl!.isNotEmpty
                                      ? ClipOval(child: AvatarImage(photoUrl: nextBirthday.photoUrl!, width: 38, height: 38, fit: BoxFit.cover))
                                      : Center(
                                          child: Text(
                                            nextBirthday.name.isNotEmpty ? nextBirthday.name[0].toUpperCase() : '?',
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
                                        'Générer un vœu pour ${nextBirthday.name}',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : AppColors.textMainLight,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        nextBirthday.isToday
                                            ? '🎉 C\'est son anniversaire aujourd\'hui !'
                                            : 'Dans ${nextBirthday.daysRemaining} jours · Fête ses ${nextBirthday.nextAge} ans',
                                        style: TextStyle(
                                          color: nextBirthday.isToday ? AppColors.accentCoral : (isDark ? AppColors.cyanLight : const Color(0xFF0284C7)),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white38),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Fast Tone Chips: Touch once to generate wish in that tone
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildQuickToneChip(
                                context: context,
                                label: '🎉 Festif',
                                color: const Color(0xFF06B6D4),
                                isDark: isDark,
                                onTap: () => AiWishDialog.show(context, nextBirthday.id, apiService, initialTone: 'AMICAL'),
                              ),
                              const SizedBox(width: 8),
                              _buildQuickToneChip(
                                context: context,
                                label: '😂 Humour',
                                color: const Color(0xFFF59E0B),
                                isDark: isDark,
                                onTap: () => AiWishDialog.show(context, nextBirthday.id, apiService, initialTone: 'HUMORISTIQUE'),
                              ),
                              const SizedBox(width: 8),
                              _buildQuickToneChip(
                                context: context,
                                label: '💌 Émouvant',
                                color: const Color(0xFFA855F7),
                                isDark: isDark,
                                onTap: () => AiWishDialog.show(context, nextBirthday.id, apiService, initialTone: 'POETIQUE'),
                              ),
                              const SizedBox(width: 8),
                              _buildQuickToneChip(
                                context: context,
                                label: '👔 Formel',
                                color: const Color(0xFF3B82F6),
                                isDark: isDark,
                                onTap: () => AiWishDialog.show(context, nextBirthday.id, apiService, initialTone: 'FORMEL'),
                              ),
                              const SizedBox(width: 8),
                              _buildQuickToneChip(
                                context: context,
                                label: '💡 Idées Cadeaux',
                                color: AppColors.wishCoinsAmber,
                                isDark: isDark,
                                isGift: true,
                                onTap: () => AiGiftSheet.show(context, nextBirthday),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.celebration_rounded, color: AppColors.wishCoinsAmber, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Aucun anniversaire prévu pour le moment. Ajoutez des contacts pour débloquer les inspirations IA.',
                                  style: TextStyle(
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Horizon Mini Timeline (if multiple upcoming birthdays)
                      if (birthdayService.upcoming.length > 1) ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Colors.white12),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Horizon des prochains jours',
                              style: TextStyle(
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              '${birthdayService.upcoming.length} suivis',
                              style: TextStyle(
                                color: isDark ? AppColors.cyanLight : AppColors.primaryCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: birthdayService.upcoming.take(6).map((b) {
                              final isNext = b.id == nextBirthday?.id;
                              return GestureDetector(
                                onTap: () {
                                  DeviceService.triggerLightHaptic();
                                  context.push('/birthday/${b.id}');
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isNext
                                        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                                        : (isDark ? const Color(0xFF161C28) : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isNext
                                          ? (isDark ? AppColors.cyanLight : AppColors.primaryCyan).withValues(alpha: 0.5)
                                          : (isDark ? const Color(0xFF222B3E) : AppColors.lightBorder),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: AppColors.primaryGradient,
                                        ),
                                        child: Center(
                                          child: Text(
                                            b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        b.name.split(' ').first,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : AppColors.textMainLight,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        b.isToday ? '🎉' : '${b.daysRemaining}j',
                                        style: TextStyle(
                                          color: b.isToday ? AppColors.accentCoral : (isDark ? AppColors.cyanLight : const Color(0xFF0284C7)),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // 4. OFFLINE SYNC BANNER (IF PENDING)
            if (syncService.hasPending)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.wishCoinsAmber.withValues(alpha: isDark ? 0.35 : 0.5),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.wishCoinsAmber.withValues(alpha: isDark ? 0.12 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.wishCoinsAmber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: syncService.isSyncing
                              ? const SpinKitRing(color: AppColors.wishCoinsAmber, size: 14, lineWidth: 2)
                              : const Icon(Icons.cloud_sync, color: AppColors.wishCoinsAmber, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            syncService.isSyncing
                                ? 'Synchronisation en cours...'
                                : '${syncService.pendingCount} ${settings.tr('sync_pending')}',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textMainLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!syncService.isSyncing) ...[
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _handleManualSync(context, syncService, birthdayService, settings),
                            child: Text(
                              settings.tr('sync_now'),
                              style: TextStyle(
                                color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () async {
                              await syncService.clearQueue();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('File de synchronisation vidée avec succès !'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Vider',
                              style: TextStyle(
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // 5. SEARCH & FILTER SECTION
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Modern Search Bar
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textMainLight,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: settings.tr('search_hint'),
                                hintStyle: TextStyle(
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Filter Pills Horizontal Row
                    SizedBox(
                      height: 34,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;

                          String label;
                          switch (cat) {
                            case 'CE_MOIS':
                              label = settings.tr('this_month');
                              break;
                            case 'FAVORIS':
                              label = settings.tr('filter_favorites');
                              break;
                            case 'AMIS':
                              label = settings.tr('filter_friends');
                              break;
                            case 'FAMILLE':
                              label = settings.tr('filter_family');
                              break;
                            case 'TRAVAIL':
                              label = settings.tr('filter_work');
                              break;
                            default:
                              label = settings.tr('filter_all');
                          }

                          final primaryColor = isDark ? AppColors.indigoLight : AppColors.primaryIndigo;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? AppColors.darkCard : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryColor
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. MAIN CELEBRATIONS LIST
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
              sliver: filtered.isEmpty
                  ? SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cake_outlined,
                              size: 48,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              settings.tr('no_birthdays'),
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textMainLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              settings.tr('no_birthdays_sub'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                fontSize: 13,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty || _selectedCategory != 'TOUS') ...[
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedCategory = 'TOUS';
                                    _searchController.clear();
                                  });
                                },
                                child: Text(
                                  settings.tr('view_all'),
                                  style: TextStyle(
                                    color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (itemContext, index) {
                          final birthday = filtered[index];
                          return Padding(
                            key: ValueKey('birthday_card_${birthday.id}'),
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: _buildCelebrationListItem(
                              context: context,
                              birthday: birthday,
                              birthdayService: birthdayService,
                              settings: settings,
                              apiService: apiService,
                              isDark: isDark,
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickToneChip({
    required BuildContext context,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool isGift = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        DeviceService.playTapSound();
        DeviceService.triggerLightHaptic();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGift) ...[
              Icon(Icons.lightbulb_rounded, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textMainLight,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibrantStatCard({
    required BuildContext context,
    required bool isDark,
    required bool isSelected,
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? iconBgColor,
    Color? textColor,
    Color? labelColor,
  }) {
    final effectiveIconBg = iconBgColor ?? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE));
    final effectiveIconColor = iconColor ?? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));
    final effectiveTextColor = textColor ?? (isDark ? Colors.white : AppColors.textMainLight);
    final effectiveLabelColor = labelColor ?? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight);

    final effectiveBorder = Border.all(
      color: isSelected
          ? (isDark ? const Color(0xFF3B82F6) : AppColors.primaryIndigo)
          : (isDark ? const Color(0xFF222B3E) : AppColors.lightBorder),
      width: isSelected ? 1.8 : 1.0,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 118,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131826) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: effectiveBorder,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top left squircle icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: effectiveIconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),

            // Metric number & label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: effectiveLabelColor,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationListItem({
    required BuildContext context,
    required BirthdayModel birthday,
    required BirthdayService birthdayService,
    required SettingsService settings,
    required ApiService apiService,
    required bool isDark,
  }) {
    final initial = birthday.name.isNotEmpty ? birthday.name[0].toUpperCase() : '?';

    Color categoryColor;
    switch (birthday.category.toUpperCase()) {
      case 'FAMILLE':
        categoryColor = AppColors.accentCoral;
        break;
      case 'TRAVAIL':
        categoryColor = AppColors.accentEmerald;
        break;
      case 'AMIS':
        categoryColor = isDark ? AppColors.indigoLight : AppColors.primaryIndigo;
        break;
      default:
        categoryColor = isDark ? AppColors.cyanLight : AppColors.primaryCyan;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: birthday.isToday
              ? AppColors.accentCoral.withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF232D3F) : AppColors.lightBorder),
          width: birthday.isToday ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            DeviceService.triggerLightHaptic();
            context.push('/birthday/${birthday.id}');
          },
          onLongPress: () {
            DeviceService.triggerMediumHaptic();
            _showBirthdayQuickActionsModal(
              context,
              birthday,
              settings,
              apiService,
              birthdayService,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar with clean neutral border
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    border: Border.all(
                      color: isDark ? const Color(0xFF2D3748) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: birthday.photoUrl != null && birthday.photoUrl!.isNotEmpty
                      ? ClipOval(
                          child: AvatarImage(
                            photoUrl: birthday.photoUrl!,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            fallback: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Name, Category & Age
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              birthday.name,
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textMainLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              birthday.category,
                              style: TextStyle(
                                color: categoryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· ${birthday.nextAge} ${settings.tr('turning_age')}',
                            style: TextStyle(
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Countdown Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: birthday.isToday
                        ? AppColors.accentCoral.withValues(alpha: 0.15)
                        : (birthday.daysRemaining <= 7
                            ? AppColors.wishCoinsAmber.withValues(alpha: 0.14)
                            : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: birthday.isToday
                          ? AppColors.accentCoral.withValues(alpha: 0.4)
                          : (birthday.daysRemaining <= 7
                              ? AppColors.wishCoinsAmber.withValues(alpha: 0.3)
                              : Colors.transparent),
                    ),
                  ),
                  child: Text(
                    birthday.isToday
                        ? '🎂 ${settings.tr('today')}'
                        : (birthday.daysRemaining <= 1
                            ? settings.tr('in_day')
                            : '${settings.tr('in_days')} ${birthday.daysRemaining} j'),
                    style: TextStyle(
                      color: birthday.isToday
                          ? AppColors.accentCoral
                          : (birthday.daysRemaining <= 7
                              ? AppColors.wishCoinsAmber
                              : (isDark ? AppColors.cyanLight : AppColors.primaryIndigo)),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Quick AI Wish Action Button (directly on row)
                IconButton(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                  tooltip: 'Vœu IA pour ${birthday.name}',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  onPressed: () {
                    AiWishDialog.show(context, birthday.id, apiService);
                  },
                ),

                // Favorite Toggle Button
                IconButton(
                  icon: Icon(
                    birthday.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: birthday.isFavorite ? AppColors.wishCoinsAmber : (isDark ? Colors.white24 : Colors.black26),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  onPressed: () => birthdayService.toggleFavorite(birthday.id),
                ),

                // Direct Navigation to Details Screen
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: () {
                    DeviceService.triggerLightHaptic();
                    context.push('/birthday/${birthday.id}');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
