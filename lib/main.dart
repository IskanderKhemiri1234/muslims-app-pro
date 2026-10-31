
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/prayer_times/presentation/controllers/prayer_controller.dart';

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
  bool isDark = true;

  void toggleLanguage() {
    setState(() {
      isArabic = !isArabic;
    });
  }

  void toggleTheme() {
    setState(() {
      isDark = !isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrayerController(),
      child: MaterialApp(
        title: 'Muslims Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: PrayerHomePage(
          isArabic: isArabic,
          onLanguageToggle: toggleLanguage,
          isDark: isDark,
          onThemeToggle: toggleTheme,
        ),
      ),
    );
  }
}
