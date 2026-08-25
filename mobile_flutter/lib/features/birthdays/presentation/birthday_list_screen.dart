import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glowing_badge.dart';

class BirthdayListScreen extends StatefulWidget {
  const BirthdayListScreen({super.key});

  @override
  State<BirthdayListScreen> createState() => _BirthdayListScreenState();
}

class _BirthdayListScreenState extends State<BirthdayListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'TOUS';

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
    return birthdays.where((b) {
      final matchesSearch = _searchQuery.isEmpty ||
          b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.category.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedCategory == 'FAVORIS') return b.isFavorite;
      if (_selectedCategory != 'TOUS') return b.category.toUpperCase() == _selectedCategory;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final birthdayService = Provider.of<BirthdayService>(context);
    final user = authService.currentUser;
    final filtered = _getFilteredBirthdays(birthdayService.upcoming);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryCyan.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => context.push('/birthday/new'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryCyan,
        backgroundColor: const Color(0xFF1E1B4B),
        onRefresh: () => birthdayService.fetchBirthdays(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero Welcome & Wallet Header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                    user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'A',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bonjour, ${user?.fullName ?? 'Ami'} 👋',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${birthdayService.birthdays.length} anniversaires · ${birthdayService.upcomingThisMonth} ce mois',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GlowingBadge(
                            label: '100% Autonome & Hors-Ligne',
                            icon: Icons.bolt,
                            color: AppColors.successGreen,
                          ),
                        ],
                      ),
                    ),
                    // WishCoins Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.wishCoinsAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.wishCoinsAmber.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.wishCoinsAmber.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on, color: AppColors.wishCoinsAmber, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '${user?.coins ?? 100}',
                            style: const TextStyle(
                              color: AppColors.wishCoinsAmber,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Glass Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un ami, une catégorie...',
                      hintStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
                      icon: const Icon(Icons.search, color: AppColors.primaryCyan),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMutedDark, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            // Category Filter Pills
            SliverToBoxAdapter(
              child: SizedBox(
                height: 54,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GlowingBadge(
                        label: cat,
                        color: isSelected ? AppColors.primaryCyan : AppColors.textMutedDark,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedCategory = cat),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Loading Indicator
            if (birthdayService.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
                ),
              ),

            // Empty State
            if (!birthdayService.isLoading && filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryCyan.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                          ),
                          child: const Center(
                            child: Text('🎂', style: TextStyle(fontSize: 42)),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _searchQuery.isNotEmpty ? 'Aucun résultat trouvé' : 'Aucun anniversaire enregisté',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Essayez avec un autre nom ou catégorie'
                              : 'Ajoutez votre premier anniversaire\navec le bouton + ci-dessous',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Birthday Cards List
            if (!birthdayService.isLoading && filtered.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final birthday = filtered[index];
                    return _buildBirthdayCard(context, birthday, birthdayService);
                  },
                  childCount: filtered.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdayCard(BuildContext context, BirthdayModel birthday, BirthdayService service) {
    final String initial = birthday.name.isNotEmpty ? birthday.name[0].toUpperCase() : '?';
    final Color badgeColor = birthday.daysRemaining <= 3
        ? AppColors.accentPink
        : birthday.daysRemaining <= 7
            ? AppColors.wishCoinsAmber
            : AppColors.successGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: GlassCard(
        onTap: () => context.push('/birthday/${birthday.id}'),
        child: Row(
          children: [
            // Avatar with Gradient Ring
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Contact Info
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
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          birthday.isFavorite ? Icons.star : Icons.star_border,
                          color: birthday.isFavorite ? AppColors.wishCoinsAmber : AppColors.textMutedDark,
                          size: 20,
                        ),
                        onPressed: () => service.toggleFavorite(birthday.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      GlowingBadge(
                        label: birthday.category,
                        color: AppColors.primaryCyan,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      ),
                      if (birthday.interests.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            birthday.interests.take(2).join(', '),
                            style: const TextStyle(color: AppColors.textMutedDark, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Dynamic Countdown Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Text(
                    birthday.isToday ? '🎂' : '${birthday.daysRemaining}j',
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    birthday.isToday ? "Aujourd'hui" : 'Restants',
                    style: const TextStyle(color: AppColors.textMutedDark, fontSize: 9),
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
