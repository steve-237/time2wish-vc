import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/models/astrology_model.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/astrology_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class ZodiacCompatibilitySheet extends StatefulWidget {
  final BirthdayModel birthday;
  final AstrologyInsight insight;

  const ZodiacCompatibilitySheet({
    super.key,
    required this.birthday,
    required this.insight,
  });

  static void show(BuildContext context, BirthdayModel birthday, AstrologyInsight insight) {
    DeviceService.triggerMediumHaptic();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ZodiacCompatibilitySheet(
        birthday: birthday,
        insight: insight,
      ),
    );
  }

  @override
  State<ZodiacCompatibilitySheet> createState() => _ZodiacCompatibilitySheetState();
}

class _ZodiacCompatibilitySheetState extends State<ZodiacCompatibilitySheet> {
  BirthdayModel? _selectedPartner;
  ZodiacCompatibility? _compatibility;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bService = context.read<BirthdayService>();
      final others = bService.birthdays.where((b) => b.id != widget.birthday.id).toList();
      if (others.isNotEmpty) {
        setState(() {
          _selectedPartner = others.first;
          _computeCompatibility();
        });
      }
    });
  }

  void _computeCompatibility() {
    if (_selectedPartner == null) return;
    final settings = context.read<SettingsService>();
    final comp = AstrologyService.computeLocalCompatibility(
      widget.birthday.birthdate,
      _selectedPartner!.birthdate,
      lang: settings.language,
    );
    setState(() {
      _compatibility = comp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final birthdayService = context.watch<BirthdayService>();
    final isDark = settings.isDarkMode;

    final others = birthdayService.birthdays.where((b) => b.id != widget.birthday.id).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 40,
        left: 16,
        right: 16,
      ),
      child: GlassCard(
        blurAmount: 24,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compatibilité Cosmique',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Synergie astrale entre deux célébrations',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Partner Selector Dropdown / Row
            if (others.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Text(
                  'Ajoutez d\'autres contacts pour calculer leur compatibilité cosmique avec ${widget.birthday.name}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 13),
                ),
              ),
            ] else ...[
              Text(
                'Comparer ${widget.birthday.name} (${widget.insight.westernSign} ${widget.insight.westernEmoji}) avec :',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textLight : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardElevated : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<BirthdayModel>(
                    value: _selectedPartner,
                    isExpanded: true,
                    dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white70 : Colors.black87),
                    items: others.map((b) {
                      final partnerInsight = AstrologyService.computeLocalInsights(b.birthdate, lang: settings.language);
                      return DropdownMenuItem<BirthdayModel>(
                        value: b,
                        child: Text(
                          '${b.name} (${partnerInsight.westernSign} ${partnerInsight.westernEmoji})',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.textMainLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newPartner) {
                      if (newPartner != null) {
                        DeviceService.triggerLightHaptic();
                        setState(() {
                          _selectedPartner = newPartner;
                          _computeCompatibility();
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Synergy Result Box
              if (_compatibility != null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF2E1065), const Color(0xFF1E1B4B)]
                          : [const Color(0xFFEDE9FE), const Color(0xFFE0E7FF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.2 : 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Dual Signs & Score Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSignBadge(
                            widget.insight.westernSign,
                            widget.insight.westernEmoji,
                            widget.insight.element,
                            isDark,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    '${_compatibility!.compatibilityScore}%',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('✨', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          _buildSignBadge(
                            _compatibility!.sign2,
                            _compatibility!.sign2Emoji,
                            _compatibility!.elementHarmony.split('+').last.replaceAll(')', '').trim(),
                            isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Harmony Title
                      Text(
                        _compatibility!.elementHarmony,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Synergy Description
                      Text(
                        _compatibility!.synergyDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textMainLight,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tip
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.white60,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _compatibility!.tipForHarmony,
                                style: TextStyle(
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignBadge(String name, String emoji, String element, bool isDark) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white12 : Colors.white,
            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4), width: 1.5),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textMainLight,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
