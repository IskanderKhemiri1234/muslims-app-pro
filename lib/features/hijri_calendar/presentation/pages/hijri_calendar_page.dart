import 'package:flutter/material.dart';

import '../../../../core/design_system/mumin_design_tokens.dart';
import '../../../../core/localization/mumin_hijri_localizations.dart';
import '../../../../core/localization/mumin_localizations.dart';
import '../../domain/models/hijri_calendar_day.dart';
import '../../domain/services/hijri_calendar_month_builder.dart';
import '../../domain/services/hijri_date_calculator.dart';

class HijriCalendarPage extends StatefulWidget {
  const HijriCalendarPage({
    super.key,
    required this.localizations,
  });

  final MuminLocalizations localizations;

  @override
  State<HijriCalendarPage> createState() =>
      _HijriCalendarPageState();
}

class _HijriCalendarPageState extends State<HijriCalendarPage> {
  late DateTime _today;
  late DateTime _anchorDate;
  late DateTime _selectedDate;

  bool get _isArabic => widget.localizations.languageCode == 'ar';

  bool get _isEnglish => widget.localizations.languageCode == 'en';

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(DateTime.now());
    _anchorDate = _today;
    _selectedDate = _today;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  HijriDate get _visibleHijriDate {
    return HijriDateCalculator.fromGregorian(_anchorDate);
  }

  List<HijriCalendarDay> get _calendarDays {
    return HijriCalendarMonthBuilder.build(
      anchorDate: _anchorDate,
      today: _today,
      selectedDate: _selectedDate,
    );
  }

  List<String> get _weekdays {
    if (_isArabic) {
      return const [
        'الإثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
        'الأحد',
      ];
    }

    if (_isEnglish) {
      return const [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ];
    }

    return const [
      'Lun',
      'Mar',
      'Mer',
      'Jeu',
      'Ven',
      'Sam',
      'Dim',
    ];
  }

  String get _selectedDateLabel {
    final date = HijriDateCalculator.fromGregorian(_selectedDate);
    final monthName = MuminHijriLocalizations.monthName(
      widget.localizations,
      date.month,
    );

    return '${date.day} $monthName ${date.year} AH';
  }

  void _changeMonth(int offset) {
    setState(() {
      _anchorDate = DateTime(
        _anchorDate.year,
        _anchorDate.month,
        _anchorDate.day + (offset * 30),
      );
    });
  }

  void _goToToday() {
    setState(() {
      _today = _dateOnly(DateTime.now());
      _anchorDate = _today;
      _selectedDate = _today;
    });
  }

  void _selectDay(HijriCalendarDay day) {
    setState(() {
      _selectedDate = day.dateOnly;

      if (!day.isCurrentMonth) {
        _anchorDate = day.dateOnly;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final foreground = MuminColors.primaryText(brightness);
    final secondary = MuminColors.secondaryText(brightness);
    final surface = MuminColors.surface(brightness);
    final border = MuminColors.border(brightness);
    final hijri = _visibleHijriDate;

    final todayHijri = HijriDateCalculator.fromGregorian(_today);

    return Directionality(
      textDirection: widget.localizations.isRightToLeft
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MuminColors.background(brightness),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            MuminHijriLocalizations.title(widget.localizations),
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          iconTheme: IconThemeData(color: foreground),
          actions: [
            IconButton(
              tooltip: _isArabic
                  ? 'العودة إلى اليوم'
                  : _isEnglish
                      ? 'Go to today'
                      : 'Revenir à aujourd’hui',
              onPressed: _goToToday,
              icon: const Icon(Icons.today_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              _HijriMonthHero(
                monthName: MuminHijriLocalizations.monthName(
                  widget.localizations,
                  hijri.month,
                ),
                year: hijri.year,
                todayLabel: MuminHijriLocalizations.todayLabel(
                  widget.localizations,
                ),
                todayDate: todayHijri,
                todayMonthName: MuminHijriLocalizations.monthName(
                  widget.localizations,
                  todayHijri.month,
                ),
                todayYear: todayHijri.year,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: border),
                  boxShadow: isDark
                      ? MuminElevation.darkCard
                      : MuminElevation.lightCard,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: _isArabic
                              ? 'الشهر السابق'
                              : _isEnglish
                                  ? 'Previous month'
                                  : 'Mois précédent',
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                          ),
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: MuminMotion.normal,
                            child: Text(
                              '${MuminHijriLocalizations.monthName(widget.localizations, hijri.month)} ${hijri.year}',
                              key: ValueKey(
                                '${hijri.year}-${hijri.month}',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: _isArabic
                              ? 'الشهر التالي'
                              : _isEnglish
                                  ? 'Next month'
                                  : 'Mois suivant',
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _weekdays.map((weekday) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              weekday,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                color: secondary,
                                fontSize: _isArabic ? 10 : 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: MuminMotion.normal,
                      child: _CalendarGrid(
                        key: ValueKey(
                          '${hijri.year}-${hijri.month}',
                        ),
                        days: _calendarDays,
                        onSelect: _selectDay,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(
                          color: MuminColors.gold,
                          label: _isArabic
                              ? 'اليوم'
                              : _isEnglish
                                  ? 'Today'
                                  : 'Aujourd’hui',
                          textColor: secondary,
                        ),
                        const SizedBox(width: 18),
                        _LegendDot(
                          color: MuminColors.emeraldLight,
                          label: _isArabic
                              ? 'المحدد'
                              : _isEnglish
                                  ? 'Selected'
                                  : 'Sélectionné',
                          textColor: secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? MuminGradients.midnight
                      : MuminGradients.lightSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: MuminColors.gold.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: MuminColors.gold.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: MuminColors.gold,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isArabic
                                ? 'التاريخ المحدد'
                                : _isEnglish
                                    ? 'Selected date'
                                    : 'Date sélectionnée',
                            style: TextStyle(
                              color: MuminColors.secondaryText(
                                brightness,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _selectedDateLabel,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            MaterialLocalizations.of(context)
                                .formatMediumDate(_selectedDate),
                            style: TextStyle(
                              color: secondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MuminColors.gold.withValues(
                    alpha: isDark ? 0.09 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: MuminColors.goldDark,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        MuminHijriLocalizations.estimatedLabel(
                          widget.localizations,
                        ),
                        style: TextStyle(
                          color: foreground,
                          height: 1.5,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HijriMonthHero extends StatelessWidget {
  const _HijriMonthHero({
    required this.monthName,
    required this.year,
    required this.todayLabel,
    required this.todayDate,
    required this.todayMonthName,
    required this.todayYear,
  });

  final String monthName;
  final int year;
  final String todayLabel;
  final HijriDate todayDate;
  final String todayMonthName;
  final int todayYear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: MuminGradients.emerald,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: MuminColors.gold.withValues(alpha: 0.5),
        ),
        boxShadow: MuminElevation.emeraldGlow,
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -8,
            top: -12,
            child: Icon(
              Icons.nightlight_round,
              size: 100,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                todayLabel,
                style: const TextStyle(
                  color: MuminColors.goldLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${todayDate.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '$todayMonthName $todayYear AH',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 1,
                width: 75,
                color: MuminColors.gold.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 12),
              Text(
                '$monthName $year AH',
                style: const TextStyle(
                  color: MuminColors.goldLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    super.key,
    required this.days,
    required this.onSelect,
  });

  final List<HijriCalendarDay> days;
  final ValueChanged<HijriCalendarDay> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 7,
        crossAxisSpacing: 3,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final day = days[index];

        final background = day.isSelected
            ? MuminColors.emerald
            : day.isToday
                ? MuminColors.gold.withValues(alpha: 0.17)
                : Colors.transparent;

        final foreground = day.isSelected
            ? Colors.white
            : day.isToday
                ? MuminColors.goldDark
                : day.isCurrentMonth
                    ? MuminColors.primaryText(
                        Theme.of(context).brightness,
                      )
                    : MuminColors.mutedText.withValues(
                        alpha: 0.55,
                      );

        return Semantics(
          button: true,
          selected: day.isSelected,
          label:
              '${day.hijriDate.day}/${day.hijriDate.month}/${day.hijriDate.year}',
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => onSelect(day),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: day.isToday && !day.isSelected
                      ? Border.all(
                          color: MuminColors.gold.withValues(
                            alpha: 0.65,
                          ),
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.hijriDate.day}',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: day.isToday || day.isSelected
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.textColor,
  });

  final Color color;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
