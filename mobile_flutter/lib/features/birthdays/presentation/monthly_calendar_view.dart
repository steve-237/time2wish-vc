import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/quick_action_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glowing_badge.dart';

class MonthlyCalendarView extends StatefulWidget {
  final List<BirthdayModel> birthdays;

  const MonthlyCalendarView({
    super.key,
    required this.birthdays,
  });

  @override
  State<MonthlyCalendarView> createState() => _MonthlyCalendarViewState();
}

class _MonthlyCalendarViewState extends State<MonthlyCalendarView> {
  late DateTime _displayedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    DeviceService.triggerLightHaptic();
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    DeviceService.triggerLightHaptic();
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
      _selectedDay = null;
    });
  }

  void _jumpToToday() {
    DeviceService.triggerLightHaptic();
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month, 1);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  List<BirthdayModel> _getBirthdaysForDate(int day, int month) {
    return widget.birthdays.where((b) => b.birthdate.month == month && b.birthdate.day == day).toList();
  }

  List<BirthdayModel> _getBirthdaysForMonth(int month) {
    final list = widget.birthdays.where((b) => b.birthdate.month == month).toList();
    list.sort((a, b) => a.birthdate.day.compareTo(b.birthdate.day));
    return list;
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'FAMILLE':
        return AppColors.accentPurple;
      case 'AMIS':
        return AppColors.primaryCyan;
      case 'TRAVAIL':
        return AppColors.wishCoinsAmber;
      case 'AUTRE':
      default:
        return AppColors.accentPink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final isDark = settings.isDarkMode;
    final locale = settings.language;
    final now = DateTime.now();
    final isCurrentMonth = _displayedMonth.year == now.year && _displayedMonth.month == now.month;

    final monthBirthdays = _getBirthdaysForMonth(_displayedMonth.month);
    final displayedBirthdays = _selectedDay != null
        ? _getBirthdaysForDate(_selectedDay!.day, _selectedDay!.month)
        : monthBirthdays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Month Header Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              // Month & Year title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMM(locale).format(_displayedMonth).toUpperCase(),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? Colors.white : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${monthBirthdays.length} ${settings.tr('celebrations_count')} ${settings.tr('this_month').toLowerCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),

              // "Today" Button
              if (!isCurrentMonth || (_selectedDay != null && (_selectedDay!.day != now.day || _selectedDay!.month != now.month)))
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _jumpToToday,
                  icon: Icon(Icons.today_rounded, size: 14, color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo),
                  label: Text(
                    settings.tr('jump_today'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                    ),
                  ),
                ),
              const SizedBox(width: 8),

              // Navigation arrows
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      color: isDark ? Colors.white70 : AppColors.textMainLight,
                      onPressed: _previousMonth,
                    ),
                    Container(width: 1, height: 16, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      color: isDark ? Colors.white70 : AppColors.textMainLight,
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Calendar Grid Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Day of Week Header Row (Lun, Mar, Mer, Jeu, Ven, Sam, Dim)
                _buildDaysOfWeekHeader(isDark, locale),
                const SizedBox(height: 10),

                // Days Grid
                _buildMonthGrid(isDark, now),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // 3. Selected Day Inspector Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _selectedDay != null ? Icons.event_available_rounded : Icons.calendar_month_rounded,
                    size: 18,
                    color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDay != null
                        ? DateFormat('EEEE d MMMM', locale).format(_selectedDay!)
                        : '${settings.tr('celebrations_in_month')} ${DateFormat.MMMM(locale).format(_displayedMonth)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textMainLight,
                    ),
                  ),
                ],
              ),
              if (_selectedDay != null)
                GestureDetector(
                  onTap: () {
                    DeviceService.triggerLightHaptic();
                    setState(() => _selectedDay = null);
                  },
                  child: Text(
                    settings.tr('view_all'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.cyanLight : AppColors.primaryCyan,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 4. Birthdays List for selected day / month
        if (displayedBirthdays.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cake_outlined,
                    size: 32,
                    color: isDark ? AppColors.textMutedDark.withValues(alpha: 0.5) : AppColors.textMutedLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedDay != null ? settings.tr('no_birthdays_this_day') : settings.tr('no_birthdays_this_month'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: displayedBirthdays.length,
            itemBuilder: (context, index) {
              final b = displayedBirthdays[index];
              return _buildBirthdayCalendarCard(context, b, isDark, locale, settings);
            },
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDaysOfWeekHeader(bool isDark, String locale) {
    // Starting with Monday (ISO 8601 standard)
    final days = locale == 'fr'
        ? ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
        : locale == 'de'
            ? ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
            : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.asMap().entries.map((entry) {
        final isWeekend = entry.key >= 5;
        return Expanded(
          child: Center(
            child: Text(
              entry.value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isWeekend
                    ? (isDark ? AppColors.cyanLight : AppColors.primaryCyan)
                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthGrid(bool isDark, DateTime now) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final daysInPrevMonth = DateTime(year, month, 0).day;

    // DateTime.weekday: 1 = Monday, 7 = Sunday
    final startingWeekday = firstDayOfMonth.weekday; // 1 to 7

    final List<Widget> dayWidgets = [];

    // 1. Previous month trailing days
    for (int i = startingWeekday - 1; i > 0; i--) {
      final dayNumber = daysInPrevMonth - i + 1;
      dayWidgets.add(_buildDayCell(
        day: dayNumber,
        month: month == 1 ? 12 : month - 1,
        year: month == 1 ? year - 1 : year,
        isCurrentMonth: false,
        isDark: isDark,
        now: now,
      ));
    }

    // 2. Current month days
    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(_buildDayCell(
        day: day,
        month: month,
        year: year,
        isCurrentMonth: true,
        isDark: isDark,
        now: now,
      ));
    }

    // 3. Next month leading days to complete the 7-column grid
    final remainingCells = (7 - (dayWidgets.length % 7)) % 7;
    for (int day = 1; day <= remainingCells; day++) {
      dayWidgets.add(_buildDayCell(
        day: day,
        month: month == 12 ? 1 : month + 1,
        year: month == 12 ? year + 1 : year,
        isCurrentMonth: false,
        isDark: isDark,
        now: now,
      ));
    }

    // Group into 7-day rows
    final List<Widget> rows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayWidgets.sublist(i, i + 7),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildDayCell({
    required int day,
    required int month,
    required int year,
    required bool isCurrentMonth,
    required bool isDark,
    required DateTime now,
  }) {
    final cellDate = DateTime(year, month, day);
    final isToday = now.year == year && now.month == month && now.day == day;
    final isSelected = _selectedDay != null &&
        _selectedDay!.year == year &&
        _selectedDay!.month == month &&
        _selectedDay!.day == day;

    final birthdays = _getBirthdaysForDate(day, month);
    final hasBirthdays = birthdays.isNotEmpty;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          DeviceService.triggerLightHaptic();
          setState(() {
            if (isSelected) {
              _selectedDay = null; // Toggle off
            } else {
              _selectedDay = cellDate;
              // If user tapped a leading/trailing day outside viewed month, switch view
              if (!isCurrentMonth) {
                _displayedMonth = DateTime(year, month, 1);
              }
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? AppColors.primaryGradient
                : (isToday && !isSelected
                    ? LinearGradient(
                        colors: [
                          (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.2),
                          (isDark ? AppColors.cyanLight : AppColors.primaryCyan).withValues(alpha: 0.1),
                        ],
                      )
                    : null),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.6)
                  : (isToday
                      ? (isDark ? AppColors.cyanLight : AppColors.primaryCyan)
                      : (hasBirthdays && isCurrentMonth
                          ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                          : Colors.transparent)),
              width: isToday ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day number
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: (isToday || isSelected || hasBirthdays) ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (isCurrentMonth
                          ? (isToday
                              ? (isDark ? AppColors.cyanLight : AppColors.primaryCyan)
                              : (isDark ? Colors.white : AppColors.textMainLight))
                          : (isDark ? Colors.white24 : Colors.black26)),
                ),
              ),
              const SizedBox(height: 2),

              // Birthday indicators
              SizedBox(
                height: 5,
                child: hasBirthdays && isCurrentMonth
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: birthdays.take(3).map((b) {
                          final dotColor = isSelected ? Colors.white : _getCategoryColor(b.category);
                          return Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                              boxShadow: [
                                BoxShadow(
                                  color: dotColor.withValues(alpha: 0.6),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBirthdayCalendarCard(
    BuildContext context,
    BirthdayModel birthday,
    bool isDark,
    String locale,
    SettingsService settings,
  ) {
    final categoryColor = _getCategoryColor(birthday.category);
    final initial = birthday.name.isNotEmpty ? birthday.name[0].toUpperCase() : '🎂';
    final hasPhone = birthday.whatsapp != null && birthday.whatsapp!.trim().isNotEmpty;
    final phone = hasPhone ? birthday.whatsapp!.trim() : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            DeviceService.triggerLightHaptic();
            context.push('/birthday/${birthday.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: birthday.photoUrl != null && birthday.photoUrl!.isNotEmpty
                      ? ClipOval(
                          child: AvatarImage(
                            photoUrl: birthday.photoUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            fallback: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Name, date & category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              birthday.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textMainLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GlowingBadge(
                            label: birthday.category,
                            color: categoryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            DateFormat('d MMMM', locale).format(birthday.birthdate),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· ${settings.tr('fete_ses')} ${birthday.nextAge} ${settings.tr('turning_age')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Quick Action Button (Call or WhatsApp)
                if (hasPhone)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.2 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF25D366)),
                    ),
                    onPressed: () {
                      QuickActionService.sendWhatsApp(context, phone);
                    },
                    tooltip: 'WhatsApp',
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
