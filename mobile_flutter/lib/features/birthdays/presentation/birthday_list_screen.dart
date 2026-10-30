import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/widgets/animated_list_item.dart';

class BirthdayListScreen extends StatefulWidget {
  const BirthdayListScreen({super.key});

  @override
  State<BirthdayListScreen> createState() => _BirthdayListScreenState();
}

class _BirthdayListScreenState extends State<BirthdayListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'TOUS';
  String _sortBy = 'DATE';

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
    var result = birthdays.where((b) {
      final matchesSearch = _searchQuery.isEmpty ||
          b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.interests.any((i) => i.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      if (_selectedCategory == 'FAVORIS') return b.isFavorite;
      if (_selectedCategory == 'CE_MOIS') return b.birthDate.month == now.month;
      if (_selectedCategory != 'TOUS') return b.category.toUpperCase() == _selectedCategory;
      return true;
    }).toList();

    if (_sortBy == 'NOM') {
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'FAVORIS') {
      result.sort((a, b) {
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        return a.daysRemaining.compareTo(b.daysRemaining);
      });
    } else {
      result.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    }
    return result;
  }

  void _showLanguageSelector(BuildContext context, SettingsService settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.language_rounded, color: AppColors.primaryCyan, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    settings.tr('select_language'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLangTile(ctx, settings, 'fr', 'Français', '🇫🇷'),
              _buildLangTile(ctx, settings, 'en', 'English', '🇬🇧'),
              _buildLangTile(ctx, settings, 'de', 'Deutsch', '🇩🇪'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangTile(BuildContext ctx, SettingsService settings, String code, String label, String flag) {
    final isSelected = settings.language == code;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? AppColors.primaryCyan.withValues(alpha: 0.18) : Colors.transparent,
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primaryCyan : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryCyan, size: 20)
          : null,
      onTap: () {
        settings.setLanguage(code);
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$flag Langue : $label'),
            backgroundColor: AppColors.primaryCyan,
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  void _showNotificationSheet(BuildContext context, BirthdayService birthdayService, SettingsService settings) {
    final upcomingList = birthdayService.upcoming.take(5).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF38BDF8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Rappels & Notifications',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (upcomingList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('Aucun rappel pour le moment.', style: TextStyle(color: AppColors.textMutedDark)),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: upcomingList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final b = upcomingList[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: Center(
                                child: Text(
                                  b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    b.isToday ? '🎉 C\'est son anniversaire aujourd\'hui !' : 'Dans ${b.daysRemaining} jours 🎂',
                                    style: TextStyle(
                                      color: b.isToday ? const Color(0xFFF43F5E) : const Color(0xFF38BDF8),
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
                              child: const Text('Voir', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  void _showWishCoinsModal(BuildContext context, int coins) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundDialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.wishCoinsAmber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.monetization_on, color: AppColors.wishCoinsAmber, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('WishCoins', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.wishCoinsAmber.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Text(
                  '$coins WishCoins 🪙',
                  style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Avantages de vos WishCoins :',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            _buildCoinPerk('✨ Vœux IA personnalisés', '1 crédit / vœu généré'),
            const SizedBox(height: 6),
            _buildCoinPerk('💡 Idées cadeaux ciblées', 'Analyses de profils exclusives'),
            const SizedBox(height: 6),
            _buildCoinPerk('🎁 Cagnottes collectives', 'Rechargement quotidien gratuit'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Super !', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinPerk(String title, String subtitle) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$title : ',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              children: [
                TextSpan(
                  text: subtitle,
                  style: const TextStyle(color: AppColors.textMutedDark, fontWeight: FontWeight.normal),
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
    final user = authService.currentUser;
    final filtered = _getFilteredBirthdays(birthdayService.upcoming);
    final BirthdayModel? nextBirthday = birthdayService.upcoming.isNotEmpty ? birthdayService.upcoming.first : null;

    final now = DateTime.now();
    final thisMonthCount = birthdayService.birthdays.where((b) => b.birthDate.month == now.month).length;
    final totalCount = birthdayService.birthdays.length;

    final String langFlag = settings.language == 'en'
        ? '🇬🇧'
        : settings.language == 'de'
            ? '🇩🇪'
            : '🇫🇷';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.primaryCyan,
        backgroundColor: AppColors.backgroundDialogDark,
        onRefresh: () async {
          if (syncService.hasPending) {
            await syncService.syncAll();
          }
          await birthdayService.fetchBirthdays();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. TOP HEADER APP BAR WITH TITLE, SUBTITLE & NOTIFICATION BELL
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                              children: [
                                TextSpan(text: 'Time', style: TextStyle(color: Colors.white)),
                                TextSpan(text: '2', style: TextStyle(color: Color(0xFF38BDF8))),
                                TextSpan(text: 'Wish', style: TextStyle(color: Color(0xFFA855F7))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            settings.tr('app_subtitle'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right header accessories: Lang pill & Notification Bell
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Language switcher pill
                        GestureDetector(
                          onTap: () => _showLanguageSelector(context, settings),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(langFlag, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  settings.language.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Notification Bell with Red Badge Dot
                        GestureDetector(
                          onTap: () => _showNotificationSheet(context, birthdayService, settings),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF161F33).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                // Red active dot
                                Positioned(
                                  top: 8,
                                  right: 9,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF161F33), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                          blurRadius: 4,
                                        ),
                                      ],
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

            // 2. THE 3 HERO METRIC STAT CARDS IN A ROW (AS IN MOCKUP)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    // Card 1: Next Birthday (Blue Glow Border)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (nextBirthday != null) {
                            context.push('/birthday/${nextBirthday.id}');
                          }
                        },
                        child: Container(
                          height: 132,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1E36),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFF38BDF8),
                              width: 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.32),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Icon Badge
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                                ),
                                child: const Icon(
                                  Icons.card_giftcard_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 19,
                                ),
                              ),
                              // Big Number
                              Text(
                                '${nextBirthday?.daysRemaining ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                              // Subtitle
                              Text(
                                nextBirthday != null && nextBirthday.daysRemaining <= 1
                                    ? settings.tr('day_remaining')
                                    : settings.tr('days_unit'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Card 2: This Month (Dark Glass Card)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = 'CE_MOIS'),
                        child: Container(
                          height: 132,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161F33).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: _selectedCategory == 'CE_MOIS'
                                  ? const Color(0xFF38BDF8)
                                  : Colors.white.withValues(alpha: 0.12),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Icon Badge
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                child: const Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white70,
                                  size: 19,
                                ),
                              ),
                              // Big Number
                              Text(
                                '$thisMonthCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                              // Subtitle
                              Text(
                                settings.tr('this_month'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Card 3: Total Celebrations (Purple Gradient Glow)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = 'TOUS'),
                        child: Container(
                          height: 132,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFF6D28D9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Icon Badge
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                                child: const Icon(
                                  Icons.cake_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                              // Big Number
                              Text(
                                '$totalCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                              // Subtitle
                              Text(
                                settings.tr('total_birthdays'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. OFFLINE SYNC BANNER (IF PENDING)
            if (syncService.hasPending)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.wishCoinsAmber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: syncService.isSyncing
                              ? const SpinKitRing(color: AppColors.wishCoinsAmber, size: 16, lineWidth: 2)
                              : const Icon(Icons.cloud_sync, color: AppColors.wishCoinsAmber, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            syncService.isSyncing
                                ? 'Synchronisation en cours...'
                                : '${syncService.pendingCount} ${settings.tr('sync_pending')}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (!syncService.isSyncing)
                          TextButton(
                            onPressed: () => syncService.syncAll(),
                            child: Text(
                              settings.tr('sync_now'),
                              style: const TextStyle(color: AppColors.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // 4. MAIN "BIRTHDAYS" SECTION GLASS CARD (MATCHING MOCKUP)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A29).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header inside Card: "Birthdays" title & "View all" link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            settings.tr('birthdays'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = 'TOUS';
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                            child: Text(
                              settings.tr('view_all'),
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quick Filter Pills Row
                      SizedBox(
                        height: 36,
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

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCategory = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF38BDF8).withValues(alpha: 0.22)
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.08),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                      const SizedBox(height: 12),

                      // Search bar
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: settings.tr('search_hint'),
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 18),
                            prefixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: const Icon(Icons.clear, color: Colors.white54, size: 16),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Birthday List Content
                      if (birthdayService.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: SpinKitThreeBounce(color: Color(0xFF38BDF8), size: 24),
                          ),
                        )
                      else if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Column(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                                child: const Center(child: Text('🎂', style: TextStyle(fontSize: 26))),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Aucun résultat pour "$_searchQuery"'
                                    : settings.tr('no_birthdays'),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                settings.tr('no_birthdays_sub'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final b = filtered[index];
                            return _buildMockupBirthdayItem(context, b, birthdayService, settings);
                          },
                        ),

                      const SizedBox(height: 16),

                      // Bottom Card Button: "+ Ajouter un anniversaire"
                      GestureDetector(
                        onTap: () => context.push('/birthday/new'),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E283D),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded, color: Color(0xFF38BDF8), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                settings.tr('add_birthday'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockupBirthdayItem(
    BuildContext context,
    BirthdayModel birthday,
    BirthdayService service,
    SettingsService settings,
  ) {
    final String initial = birthday.name.isNotEmpty ? birthday.name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => context.push('/birthday/${birthday.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                border: Border.all(
                  color: birthday.isFavorite ? AppColors.wishCoinsAmber : Colors.white24,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: birthday.photoUrl != null && birthday.photoUrl!.isNotEmpty
                  ? ClipOval(
                      child: AvatarImage(
                        photoUrl: birthday.photoUrl!,
                        width: 44,
                        height: 44,
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

            // Name & Subtext
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          birthday.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (birthday.isFavorite)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.star_rounded, color: AppColors.wishCoinsAmber, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    birthday.isToday
                        ? '🎂 Aujourd\'hui !'
                        : 'Dans ${birthday.daysRemaining} jours 🎂',
                    style: TextStyle(
                      color: birthday.isToday
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: birthday.isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Trailing Chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
