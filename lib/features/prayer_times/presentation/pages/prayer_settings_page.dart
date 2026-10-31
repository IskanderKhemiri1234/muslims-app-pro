
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
        'جامعة العلوم الإسلامية – كراتشي',
        'University of Islamic Sciences, Karachi',
      ],
      CalculationMethod.umm_al_qura: [
        'أم القرى – مكة المكرمة',
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
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('إعدادات الصلاة', 'Prayer Settings')),
          centerTitle: true,
        ),
        body: Consumer<PrayerController>(
          builder: (context, controller, child) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SettingsHeader(
                  icon: Icons.calculate_rounded,
                  title: t(
                    'طريقة حساب المواقيت',
                    'Prayer Calculation Method',
                  ),
                  subtitle: t(
                    'اختر الطريقة المعتمدة في بلدك.',
                    'Choose the calculation method used in your region.',
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<CalculationMethod>(
                  value: controller.method,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: t('طريقة الحساب', 'Calculation method'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
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
                    'يؤثر هذا الاختيار على توقيت صلاة العصر.',
                    'This setting changes the Asr prayer time.',
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<Madhab>(
                  value: controller.madhab,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: t('المذهب', 'Madhab'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: Madhab.shafi,
                      child: Text(
                        t('الشافعي والمالكي والحنبلي', 'Shafi, Maliki and Hanbali'),
                      ),
                    ),
                    DropdownMenuItem(
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

                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t(
                            'تختلف مواقيت الصلاة باختلاف الموقع وطريقة الحساب. اختر الإعدادات التي تعتمدها الجهة الإسلامية الموثوقة في منطقتك.',
                            'Prayer times vary by location and calculation method. Choose the settings recommended by a trusted Islamic authority in your region.',
                          ),
                          style: TextStyle(
                            color: textColor,
                            height: 1.6,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (controller.message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    controller.message!,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 12),
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
                  color: textColor.withValues(alpha: 0.6),
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
