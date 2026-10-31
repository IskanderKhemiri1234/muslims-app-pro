
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/prayer_controller.dart';

class PrayerSettingsPage extends StatelessWidget {
  const PrayerSettingsPage({
    super.key,
    required this.isArabic,
  });

  final bool isArabic;

  String t(String ar, String en) => isArabic ? ar : en;

  String methodName(CalculationMethod method) {
    const names = <CalculationMethod, List<String>>{
      CalculationMethod.muslim_world_league: [
        'رابطة العالم الإسلامي',
        'Muslim World League',
      ],
      CalculationMethod.egyptian: [
        'الهيئة المصرية العامة للمساحة',
        'Egyptian General Authority',
      ],
      CalculationMethod.karachi: [
        'جامعة العلوم الإسلامية - كراتشي',
        'University of Islamic Sciences, Karachi',
      ],
      CalculationMethod.umm_al_qura: [
        'أم القرى - مكة المكرمة',
        'Umm Al-Qura University',
      ],
      CalculationMethod.dubai: [
        'دبي',
        'Dubai',
      ],
      CalculationMethod.qatar: [
        'قطر',
        'Qatar',
      ],
      CalculationMethod.kuwait: [
        'الكويت',
        'Kuwait',
      ],
      CalculationMethod.singapore: [
        'سنغافورة',
        'Singapore',
      ],
      CalculationMethod.north_america: [
        'أمريكا الشمالية',
        'North America',
      ],
      CalculationMethod.turkey: [
        'تركيا',
        'Turkey',
      ],
      CalculationMethod.tehran: [
        'طهران',
        'Tehran',
      ],
      CalculationMethod.other: [
        'إعدادات مخصصة',
        'Other',
      ],
    };

    final labels = names[method];

    if (labels == null) {
      return method.name;
    }

    return labels[isArabic ? 0 : 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Directionality(
      textDirection:
          isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            t('إعدادات الصلاة', 'Prayer Settings'),
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
                  isArabic: isArabic,
                ),

                const SizedBox(height: 28),

                _SettingsHeader(
                  icon: Icons.calculate_rounded,
                  title: t(
                    'طريقة حساب المواقيت',
                    'Prayer Calculation Method',
                  ),
                  subtitle: t(
                    'اختر طريقة الحساب المعتمدة في منطقتك.',
                    'Choose the calculation method used in your region.',
                  ),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<CalculationMethod>(
                  initialValue: controller.method,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: t(
                      'طريقة الحساب',
                      'Calculation method',
                    ),
                  ),
                  items: CalculationMethod.values.map((method) {
                    return DropdownMenuItem<CalculationMethod>(
                      value: method,
                      child: Text(
                        methodName(method),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.changeMethod(value);
                    }
                  },
                ),

                const SizedBox(height: 30),

                _SettingsHeader(
                  icon: Icons.balance_rounded,
                  title: t(
                    'طريقة حساب صلاة العصر',
                    'Asr Calculation',
                  ),
                  subtitle: t(
                    'يحدد هذا الاختيار وقت صلاة العصر.',
                    'This setting determines the Asr prayer time.',
                  ),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<Madhab>(
                  initialValue: controller.madhab,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: t('المذهب', 'Madhab'),
                  ),
                  items: [
                    DropdownMenuItem<Madhab>(
                      value: Madhab.shafi,
                      child: Text(
                        t(
                          'الشافعي والمالكي والحنبلي',
                          'Shafi, Maliki and Hanbali',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<Madhab>(
                      value: Madhab.hanafi,
                      child: Text(
                        t('الحنفي', 'Hanafi'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.changeMadhab(value);
                    }
                  },
                ),

                const SizedBox(height: 28),

                _InformationCard(
                  textColor: textColor,
                  message: t(
                    'تختلف مواقيت الصلاة حسب الموقع الجغرافي وطريقة الحساب. للحصول على نتائج أدق، اختر الطريقة التي تعتمدها الجهة الإسلامية الموثوقة في منطقتك.',
                    'Prayer times vary according to geographical location and calculation method. For accurate results, choose the method recommended by a trusted Islamic authority in your region.',
                  ),
                ),

                if (controller.message != null) ...[
                  const SizedBox(height: 18),
                  _MessageCard(
                    message: controller.message!,
                  ),
                ],

                const SizedBox(height: 24),

                Center(
                  child: Text(
                    t(
                      'الإعدادات تحفظ تلقائيًا',
                      'Settings are saved automatically',
                    ),
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
    required this.isArabic,
  });

  final bool isArabic;

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
                  isArabic
                      ? 'صلاتك في وقتها'
                      : 'Prayer, on time',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isArabic
                      ? 'خصص مواقيت الصلاة لتناسب موقعك وطريقة الحساب التي تتبعها.'
                      : 'Customize prayer times for your location and preferred calculation method.',
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
