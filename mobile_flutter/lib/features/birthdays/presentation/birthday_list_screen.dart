import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class BirthdayListScreen extends StatefulWidget {
  const BirthdayListScreen({super.key});

  @override
  State<BirthdayListScreen> createState() => _BirthdayListScreenState();
}

class _BirthdayListScreenState extends State<BirthdayListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  List<BirthdayModel> _filteredBirthdays(List<BirthdayModel> birthdays) {
    if (_searchQuery.isEmpty) return birthdays;
    return birthdays
        .where((b) => b.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final birthdayService = Provider.of<BirthdayService>(context);
    final user = authService.currentUser;
    final filtered = _filteredBirthdays(birthdayService.upcoming);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/birthday/new'),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        backgroundColor: const Color(0xFF1E1B4B),
        onRefresh: () => birthdayService.fetchBirthdays(),
        child: CustomScrollView(
          slivers: [
            // Header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, ${user?.fullName ?? 'Ami'} 👋',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${birthdayService.birthdays.length} anniversaires · ${birthdayService.upcomingThisMonth} ce mois',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMutedDark),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, color: Colors.greenAccent, size: 12),
                              SizedBox(width: 4),
                              Text(
                                '100% Autonome & Hors-Ligne',
                                style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.wishCoinsAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.wishCoinsAmber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.token, color: AppColors.wishCoinsAmber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${user?.coins ?? 50}',
                            style: const TextStyle(
                              color: AppColors.wishCoinsAmber,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un anniversaire...',
                      hintStyle: TextStyle(color: AppColors.textMutedDark, fontSize: 14),
                      icon: Icon(Icons.search, color: AppColors.textMutedDark),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),

            // Loading indicator
            if (birthdayService.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
                ),
              ),

            // Empty state
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
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          ),
                          child: const Center(
                            child: Text('🎂', style: TextStyle(fontSize: 40)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'Aucun résultat' : 'Aucun anniversaire',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Essayez un autre nom'
                              : 'Ajoutez votre premier anniversaire\navec le bouton + ci-dessous',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Birthday Cards
            if (!birthdayService.isLoading && filtered.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final birthday = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: GlassCard(
                        onTap: () => context.push('/birthday/${birthday.id}'),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryBlue.withValues(alpha: 0.8),
                                    AppColors.accentPurple.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  birthday.name.isNotEmpty ? birthday.name[0] : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Info
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
                                        ),
                                      ),
                                      if (birthday.isFavorite)
                                        const Icon(Icons.star, color: AppColors.wishCoinsAmber, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.4)),
                                        ),
                                        child: Text(
                                          birthday.category,
                                          style: const TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (birthday.interests.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          birthday.interests.take(2).join(', '),
                                          style: const TextStyle(color: AppColors.textMutedDark, fontSize: 10),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Countdown Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: birthday.daysRemaining <= 3
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : birthday.daysRemaining <= 7
                                        ? AppColors.wishCoinsAmber.withValues(alpha: 0.2)
                                        : Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: birthday.daysRemaining <= 3
                                      ? Colors.red.withValues(alpha: 0.5)
                                      : birthday.daysRemaining <= 7
                                          ? AppColors.wishCoinsAmber.withValues(alpha: 0.5)
                                          : Colors.green.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    birthday.isToday ? '🎂' : '${birthday.daysRemaining}j',
                                    style: TextStyle(
                                      color: birthday.daysRemaining <= 3
                                          ? Colors.redAccent
                                          : birthday.daysRemaining <= 7
                                              ? AppColors.wishCoinsAmber
                                              : Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
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
                  },
                  childCount: filtered.length,
                ),
              ),

            // Bottom spacing for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
