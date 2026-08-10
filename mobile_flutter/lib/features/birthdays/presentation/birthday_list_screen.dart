import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class BirthdayModel {
  final int id;
  final String name;
  final DateTime birthDate;
  final String relationship;
  final String? avatarUrl;
  final int daysRemaining;

  BirthdayModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.relationship,
    this.avatarUrl,
    required this.daysRemaining,
  });
}

class BirthdayListScreen extends StatefulWidget {
  const BirthdayListScreen({super.key});

  @override
  State<BirthdayListScreen> createState() => _BirthdayListScreenState();
}

class _BirthdayListScreenState extends State<BirthdayListScreen> {
  final List<BirthdayModel> _mockBirthdays = [
    BirthdayModel(
      id: 1,
      name: 'Sophie Martin',
      birthDate: DateTime.now().add(const Duration(days: 3)),
      relationship: 'AMIS',
      daysRemaining: 3,
    ),
    BirthdayModel(
      id: 2,
      name: 'Alexandre Dubois',
      birthDate: DateTime.now().add(const Duration(days: 12)),
      relationship: 'FAMILLE',
      daysRemaining: 12,
    ),
    BirthdayModel(
      id: 3,
      name: 'Emma Leroy',
      birthDate: DateTime.now().add(const Duration(days: 28)),
      relationship: 'TRAVAIL',
      daysRemaining: 28,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // App Bar Header
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
                      const Text(
                        'Vos anniversaires à venir',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                    ],
                  ),

                  // WishCoins Header Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.wishCoinsAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.wishCoinsAmber.withValues(alpha: 0.3),
                      ),
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

          // Birthday Cards List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final birthday = _mockBirthdays[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: GlassCard(
                    onTap: () {},
                    child: Row(
                      children: [
                        // Avatar Circle
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
                              birthday.name[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Info Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                birthday.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primaryBlue.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      birthday.relationship,
                                      style: const TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
                                : Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: birthday.daysRemaining <= 3
                                  ? Colors.red.withValues(alpha: 0.5)
                                  : Colors.green.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${birthday.daysRemaining}j',
                                style: TextStyle(
                                  color: birthday.daysRemaining <= 3
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const Text(
                                'Restants',
                                style: TextStyle(
                                  color: AppColors.textMutedDark,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _mockBirthdays.length,
            ),
          ),
        ],
      ),
    );
  }
}
