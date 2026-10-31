import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class ReminderSettingsSheet extends StatefulWidget {
  const ReminderSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ReminderSettingsSheet(),
    );
  }

  @override
  State<ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends State<ReminderSettingsSheet> {
  bool _isLoading = true;
  bool _enabled = true;
  int _hour = 9;
  int _minute = 0;
  bool _j7 = true;
  bool _j3 = true;
  bool _j1 = true;
  bool _day0 = true;
  bool _sound = true;
  bool _vibration = true;

  List<ScheduledReminder> _scheduledReminders = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationService.getSettings();
    final reminders = await NotificationService.getAllReminders();

    if (mounted) {
      setState(() {
        _enabled = settings['enabled'] as bool;
        _hour = settings['hour'] as int;
        _minute = settings['minute'] as int;
        _j7 = settings['j7'] as bool;
        _j3 = settings['j3'] as bool;
        _j1 = settings['j1'] as bool;
        _day0 = settings['day0'] as bool;
        _sound = settings['sound'] as bool;
        _vibration = settings['vibration'] as bool;
        _scheduledReminders = reminders;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickTime(BuildContext context, bool isDark) async {
    final initial = TimeOfDay(hour: _hour, minute: _minute);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  Future<void> _saveAndApply() async {
    await NotificationService.saveSettings(
      enabled: _enabled,
      hour: _hour,
      minute: _minute,
      j7: _j7,
      j3: _j3,
      j1: _j1,
      day0: _day0,
      sound: _sound,
      vibration: _vibration,
    );

    if (!mounted) return;
    final birthdayService = context.read<BirthdayService>();
    await NotificationService.rescheduleAll(birthdayService.birthdays);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Paramètres de rappels enregistrés avec succès !'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendTestPush() async {
    final reminder = await NotificationService.sendTestNotification(
      title: '🎉 Notification Push Test · Time2Wish',
      message: 'Rappel configuré avec succès ! Les alertes se déclencheront à ${_formatTime()}.',
    );

    final reminders = await NotificationService.getAllReminders();
    if (mounted) {
      setState(() {
        _scheduledReminders = reminders;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '✓ Notification test envoyée : "${reminder.title}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4F46E5),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatTime() {
    final h = _hour.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final isDark = settings.isDarkMode;

    final primaryColor = isDark ? AppColors.indigoLight : AppColors.primaryIndigo;
    final surfaceColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textMain = isDark ? Colors.white : AppColors.textMainLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: borderColor, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_active_rounded, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configuration des Rappels & Push',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        // Master Switch Card
                        GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Activer les rappels d\'anniversaire',
                              style: TextStyle(fontWeight: FontWeight.bold, color: textMain),
                            ),
                            subtitle: Text(
                              'Recevoir des notifications avant et le jour de l\'événement',
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                            value: _enabled,
                            activeTrackColor: primaryColor,
                            onChanged: (val) => setState(() => _enabled = val),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Time Picker Card
                        GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Heure quotidienne du rappel',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: textMain),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Heure à laquelle vous recevrez l\'alerte',
                                    style: TextStyle(fontSize: 12, color: textMuted),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _enabled ? () => _pickTime(context, isDark) : null,
                                icon: const Icon(Icons.access_time_rounded, size: 16),
                                label: Text(
                                  _formatTime(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Notice Deadlines Section
                        Text(
                          'Délais de notification',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),

                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: Column(
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Jour J (Le jour de l\'anniversaire) 🎉', style: TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.w600)),
                                subtitle: Text('Alerte le matin à ${_formatTime()}', style: TextStyle(color: textMuted, fontSize: 11)),
                                value: _day0,
                                activeTrackColor: primaryColor,
                                onChanged: _enabled ? (val) => setState(() => _day0 = val) : null,
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('J-1 (La veille au soir) ⏰', style: TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.w600)),
                                subtitle: Text('Pour être fin prêt la veille', style: TextStyle(color: textMuted, fontSize: 11)),
                                value: _j1,
                                activeTrackColor: primaryColor,
                                onChanged: _enabled ? (val) => setState(() => _j1 = val) : null,
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('J-3 (3 jours avant) ⏳', style: TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.w600)),
                                subtitle: Text('Idéal pour trouver un cadeau ou écrire un mot', style: TextStyle(color: textMuted, fontSize: 11)),
                                value: _j3,
                                activeTrackColor: primaryColor,
                                onChanged: _enabled ? (val) => setState(() => _j3 = val) : null,
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('J-7 (1 semaine avant) 🎁', style: TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.w600)),
                                subtitle: Text('Pour planifier une fête ou organiser une cagnotte', style: TextStyle(color: textMuted, fontSize: 11)),
                                value: _j7,
                                activeTrackColor: primaryColor,
                                onChanged: _enabled ? (val) => setState(() => _j7 = val) : null,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Alert Options
                        Text(
                          'Options d\'alerte',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),

                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: Column(
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Sonnerie & notification sonore 🔊', style: TextStyle(color: textMain, fontSize: 14)),
                                value: _sound,
                                activeTrackColor: primaryColor,
                                onChanged: _enabled ? (val) => setState(() => _sound = val) : null,
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Vibration 📳', style: TextStyle(color: textMain, fontSize: 14)),
                                value: _vibration,
                                activeTrackColor: primaryColor,
                                onChanged: _enabled ? (val) => setState(() => _vibration = val) : null,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Test Notification Action
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                          ),
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: primaryColor,
                            ),
                            onPressed: _sendTestPush,
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text(
                              '🔔 Envoyer une notification push de test',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Scheduled Reminders Preview
                        if (_scheduledReminders.isNotEmpty) ...[
                          Text(
                            'Rappels programmés récents (${_scheduledReminders.length})',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._scheduledReminders.take(4).map((rem) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.event_note_rounded, size: 16, color: primaryColor),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rem.title,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textMain),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('dd MMMM yyyy à HH:mm').format(rem.scheduledDate),
                                          style: TextStyle(color: textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: rem.isTriggered ? AppColors.successGreen.withValues(alpha: 0.15) : primaryColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      rem.type,
                                      style: TextStyle(
                                        color: rem.isTriggered ? AppColors.successGreen : primaryColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 20),

                        // Save Button
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _saveAndApply,
                            child: const Text(
                              'Enregistrer les préférences',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
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
