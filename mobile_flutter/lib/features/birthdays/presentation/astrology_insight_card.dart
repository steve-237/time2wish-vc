import 'package:flutter/material.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/models/astrology_model.dart';
import '../../../core/services/astrology_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/theme/app_theme.dart';
import 'zodiac_compatibility_sheet.dart';

class AstrologyInsightCard extends StatelessWidget {
  final BirthdayModel birthday;
  final SettingsService settings;
  final bool isDark;

  const AstrologyInsightCard({
    super.key,
    required this.birthday,
    required this.settings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final insight = AstrologyService.computeLocalInsights(
      birthday.birthdate,
      lang: settings.language,
    );

    // Color theme based on Western element
    Color elementColor;
    Color elementBg;
    switch (insight.element.toLowerCase()) {
      case 'feu':
      case 'fire':
        elementColor = AppColors.accentCoral;
        elementBg = AppColors.accentCoral.withValues(alpha: isDark ? 0.2 : 0.12);
        break;
      case 'eau':
      case 'water':
        elementColor = isDark ? AppColors.cyanLight : AppColors.primaryCyan;
        elementBg = (isDark ? AppColors.cyanLight : AppColors.primaryCyan).withValues(alpha: isDark ? 0.2 : 0.12);
        break;
      case 'terre':
      case 'earth':
        elementColor = const Color(0xFF10B981);
        elementBg = const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12);
        break;
      case 'air':
      default:
        elementColor = isDark ? AppColors.indigoLight : AppColors.primaryIndigo;
        elementBg = (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: isDark ? 0.2 : 0.12);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF171938), const Color(0xFF1F1B3C)]
              : [const Color(0xFFF8F7FF), const Color(0xFFEEF2FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.16 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Cosmic Badge & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.tr('astrology_insights'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${insight.westernDateRange} · ${insight.rulingPlanet}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // Element Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: elementBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: elementColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: elementColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        insight.element,
                        style: TextStyle(
                          color: elementColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dual Zodiac Showcase (Western & Chinese)
            Row(
              children: [
                // Western Sign Showcase
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(insight.westernEmoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                insight.westernSign,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : AppColors.textMainLight,
                                ),
                              ),
                              Text(
                                'Zodiaque Occidental',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Chinese Sign Showcase
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(insight.chineseEmoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${insight.chineseAnimal} ${insight.chineseElement}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppColors.textMainLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Signe Chinois (${insight.polarity})',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Personality Traits Wrap
            if (insight.personalityTraits.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: insight.personalityTraits.map((trait) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⭐ $trait',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Lucky Attributes Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.casino_outlined, size: 14, color: AppColors.wishCoinsAmber),
                      const SizedBox(width: 5),
                      Text(
                        '${settings.tr('lucky_numbers')}: ${insight.luckyNumbers.join(', ')}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textLight : AppColors.textMainLight,
                        ),
                      ),
                    ],
                  ),
                  if (insight.luckyDays.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 5),
                        Text(
                          '${settings.tr('lucky_day')}: ${insight.luckyDays.first}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textLight : AppColors.textMainLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Celebration Horoscope Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2E1065).withValues(alpha: 0.5), const Color(0xFF1E1B4B).withValues(alpha: 0.5)]
                      : [const Color(0xFFF3E8FF), const Color(0xFFEEF2FF)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        settings.tr('celebration_horoscope'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    insight.celebrationHoroscope,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? Colors.white70 : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '💬 « ${insight.dailyAffirmation} »',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Compatibility Test Button
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                ZodiacCompatibilitySheet.show(context, birthday, insight);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flare_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      settings.tr('compatibility_test'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
