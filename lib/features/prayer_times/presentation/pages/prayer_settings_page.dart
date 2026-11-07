
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/localization/mumin_prayer_settings_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/prayer_controller.dart';

class PrayerSettingsPage extends StatelessWidget {
  const PrayerSettingsPage({super.key});

  String _methodName(
    MuminLocalizations localizations,
    CalculationMethod method,
  ) {
    final key = switch (method) {
      CalculationMethod.muslim_world_league =>
        'calculation_muslim_world_league',
      CalculationMethod.egyptian =>
        'calculation_egyptian',
      CalculationMethod.karachi =>
        'calculation_karachi',
      CalculationMethod.umm_al_qura =>
        'calculation_umm_al_qura',
      CalculationMethod.dubai =>
        'calculation_dubai',
      CalculationMethod.qatar =>
        'calculation_qatar',
      CalculationMethod.kuwait =>
        'calculation_kuwait',
      CalculationMethod.singapore =>
        'calculation_singapore',
      CalculationMethod.north_america =>
        'calculation_north_america',
      CalculationMethod.turkey =>
        'calculation_turkey',
      CalculationMethod.tehran =>
        'calculation_tehran',
      CalculationMethod.moon_sighting_committee =>
        'calculation_moon_sighting_committee',
      CalculationMethod.other =>
        'calculation_other',
    };

    return localizations.prayerSettingsText(key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final localizations = MuminLocalizations.fromCode(
      Localizations.localeOf(context).languageCode,
    );

    final direction = localizations.isRightToLeft
        ? TextDirection.rtl
        : TextDirection.ltr;

    String t(String key) =>
        localizations.prayerSettingsText(key);

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            t('prayer_settings_title'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<PrayerController>(
          builder: (context, controller, child) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                35,
              ),
              children: [
                _SettingsIntro(
                  title: t('prayer_settings_intro_title'),
                  description:
                      t('prayer_settings_intro_description'),
                ),
                const SizedBox(height: 28),
                _SettingsHeader(
                  icon: Icons.calculate_rounded,
                  title: t(
                    'prayer_settings_calculation_section',
                  ),
                  subtitle: t(
                    'prayer_settings_calculation_description',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CalculationMethod>(
                  key: ValueKey(
                    'method_${controller.method.name}',
                  ),
                  initialValue: controller.method,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: t(
                      'prayer_settings_calculation_label',
                    ),
                  ),
                  items: CalculationMethod.values.map((method) {
                    return DropdownMenuItem<CalculationMethod>(
                      value: method,
                      child: Text(
                        _methodName(localizations, method),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(growable: false),
                  onChanged: controller.isLoadingLocation
                      ? null
                      : (value) {
                          if (value != null) {
                            controller.changeMethod(value);
                          }
                        },
                ),
                const SizedBox(height: 30),
                _SettingsHeader(
                  icon: Icons.balance_rounded,
                  title: t('prayer_settings_asr_section'),
                  subtitle:
                      t('prayer_settings_asr_description'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Madhab>(
                  key: ValueKey(
                    'madhab_${controller.madhab.name}',
                  ),
                  initialValue: controller.madhab,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: t('prayer_settings_madhab_label'),
                  ),
                  items: [
                    DropdownMenuItem<Madhab>(
                      value: Madhab.shafi,
                      child: Text(
                        t('prayer_settings_madhab_shafi_group'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<Madhab>(
                      value: Madhab.hanafi,
                      child: Text(
                        t('prayer_settings_madhab_hanafi'),
                      ),
                    ),
                  ],
                  onChanged: controller.isLoadingLocation
                      ? null
                      : (value) {
                          if (value != null) {
                            controller.changeMadhab(value);
                          }
                        },
                ),
                const SizedBox(height: 28),
                _InformationCard(
                  textColor: textColor,
                  message: t('prayer_settings_information'),
                ),
                if (controller.timezoneId != null) ...[
                  const SizedBox(height: 18),
                  _TimezoneCard(
                    timezoneId: controller.timezoneId!,
                    title: t('prayer_settings_timezone_title'),
                  ),
                ],
                if (controller.message != null) ...[
                  const SizedBox(height: 18),
                  _MessageCard(
                    message: controller.message!,
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    t('prayer_settings_auto_save'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.48),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.emerald.withValues(alpha: 0.055),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: AppColors.emerald.withValues(alpha: 0.22),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: AppColors.gold,
          width: 1.5,
        ),
      ),
    );
  }
}

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.emerald,
            AppColors.deepGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mosque_rounded,
            color: AppColors.goldLight,
            size: 42,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.gold,
            size: 23,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.58),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.textColor,
    required this.message,
  });

  final Color textColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.gold,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                height: 1.7,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimezoneCard extends StatelessWidget {
  const _TimezoneCard({
    required this.timezoneId,
    required this.title,
  });

  final String timezoneId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.emerald.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.public_rounded,
            color: AppColors.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.65),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timezoneId,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.orange,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
