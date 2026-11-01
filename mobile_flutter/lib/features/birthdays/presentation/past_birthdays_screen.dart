import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/theme/app_theme.dart';
import 'ai_wish_dialog.dart';

class PastBirthdaysScreen extends StatefulWidget {
  const PastBirthdaysScreen({super.key});

  @override
  State<PastBirthdaysScreen> createState() => _PastBirthdaysScreenState();
}

class _PastBirthdaysScreenState extends State<PastBirthdaysScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'TOUS';

  final List<String> _categories = ['TOUS', 'AMIS', 'FAMILLE', 'TRAVAIL', 'FAVORIS'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BirthdayModel> _filterPast(List<BirthdayModel> pastList) {
    return pastList.where((b) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = b.name.toLowerCase().contains(query);
        final matchesCat = b.category.toLowerCase().contains(query);
        if (!matchesName && !matchesCat) return false;
      }

      if (_selectedCategory == 'FAVORIS') {
        if (!b.isFavorite) return false;
      } else if (_selectedCategory != 'TOUS') {
        if (b.category.toUpperCase() != _selectedCategory.toUpperCase()) return false;
      }

      return true;
    }).toList();
  }

  String _formatPastDate(DateTime date, String lang) {
    final locale = lang == 'en' ? 'en_US' : (lang == 'de' ? 'de_DE' : 'fr_FR');
    final formatter = DateFormat('d MMMM', locale);
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final birthdayService = context.watch<BirthdayService>();
    final settings = context.watch<SettingsService>();
    final apiService = context.read<ApiService>();
    final isDark = settings.isDarkMode;

    final pastBirthdays = birthdayService.pastBirthdays;
    final filtered = _filterPast(pastBirthdays);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF131826) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : AppColors.textMainLight,
          ),
          onPressed: () {
            DeviceService.triggerLightHaptic();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.cyanLight : AppColors.primaryCyan).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.history_rounded,
                color: isDark ? AppColors.cyanLight : AppColors.primaryCyan,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Anniversaires Passés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textMainLight,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14,
                  color: isDark ? AppColors.cyanLight : AppColors.primaryCyan,
                ),
                const SizedBox(width: 5),
                Text(
                  '${pastBirthdays.length} célébrés',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              color: isDark ? const Color(0xFF131826) : Colors.white,
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B2233) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textMainLight,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Rechercher un anniversaire passé...',
                              hintStyle: TextStyle(
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                              });
                            },
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Category Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              DeviceService.triggerLightHaptic();
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppColors.indigoLight : AppColors.primaryIndigo)
                                    : (isDark ? const Color(0xFF1A2234) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle),
                                ),
                              ),
                              child: Text(
                                cat == 'TOUS' ? 'Tous' : '${cat.substring(0, 1)}${cat.substring(1).toLowerCase()}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                            ),
                          );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Colors.white10),

            // Content List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.cyanLight : AppColors.primaryCyan).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.history_toggle_off_rounded,
                                size: 48,
                                color: isDark ? AppColors.cyanLight : AppColors.primaryCyan,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              pastBirthdays.isEmpty
                                  ? 'Aucun anniversaire passé cette année'
                                  : 'Aucun résultat pour cette recherche',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textMainLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pastBirthdays.isEmpty
                                  ? 'Les anniversaires célébrés au cours de l\'année s\'afficheront ici automatiquement.'
                                  : 'Essayez un autre mot-clé ou réinitialisez vos filtres.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final b = filtered[index];
                        final daysAgo = b.daysSinceOccurrence;
                        final dateStr = _formatPastDate(b.birthdate, settings.language);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF141926) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF222B3E) : AppColors.lightBorder,
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              DeviceService.triggerLightHaptic();
                              context.push('/birthday/${b.id}');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: AppColors.primaryGradient,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Name & Category
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    b.name,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDark ? Colors.white : AppColors.textMainLight,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (b.isFavorite) ...[
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  dateStr,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                                  ),
                                                ),
                                                Text(
                                                  ' · Fêté : ${b.celebratedAge} ans',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? Colors.white54 : Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Time badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Text(
                                          daysAgo == 0 ? 'Aujourd\'hui' : 'Il y a $daysAgo j',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.cyanLight : AppColors.primaryCyan,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),
                                  const Divider(height: 1, color: Colors.white10),
                                  const SizedBox(height: 10),

                                  // Action Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Late wish generator button
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () {
                                          DeviceService.triggerLightHaptic();
                                          AiWishDialog.show(
                                            context,
                                            b.id,
                                            apiService,
                                            initialTone: 'HUMORISTIQUE',
                                          );
                                        },
                                        icon: const Icon(Icons.auto_awesome, size: 14, color: AppColors.wishCoinsAmber),
                                        label: const Text(
                                          'Vœu de retard IA ✨',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.wishCoinsAmber,
                                          ),
                                        ),
                                      ),

                                      // View profile button
                                      InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          DeviceService.triggerLightHaptic();
                                          context.push('/birthday/${b.id}');
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Voir la fiche',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                size: 16,
                                                color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
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
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
