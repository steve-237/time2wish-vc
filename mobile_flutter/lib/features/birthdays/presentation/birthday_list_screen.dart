import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_image.dart';
import 'ai_wish_dialog.dart';
import 'ai_gift_sheet.dart';

class BirthdayListScreen extends StatefulWidget {
  const BirthdayListScreen({super.key});

  @override
  State<BirthdayListScreen> createState() => _BirthdayListScreenState();
}

class _BirthdayListScreenState extends State<BirthdayListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'TOUS';
  int? _selectedBirthdayId;

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
                Navigator.pop(ctx);
                context.push('/birthday/${birthday.id}');
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final birthdayService = Provider.of<BirthdayService>(context);
    final syncService = Provider.of<SyncService>(context);
    final settings = Provider.of<SettingsService>(context);
    final apiService = Provider.of<ApiService>(context, listen: false);

    final user = authService.currentUser;
    final isDark = settings.isDarkMode;
    final localeStr = settings.language == 'en' ? 'en_US' : (settings.language == 'de' ? 'de_DE' : 'fr_FR');

    final filtered = _getFilteredBirthdays(birthdayService.upcoming);
    final BirthdayModel? nextBirthday = birthdayService.upcoming.isNotEmpty ? birthdayService.upcoming.first : null;
    final BirthdayModel? activeBirthday = (_selectedBirthdayId != null
        ? birthdayService.getBirthdayById(_selectedBirthdayId!)
        : null) ?? nextBirthday;
    final bool isCustomSelection = _selectedBirthdayId != null && activeBirthday != null && activeBirthday.id != nextBirthday?.id;

    final now = DateTime.now();
    final thisMonthCount = birthdayService.birthdays.where((b) => b.birthdate.month == now.month).length;
    final totalCount = birthdayService.birthdays.length;
    final favoritesCount = birthdayService.birthdays.where((b) => b.isFavorite).length;

    // Greeting by time of day
    final hour = now.hour;
    final greetingWord = (hour >= 5 && hour < 18)
        ? settings.tr('greeting_morning')
        : settings.tr('greeting_evening');
    final firstName = user?.fullName.split(' ').first ?? 'Ami';

    // Localized date header
    final dateRaw = DateFormat('EEEE d MMMM', localeStr).format(now);
    final dateTodayFormatted = dateRaw.isNotEmpty ? dateRaw[0].toUpperCase() + dateRaw.substring(1) : dateRaw;

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
                            dateTodayFormatted,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$greetingWord, $firstName 👋',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textMainLight,
                              letterSpacing: -0.4,
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
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. HERO SPOTLIGHT CARD: PROCHAIN ANNIVERSAIRE OU ANNIVERSAIRE SÉLECTIONNÉ
            if (activeBirthday != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: activeBirthday.isToday
                            ? AppColors.accentCoral.withValues(alpha: 0.5)
                            : (isCustomSelection
                                ? (isDark ? AppColors.cyanLight : AppColors.primaryCyan).withValues(alpha: 0.6)
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                        width: (activeBirthday.isToday || isCustomSelection) ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isCustomSelection
                              ? (isDark ? AppColors.cyanLight : AppColors.primaryCyan).withValues(alpha: isDark ? 0.2 : 0.08)
                              : Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Spotlight Header Pill Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: activeBirthday.isToday
                                    ? AppColors.accentCoral.withValues(alpha: 0.15)
                                    : (isCustomSelection
                                        ? (isDark ? AppColors.cyanLight : AppColors.primaryCyan).withValues(alpha: 0.15)
                                        : (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.12)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    activeBirthday.isToday
                                        ? Icons.celebration_rounded
                                        : (isCustomSelection ? Icons.touch_app_rounded : Icons.star_rounded),
                                    color: activeBirthday.isToday
                                        ? AppColors.accentCoral
                                        : (isCustomSelection
                                            ? (isDark ? AppColors.cyanLight : AppColors.primaryCyan)
                                            : (isDark ? AppColors.indigoLight : AppColors.primaryIndigo)),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    activeBirthday.isToday
                                        ? settings.tr('spotlight_today')
                                        : (isCustomSelection
                                            ? 'Sélectionné'
                                            : settings.tr('spotlight_next')),
                                    style: TextStyle(
                                      color: activeBirthday.isToday
                                          ? AppColors.accentCoral
                                          : (isCustomSelection
                                              ? (isDark ? AppColors.cyanLight : AppColors.primaryCyan)
                                              : (isDark ? AppColors.indigoLight : AppColors.primaryIndigo)),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (isCustomSelection) ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => setState(() => _selectedBirthdayId = null),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 13,
                                        color: isDark ? AppColors.cyanLight : AppColors.primaryCyan,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Countdown Tag
                            Text(
                              activeBirthday.isToday
                                  ? '🎉 ${settings.tr('today')}'
                                  : (activeBirthday.daysRemaining <= 1
                                      ? settings.tr('in_day')
                                      : '${settings.tr('in_days')} ${activeBirthday.daysRemaining} ${settings.tr('days_unit').toLowerCase()}'),
                              style: TextStyle(
                                color: activeBirthday.isToday
                                    ? AppColors.accentCoral
                                    : (isDark ? AppColors.cyanLight : AppColors.primaryCyan),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Middle Contact Row
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.push('/birthday/${activeBirthday.id}'),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: activeBirthday.photoUrl != null && activeBirthday.photoUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: AvatarImage(
                                          photoUrl: activeBirthday.photoUrl!,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          activeBirthday.name.isNotEmpty ? activeBirthday.name[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),

                              // Name & Age details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activeBirthday.name,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : AppColors.textMainLight,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${settings.tr('fete_ses')} ${activeBirthday.nextAge} ${settings.tr('turning_age')} · ${DateFormat('d MMMM', localeStr).format(activeBirthday.birthdate)}',
                                      style: TextStyle(
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: isDark ? Colors.white38 : Colors.black26,
                                size: 16,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Bottom Action Buttons
                        Row(
                          children: [
                            // Quick Action 1: AI Wish
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                                  side: BorderSide(
                                    color: (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.35),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.08),
                                ),
                                onPressed: () {
                                  AiWishDialog.show(context, activeBirthday.id, apiService);
                                },
                                icon: Icon(
                                  Icons.auto_awesome,
                                  color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                                  size: 15,
                                ),
                                label: Text(
                                  settings.tr('wish_button'),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.primaryIndigo,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Quick Action 2: AI Gifts
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                                  side: BorderSide(
                                    color: AppColors.wishCoinsAmber.withValues(alpha: 0.35),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: AppColors.wishCoinsAmber.withValues(alpha: 0.08),
                                ),
                                onPressed: () {
                                  AiGiftSheet.show(context, activeBirthday);
                                },
                                icon: const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: AppColors.wishCoinsAmber,
                                  size: 15,
                                ),
                                label: Text(
                                  settings.tr('ai_gifts').split(' ').take(2).join(' '),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.textMainLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 3. EXECUTIVE STAT METRICS ROW (3 CLEAN INTERACTIVE CARDS)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    // Stat 1: Total
                    Expanded(
                      child: _buildExecutiveStatCard(
                        context: context,
                        isDark: isDark,
                        isSelected: _selectedCategory == 'TOUS',
                        icon: Icons.cake_rounded,
                        iconColor: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                        activeGradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        ),
                        value: '$totalCount',
                        label: settings.tr('total_birthdays'),
                        onTap: () => setState(() => _selectedCategory = 'TOUS'),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Stat 2: Ce mois-ci
                    Expanded(
                      child: _buildExecutiveStatCard(
                        context: context,
                        isDark: isDark,
                        isSelected: _selectedCategory == 'CE_MOIS',
                        icon: Icons.calendar_today_rounded,
                        iconColor: isDark ? AppColors.cyanLight : AppColors.primaryCyan,
                        activeGradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0284C7), Color(0xFF2563EB)],
                        ),
                        value: '$thisMonthCount',
                        label: settings.tr('this_month'),
                        onTap: () => setState(() => _selectedCategory = 'CE_MOIS'),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Stat 3: Favoris
                    Expanded(
                      child: _buildExecutiveStatCard(
                        context: context,
                        isDark: isDark,
                        isSelected: _selectedCategory == 'FAVORIS',
                        icon: Icons.star_rounded,
                        iconColor: AppColors.wishCoinsAmber,
                        activeGradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFD97706), Color(0xFFEA580C)],
                        ),
                        value: '$favoritesCount',
                        label: settings.tr('filter_favorites'),
                        onTap: () => setState(() => _selectedCategory = 'FAVORIS'),
                      ),
                    ),
                  ],
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
                        color: AppColors.wishCoinsAmber.withValues(alpha: 0.35),
                      ),
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
                        if (!syncService.isSyncing)
                          TextButton(
                            onPressed: () => syncService.syncAll(),
                            child: Text(
                              settings.tr('sync_now'),
                              style: TextStyle(
                                color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                        (context, index) {
                          final birthday = filtered[index];
                          return Padding(
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

  Widget _buildExecutiveStatCard({
    required BuildContext context,
    required bool isDark,
    required bool isSelected,
    required IconData icon,
    required Color iconColor,
    required Gradient activeGradient,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        height: 114,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? activeGradient : null,
          color: isSelected ? null : (isDark ? const Color(0xFF131826) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.28)
                : (isDark ? const Color(0xFF232D3F) : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: iconColor.withValues(alpha: isDark ? 0.38 : 0.28),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : iconColor.withValues(alpha: isDark ? 0.16 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : iconColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.textMainLight),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    final isSelected = _selectedBirthdayId == birthday.id;

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
          color: isSelected
              ? (isDark ? AppColors.indigoLight : AppColors.primaryIndigo)
              : (birthday.isToday
                  ? AppColors.accentCoral.withValues(alpha: 0.45)
                  : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder)),
          width: isSelected ? 2.0 : (birthday.isToday ? 1.5 : 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? (isDark ? AppColors.indigoLight.withValues(alpha: 0.25) : AppColors.primaryIndigo.withValues(alpha: 0.15))
                : Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedBirthdayId = birthday.id;
            });
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
                // Avatar with category ring
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.6),
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
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Actif',
                                style: TextStyle(
                                  color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
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
                    setState(() => _selectedBirthdayId = birthday.id);
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
                    setState(() => _selectedBirthdayId = birthday.id);
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
