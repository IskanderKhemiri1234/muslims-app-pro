
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/prayer_times/presentation/controllers/prayer_controller.dart';
import 'features/prayer_times/presentation/widgets/countdown_widget.dart';

const Color primaryColor = Color(0xFF087F5B);
const Color darkGreen = Color(0xFF064E3B);
const Color backgroundColor = Color(0xFFF4F7F5);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MuslimsApp());
}

class MuslimsApp extends StatefulWidget {
  const MuslimsApp({super.key});

  @override
  State<MuslimsApp> createState() => _MuslimsAppState();
}

class _MuslimsAppState extends State<MuslimsApp> {
  bool isArabic = true;

  void toggleLanguage() {
    setState(() {
      isArabic = !isArabic;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrayerController(),
      child: MaterialApp(
        title: 'Muslims Pro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: backgroundColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryColor,
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: backgroundColor,
            foregroundColor: darkGreen,
            elevation: 0,
            centerTitle: false,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(
                color: Color(0xFFE8EEEA),
              ),
            ),
          ),
        ),
        home: PrayerHomePage(
          isArabic: isArabic,
          onLanguageToggle: toggleLanguage,
        ),
      ),
    );
  }
}

class PrayerHomePage extends StatelessWidget {
  const PrayerHomePage({
    super.key,
    required this.isArabic,
    required this.onLanguageToggle,
  });

  final bool isArabic;
  final VoidCallback onLanguageToggle;

  String get textDirectionLanguage =>
      isArabic ? 'العربية' : 'English';

  String t(String arabic, String english) {
    return isArabic ? arabic : english;
  }

  String prayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return t('الفجر', 'Fajr');
      case Prayer.sunrise:
        return t('الشروق', 'Sunrise');
      case Prayer.dhuhr:
        return t('الظهر', 'Dhuhr');
      case Prayer.asr:
        return t('العصر', 'Asr');
      case Prayer.maghrib:
        return t('المغرب', 'Maghrib');
      case Prayer.isha:
        return t('العشاء', 'Isha');
      default:
        return t('غير متاح', 'Unavailable');
    }
  }

  String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Consumer<PrayerController>(
        builder: (context, controller, child) {
          final prayerTimes = controller.prayerTimes;

          if (prayerTimes == null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: primaryColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t(
                        'جارٍ تجهيز مواقيت الصلاة...',
                        'Loading prayer times...',
                      ),
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final nextPrayer = controller.nextPrayer;
          final nextPrayerTime = controller.nextPrayerTime;

          final prayers = [
            Prayer.fajr,
            Prayer.sunrise,
            Prayer.dhuhr,
            Prayer.asr,
            Prayer.maghrib,
            Prayer.isha,
          ];

          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Muslims Pro',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: 12,
                  ),
                  child: TextButton.icon(
                    onPressed: onLanguageToggle,
                    icon: const Icon(
                      Icons.language_rounded,
                      size: 19,
                    ),
                    label: Text(
                      isArabic ? 'EN' : 'عربي',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // Location header
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: primaryColor,
                        size: 21,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          controller.city,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: darkGreen,
                          ),
                        ),
                      ),
                      Text(
                        t('مواقيت اليوم', 'Today'),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Next prayer card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          darkGreen,
                          Color(0xFF0B956B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.18),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t(
                                'الصلاة القادمة',
                                'NEXT PRAYER',
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Text(
                          nextPrayerTime == null
                              ? t(
                                  'لا توجد بيانات',
                                  'No prayer data',
                                )
                              : prayerName(nextPrayer),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        if (nextPrayerTime != null)
                          Text(
                            formatTime(nextPrayerTime),
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                t(
                                  'الوقت المتبقي للصلاة',
                                  'TIME REMAINING',
                                ),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              CountdownWidget(
                                controller: controller,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Prayer schedule heading
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t(
                            'مواقيت الصلاة',
                            'Prayer Schedule',
                          ),
                          style: const TextStyle(
                            color: darkGreen,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: primaryColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Prayer list
                  ...prayers.map((prayer) {
                    final time =
                        prayerTimes.timeForPrayer(prayer);

                    if (time == null) {
                      return const SizedBox.shrink();
                    }

                    final isNext =
                        prayer == nextPrayer;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isNext
                            ? const Color(0xFFE7F5EF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isNext
                              ? const Color(0xFFB8E4CF)
                              : const Color(0xFFE8EEEA),
                        ),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 5,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isNext
                                ? primaryColor
                                : const Color(0xFFEAF3EE),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.mosque_rounded,
                            color: isNext
                                ? Colors.white
                                : primaryColor,
                            size: 21,
                          ),
                        ),
                        title: Text(
                          prayerName(prayer),
                          style: TextStyle(
                            color: darkGreen,
                            fontSize: 16,
                            fontWeight: isNext
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isNext)
                              Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(
                                  end: 10,
                                ),
                                child: Text(
                                  t('القادمة', 'Next'),
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              formatTime(time),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: darkGreen,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 14),

                  // Location update button
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: controller.isLoadingLocation
                          ? null
                          : controller.updateLocation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(
                          color: primaryColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      icon: controller.isLoadingLocation
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                            ),
                      label: Text(
                        controller.isLoadingLocation
                            ? t(
                                'جارٍ تحديد الموقع...',
                                'Getting location...',
                              )
                            : t(
                                'استخدام موقعي الحالي',
                                'Use my current location',
                              ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (controller.message != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        controller.message!,
                        style: const TextStyle(
                          color: darkGreen,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      t(
                        'صلاتك أولويتك، أينما كنت.',
                        'Stay connected to your prayers, wherever you are.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
