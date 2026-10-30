import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/widgets/glowing_badge.dart';
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

  final List<String> _categories = ['TOUS', 'FAVORIS', 'AMIS', 'FAMILLE', 'TRAVAIL'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BirthdayService>().fetchBirthdays();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BirthdayModel> _getFilteredBirthdays(List<BirthdayModel> birthdays) {
    var result = birthdays.where((b) {
      final matchesSearch = _searchQuery.isEmpty ||
          b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.interests.any((i) => i.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      if (_selectedCategory == 'FAVORIS') return b.isFavorite;
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
            // 1. TOP HEADER APP BAR WITH OFFICIAL ICON & BRANDING
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    // Official App Icon with Glowing Ring
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/branding/time2wish_icon_192.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: const Icon(Icons.cake, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Stylized Brand Title: Time2Wish
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                              children: [
                                TextSpan(text: 'Time', style: TextStyle(color: Colors.white)),
                                TextSpan(text: '2', style: TextStyle(color: Color(0xFF38BDF8))),
                                TextSpan(text: 'Wish', style: TextStyle(color: Color(0xFFA855F7))),
                              ],
                            ),
                          ),
                          Text(
                            user?.fullName.isNotEmpty == true ? 'Bonjour, ${user!.fullName}' : 'Assistant Célébrations',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Quick Language Switcher Button (Flag Pill)
                    GestureDetector(
                      onTap: () => _showLanguageSelector(context, settings),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(langFlag, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              settings.language.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quick Theme Toggle Button
                    IconButton(
                      icon: Icon(
                        settings.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: settings.isDarkMode ? AppColors.wishCoinsAmber : Colors.orangeAccent,
                        size: 22,
                      ),
                      onPressed: () => settings.toggleDarkMode(),
                      tooltip: settings.tr('appearance'),
                      visualDensity: VisualDensity.compact,
                    ),

                    // WishCoins Badge
                    GestureDetector(
                      onTap: () => _showWishCoinsModal(context, user?.coins ?? 100),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.wishCoinsAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.wishCoinsAmber.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, color: AppColors.wishCoinsAmber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${user?.coins ?? 100}',
                              style: const TextStyle(
                                color: AppColors.wishCoinsAmber,
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

            // 2. HERO HIGHLIGHT: PROCHAIN ANNIVERSAIRE (NEXT CELEBRATION FEATURE CARD)
            if (nextBirthday != null && _searchQuery.isEmpty && _selectedCategory == 'TOUS')
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1E1B4B), // Deep Indigo
                          Color(0xFF311042), // Deep Violet
                          Color(0xFF1E293B), // Slate
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppColors.primaryCyan.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPurple.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('✨', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  settings.tr('next_celebration').toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: nextBirthday.isToday
                                    ? AppColors.accentPink
                                    : (nextBirthday.daysRemaining <= 3 ? AppColors.accentPink : AppColors.primaryCyan).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: nextBirthday.isToday ? Colors.white : AppColors.primaryCyan,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                nextBirthday.isToday
                                    ? settings.tr('today')
                                    : 'Dans ${nextBirthday.daysRemaining} ${nextBirthday.daysRemaining <= 1 ? settings.tr('day_remaining') : settings.tr('days_remaining')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: nextBirthday.photoUrl != null && nextBirthday.photoUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: AvatarImage(
                                        photoUrl: nextBirthday.photoUrl!,
                                        width: 54,
                                        height: 54,
                                        fit: BoxFit.cover,
                                        fallback: Center(
                                          child: Text(
                                            nextBirthday.name.isNotEmpty ? nextBirthday.name[0].toUpperCase() : '?',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        nextBirthday.name.isNotEmpty ? nextBirthday.name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nextBirthday.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${DateFormat('d MMMM', settings.language).format(nextBirthday.birthdate)} • ${nextBirthday.nextAge} ans',
                                    style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            // Quick Action Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF38BDF8),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: () => context.push('/birthday/${nextBirthday.id}'),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 16),
                                  SizedBox(width: 4),
                                  Text('Fêter 🎉', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 3. OFFLINE SYNC BANNER (IF PENDING)
            if (syncService.hasPending)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4.0),
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

            // 4. SEARCH & SORT BAR
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4.0),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: settings.tr('search_hint'),
                      hintStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                      icon: const Icon(Icons.search_rounded, color: AppColors.primaryCyan),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMutedDark, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.tune_rounded, color: AppColors.primaryCyan, size: 20),
                            color: AppColors.backgroundDialogDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            tooltip: settings.tr('sort_by'),
                            onSelected: (val) => setState(() => _sortBy = val),
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'DATE',
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: _sortBy == 'DATE' ? AppColors.primaryCyan : Colors.white70),
                                    const SizedBox(width: 8),
                                    Text(settings.tr('sort_date'), style: TextStyle(color: _sortBy == 'DATE' ? AppColors.primaryCyan : Colors.white)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'NOM',
                                child: Row(
                                  children: [
                                    Icon(Icons.sort_by_alpha, size: 16, color: _sortBy == 'NOM' ? AppColors.primaryCyan : Colors.white70),
                                    const SizedBox(width: 8),
                                    Text(settings.tr('sort_name'), style: TextStyle(color: _sortBy == 'NOM' ? AppColors.primaryCyan : Colors.white)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'FAVORIS',
                                child: Row(
                                  children: [
                                    Icon(Icons.star, size: 16, color: _sortBy == 'FAVORIS' ? AppColors.wishCoinsAmber : Colors.white70),
                                    const SizedBox(width: 8),
                                    Text(settings.tr('sort_favorites'), style: TextStyle(color: _sortBy == 'FAVORIS' ? AppColors.wishCoinsAmber : Colors.white)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 5. CATEGORY FILTER CHIPS
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;

                    String label;
                    String emoji;
                    switch (cat) {
                      case 'FAVORIS':
                        label = settings.tr('filter_favorites');
                        emoji = '⭐';
                        break;
                      case 'AMIS':
                        label = settings.tr('filter_friends');
                        emoji = '🎈';
                        break;
                      case 'FAMILLE':
                        label = settings.tr('filter_family');
                        emoji = '🏠';
                        break;
                      case 'TRAVAIL':
                        label = settings.tr('filter_work');
                        emoji = '💼';
                        break;
                      default:
                        label = settings.tr('filter_all');
                        emoji = '✨';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryCyan.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryCyan : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textMutedDark,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 6. LOADING STATE
            if (birthdayService.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(child: SpinKitThreeBounce(color: AppColors.primaryCyan, size: 28)),
                ),
              ),

            // 7. EMPTY STATE
            if (!birthdayService.isLoading && filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryCyan.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                          ),
                          child: const Center(
                            child: Text('🎂', style: TextStyle(fontSize: 40)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'Aucun résultat pour "$_searchQuery"' : settings.tr('no_birthdays'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          settings.tr('no_birthdays_sub'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 8. RICH & PRESENTABLE BIRTHDAY CARDS
            if (!birthdayService.isLoading && filtered.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final birthday = filtered[index];
                      return AnimatedListItem(
                        index: index,
                        child: _buildPresentableBirthdayCard(context, birthday, birthdayService, settings),
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

  Widget _buildPresentableBirthdayCard(
    BuildContext context,
    BirthdayModel birthday,
    BirthdayService service,
    SettingsService settings,
  ) {
    final String initial = birthday.name.isNotEmpty ? birthday.name[0].toUpperCase() : '?';
    final Color badgeColor = birthday.isToday
        ? const Color(0xFFEC4899)
        : birthday.daysRemaining <= 3
            ? const Color(0xFFF43F5E)
            : birthday.daysRemaining <= 7
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981);

    final String formattedDate = DateFormat('d MMM', settings.language).format(birthday.birthdate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        onTap: () => context.push('/birthday/${birthday.id}'),
        child: Row(
          children: [
            // Avatar with Gradient Ring or Photo
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                border: Border.all(
                  color: birthday.isFavorite ? AppColors.wishCoinsAmber : Colors.white24,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: birthday.photoUrl != null && birthday.photoUrl!.isNotEmpty
                  ? ClipOval(
                      child: AvatarImage(
                        photoUrl: birthday.photoUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        fallback: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Details: Name, Age, Date, Category
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
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => service.toggleFavorite(birthday.id),
                        child: Icon(
                          birthday.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: birthday.isFavorite ? AppColors.wishCoinsAmber : Colors.white30,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Date pill
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.primaryCyan),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Age indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${birthday.nextAge} ans',
                          style: const TextStyle(color: AppColors.textMutedDark, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Category pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          birthday.category,
                          style: const TextStyle(color: AppColors.primaryCyan, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Live Countdown Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    birthday.isToday ? '🎂' : '${birthday.daysRemaining}j',
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    birthday.isToday ? "Aujourd'hui" : 'Restants',
                    style: TextStyle(
                      color: badgeColor.withValues(alpha: 0.9),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
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
