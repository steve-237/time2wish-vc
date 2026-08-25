import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/gift_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glowing_badge.dart';
import 'ai_wish_dialog.dart';

class BirthdayDetailScreen extends StatelessWidget {
  final int birthdayId;

  const BirthdayDetailScreen({super.key, required this.birthdayId});

  void _showDeleteConfirmation(BuildContext context, BirthdayModel birthday) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer l\'anniversaire', style: TextStyle(color: Colors.white)),
        content: Text(
          'Voulez-vous vraiment supprimer l\'anniversaire de ${birthday.name} ?',
          style: const TextStyle(color: AppColors.textMutedDark),
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
            onPressed: () async {
              Navigator.pop(ctx);
              final service = context.read<BirthdayService>();
              await service.deleteBirthday(birthday.id);
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final birthdayService = Provider.of<BirthdayService>(context);
    final birthday = birthdayService.getBirthdayById(birthdayId);

    if (birthday == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Anniversaire non trouvé')),
        body: const Center(child: Text('Cet anniversaire n\'existe pas.', style: TextStyle(color: Colors.white))),
      );
    }

    final String initial = birthday.name.isNotEmpty ? birthday.name[0].toUpperCase() : '?';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              birthday.isFavorite ? Icons.star : Icons.star_border,
              color: birthday.isFavorite ? AppColors.wishCoinsAmber : Colors.white,
            ),
            onPressed: () {
              DeviceService.triggerLightHaptic();
              birthdayService.toggleFavorite(birthday.id);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Avatar Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryCyan.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        birthday.name,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GlowingBadge(
                            label: birthday.category,
                            color: AppColors.primaryCyan,
                            isSelected: true,
                          ),
                          if (birthday.gender != null) ...[
                            const SizedBox(width: 8),
                            GlowingBadge(
                              label: birthday.gender!,
                              color: AppColors.accentPurple,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Countdown Stat Banner
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        'Jours restants',
                        birthday.isToday ? '🎂 Aujourd\'hui' : '${birthday.daysRemaining}j',
                        AppColors.primaryCyan,
                      ),
                      Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                      _buildStatColumn(
                        'Prochain âge',
                        '${birthday.nextAge} ans',
                        AppColors.accentPurple,
                      ),
                      Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                      _buildStatColumn(
                        'Rappel',
                        'J-${birthday.reminderDays}',
                        AppColors.wishCoinsAmber,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Birthdate Details Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cake, color: AppColors.primaryCyan, size: 20),
                          SizedBox(width: 10),
                          Text('Date de naissance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat('dd MMMM yyyy', 'fr_FR').format(birthday.birthdate),
                        style: const TextStyle(color: AppColors.textLight, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      if (birthday.notes != null && birthday.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Notes & Remarques', style: TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(birthday.notes!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ],
                  ),
                ),

                if (birthday.interests.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.interests, color: AppColors.accentPurple, size: 20),
                            SizedBox(width: 10),
                            Text('Centres d\'intérêt', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: birthday.interests.map((tag) {
                            return GlowingBadge(label: tag, color: AppColors.accentPurple);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildGiftsSection(context, birthday),

                const SizedBox(height: 24),
                _buildActionButtons(context, birthday),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textMutedDark, fontSize: 11)),
      ],
    );
  }

  Widget _buildGiftsSection(BuildContext context, BirthdayModel birthday) {
    final giftService = Provider.of<GiftService>(context);
    final gifts = giftService.getGiftsForBirthday(birthday.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🎁 Idées Cadeaux & Cagnotte',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryCyan),
              onPressed: () {
                final nameCtrl = TextEditingController();
                final priceCtrl = TextEditingController();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1B4B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Ajouter une idée cadeau', style: TextStyle(color: Colors.white)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Nom du cadeau', labelStyle: TextStyle(color: AppColors.textMutedDark)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: priceCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Budget (ex: 50€)', labelStyle: TextStyle(color: AppColors.textMutedDark)),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: AppColors.textMutedDark))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
                        onPressed: () {
                          if (nameCtrl.text.isNotEmpty) {
                            Navigator.pop(ctx);
                            giftService.addGift(birthday.id, nameCtrl.text.trim(), null, priceCtrl.text.trim());
                          }
                        },
                        child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (gifts.isEmpty)
          const GlassCard(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('Aucune idée cadeau ajoutée pour l\'instant.', style: TextStyle(color: AppColors.textMutedDark)),
              ),
            ),
          )
        else
          Column(
            children: gifts.map((gift) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GlassCard(
                  child: Row(
                    children: [
                      Icon(
                        gift.isReserved ? Icons.check_circle : Icons.card_giftcard,
                        color: gift.isReserved ? AppColors.successGreen : AppColors.wishCoinsAmber,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gift.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                decoration: gift.isReserved ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (gift.description != null) ...[
                              const SizedBox(height: 2),
                              Text(gift.description!, style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
                            ],
                            if (gift.isReserved) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Réservé par ${gift.reservedByName ?? 'un ami'}',
                                style: const TextStyle(color: AppColors.successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          DeviceService.triggerLightHaptic();
                          giftService.toggleReserveGift(birthday.id, gift.id, 'Vous');
                        },
                        child: Text(
                          gift.isReserved ? 'Libérer' : 'Réserver',
                          style: TextStyle(
                            color: gift.isReserved ? AppColors.accentPink : AppColors.primaryCyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, BirthdayModel birthday) {
    final apiService = context.read<ApiService>();

    return Column(
      children: [
        // AI Wish Button
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              DeviceService.triggerMediumHaptic();
              AiWishDialog.show(context, birthday.id, apiService);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Générer un vœu avec l\'IA ✨',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Edit & Delete Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/birthday/${birthday.id}/edit'),
                icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                label: const Text('Modifier', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(context, birthday),
                icon: const Icon(Icons.delete_outline, color: AppColors.accentPink, size: 18),
                label: const Text('Supprimer', style: TextStyle(color: AppColors.accentPink)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.accentPink),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
