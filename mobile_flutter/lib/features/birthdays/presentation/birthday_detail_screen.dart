import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/services/api_service.dart';
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
        title: const Text('Supprimer cet anniversaire ?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Voulez-vous vraiment supprimer ${birthday.name} ? Cette action est irréversible.',
          style: const TextStyle(color: AppColors.textMutedDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textMutedDark)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final service = context.read<BirthdayService>();
              await service.deleteBirthday(birthday.id);
              if (context.mounted) context.pop();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<BirthdayService>(
            builder: (context, service, _) {
              final birthday = service.getBirthdayById(birthdayId);
              if (birthday == null) return const SizedBox();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: const Color(0xFF1E1B4B),
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push('/birthday/${birthday.id}/edit');
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, birthday);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text('Modifier', style: TextStyle(color: Colors.white)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
                    ]),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)],
          ),
        ),
        child: Consumer<BirthdayService>(
          builder: (context, service, _) {
            final birthday = service.getBirthdayById(birthdayId);
            if (birthday == null) {
              return const Center(
                child: Text('Anniversaire introuvable', style: TextStyle(color: Colors.white, fontSize: 18)),
              );
            }
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(birthday),
                    const SizedBox(height: 24),
                    _buildInfoSection(birthday),
                    const SizedBox(height: 24),
                    if (birthday.interests.isNotEmpty) ...[
                      _buildInterestsSection(birthday),
                      const SizedBox(height: 24),
                    ],
                    if (birthday.partyLocation != null && birthday.partyLocation!.isNotEmpty) ...[
                      _buildPartySection(birthday),
                      const SizedBox(height: 24),
                    ],
                    _buildActionButtons(context, birthday),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BirthdayModel birthday) {
    final bool isClose = birthday.daysRemaining <= 3;
    final String initial = birthday.name.isNotEmpty ? birthday.name[0].toUpperCase() : '?';

    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.accentPurple, AppColors.accentPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              if (birthday.isFavorite)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.wishCoinsAmber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            birthday.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.5)),
                ),
                child: Text(
                  birthday.category,
                  style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isClose
                      ? AppColors.accentPink.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isClose
                        ? AppColors.accentPink.withValues(alpha: 0.5)
                        : Colors.green.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  birthday.isToday ? "🎂 Aujourd'hui !" : '${birthday.daysRemaining}j restants',
                  style: TextStyle(
                    color: isClose ? AppColors.accentPink : Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (birthday.isToday) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.wishCoinsAmber, AppColors.accentPink]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cake, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text("🎉 C'est aujourd'hui !", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(BirthdayModel birthday) {
    final months = ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
                     'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    final formattedDate = '${birthday.birthdate.day} ${months[birthday.birthdate.month]} ${birthday.birthdate.year}';

    return GlassCard(
      opacity: 0.12,
      blur: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.calendar_today, 'Date de naissance',
              '$formattedDate${birthday.showAge ? ' (${birthday.nextAge} ans)' : ''}'),
          if (birthday.gender != null && birthday.gender!.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 24),
            _buildInfoRow(Icons.person_outline, 'Genre',
                birthday.gender == 'M' ? 'Homme' : birthday.gender == 'F' ? 'Femme' : birthday.gender!),
          ],
          if (birthday.email != null && birthday.email!.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 24),
            _buildInfoRow(Icons.email_outlined, 'Email', birthday.email!),
          ],
          if (birthday.whatsapp != null && birthday.whatsapp!.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 24),
            _buildInfoRow(Icons.phone_outlined, 'WhatsApp', birthday.whatsapp!),
          ],
          if (birthday.notes != null && birthday.notes!.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 24),
            const Row(children: [
              Icon(Icons.note_alt_outlined, color: AppColors.textMutedDark, size: 20),
              SizedBox(width: 12),
              Text('Notes', style: TextStyle(color: AppColors.textMutedDark, fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            Text(birthday.notes!, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMutedDark, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection(BirthdayModel birthday) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Centres d'intérêt",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: birthday.interests.map((interest) {
            return Chip(
              label: Text(interest),
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
              side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPartySection(BirthdayModel birthday) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🎉 Fête & Célébration',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GlassCard(
          opacity: 0.12,
          blur: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (birthday.partyDate != null)
                _buildInfoRow(Icons.event, 'Date', birthday.partyDate!),
              if (birthday.partyTime != null && birthday.partyTime!.isNotEmpty) ...[
                if (birthday.partyDate != null) const Divider(color: Colors.white24, height: 24),
                _buildInfoRow(Icons.access_time, 'Heure', birthday.partyTime!),
              ],
              if (birthday.partyLocation != null && birthday.partyLocation!.isNotEmpty) ...[
                const Divider(color: Colors.white24, height: 24),
                _buildInfoRow(Icons.location_on_outlined, 'Lieu', birthday.partyLocation!),
              ],
              if (birthday.partyDescription != null && birthday.partyDescription!.isNotEmpty) ...[
                const Divider(color: Colors.white24, height: 24),
                const Text('Description', style: TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
                const SizedBox(height: 4),
                Text(birthday.partyDescription!, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
              ],
            ],
          ),
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
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.accentPurple, AppColors.accentPink]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppColors.accentPurple.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: ElevatedButton(
            onPressed: () => AiWishDialog.show(context, birthday.id, apiService),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🤖', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('Générer un vœu IA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/birthday/${birthday.id}/edit'),
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                label: const Text('Modifier', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(context, birthday),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                label: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
