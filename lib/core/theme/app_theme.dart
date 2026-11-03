
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Muslims Pro - Centralized Design System.
///
/// Provides a consistent visual identity across:
/// - Light mode
/// - Dark mode
/// - Buttons
/// - Input fields
/// - Cards and surfaces
/// - Navigation
/// - Dialogs and bottom sheets
class AppTheme {
  AppTheme._();

  // ============================================================
  // DESIGN CONSTANTS
  // ============================================================

  static const double _radiusSmall = 12;
  static const double _radiusMedium = 16;
  static const double _radiusLarge = 22;
  static const double _radiusExtraLarge = 28;

  // ============================================================
  // DARK THEME
  // ============================================================

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.emeraldLight,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.deepGreen,
      surface: AppColors.darkSurface,
      onSurface: AppColors.textLight,
      error: const Color(0xFFFF6B6B),
      onError: Colors.white,
    );

    return _buildTheme(
      scheme: scheme,
      brightness: Brightness.dark,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      surfaceVariant: AppColors.darkSurfaceLight,
      foreground: AppColors.textLight,
      border: AppColors.border,
    );
  }

  // ============================================================
  // LIGHT THEME
  // ============================================================

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.emerald,
      secondary: AppColors.gold,
      onSecondary: AppColors.deepGreen,
      surface: AppColors.lightBackground,
      onSurface: AppColors.textDark,
    );

    return _buildTheme(
      scheme: scheme,
      brightness: Brightness.light,
      background: AppColors.lightBackground,
      surface: Colors.white,
      surfaceVariant: const Color(0xFFF3F6F2),
      foreground: AppColors.textDark,
      border: const Color(0xFFE1E8E0),
    );
  }

  // ============================================================
  // THEME BUILDER
  // ============================================================

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color foreground,
    required Color border,
  }) {
    final isDark = brightness == Brightness.dark;

    final mutedText = foreground.withValues(
      alpha: isDark ? 0.70 : 0.65,
    );

    final roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radiusMedium),
      borderSide: BorderSide(
        color: border,
        width: 1,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radiusMedium),
      borderSide: BorderSide(
        color: scheme.primary,
        width: 1.7,
      ),
    );

    final baseTextTheme = Typography.material2021(
      platform: TargetPlatform.android,
    );

    final textTheme = (isDark
            ? baseTextTheme.white
            : baseTextTheme.black)
        .apply(
          bodyColor: foreground,
          displayColor: foreground,
        )
        .copyWith(
          headlineLarge: TextStyle(
            color: foreground,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
          headlineMedium: TextStyle(
            color: foreground,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
          titleLarge: TextStyle(
            color: foreground,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: foreground,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: foreground,
            fontSize: 16,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            color: foreground,
            fontSize: 14,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            color: mutedText,
            fontSize: 12,
            height: 1.5,
          ),
          labelLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,

      // ========================================================
      // GLOBAL
      // ========================================================

      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: border,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      applyElevationOverlayColor: isDark,

      materialTapTargetSize: MaterialTapTargetSize.padded,

      // ========================================================
      // APP BAR
      // ========================================================

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        iconTheme: IconThemeData(
          color: foreground,
          size: 23,
        ),
      ),

      // ========================================================
      // TYPOGRAPHY
      // ========================================================

      textTheme: textTheme,

      // ========================================================
      // CARDS
      // ========================================================

      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(
          alpha: isDark ? 0.12 : 0.045,
        ),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
          side: BorderSide(
            color: border.withValues(
              alpha: isDark ? 0.65 : 0.8,
            ),
          ),
        ),
      ),

      // ========================================================
      // BUTTONS
      // ========================================================

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(
            alpha: 0.35,
          ),
          disabledForegroundColor: scheme.onPrimary.withValues(
            alpha: 0.65,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          minimumSize: const Size(48, 50),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMedium),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(
            color: scheme.primary.withValues(alpha: 0.65),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 15,
          ),
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMedium),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall),
          ),
        ),
      ),

      // ========================================================
      // INPUT FIELDS
      // ========================================================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        hintStyle: TextStyle(
          color: mutedText,
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: mutedText,
          fontSize: 14,
        ),
        prefixIconColor: mutedText,
        suffixIconColor: mutedText,
        border: roundedBorder,
        enabledBorder: roundedBorder,
        focusedBorder: focusedBorder,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
          borderSide: const BorderSide(
            color: Color(0xFFFF6B6B),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
          borderSide: const BorderSide(
            color: Color(0xFFFF6B6B),
            width: 1.7,
          ),
        ),
      ),

      // ========================================================
      // ICON BUTTONS
      // ========================================================

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: foreground,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall),
          ),
        ),
      ),

      // ========================================================
      // FLOATING ACTION BUTTON
      // ========================================================

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
        ),
      ),

      // ========================================================
      // NAVIGATION
      // ========================================================

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 72,
        indicatorColor: scheme.primary.withValues(
          alpha: isDark ? 0.22 : 0.12,
        ),
        labelBehavior:
            NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) {
            return IconThemeData(
              size: 23,
              color: states.contains(WidgetState.selected)
                  ? scheme.primary
                  : mutedText,
            );
          },
        ),
        labelTextStyle:
            WidgetStateProperty.resolveWith<TextStyle>(
          (states) {
            return TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? scheme.primary
                  : mutedText,
            );
          },
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: mutedText,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ========================================================
      // DIALOGS
      // ========================================================

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusExtraLarge),
        ),
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: mutedText,
          fontSize: 14,
          height: 1.6,
        ),
      ),

      // ========================================================
      // BOTTOM SHEETS
      // ========================================================

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        modalElevation: 12,
        showDragHandle: true,
        dragHandleColor: mutedText.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_radiusExtraLarge),
          ),
        ),
      ),

      // ========================================================
      // SNACKBARS
      // ========================================================

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceLight
            : AppColors.deepGreen,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
        ),
      ),

      // ========================================================
      // DIVIDERS
      // ========================================================

      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // ========================================================
      // PROGRESS INDICATORS
      // ========================================================

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: border,
        circularTrackColor: border,
        linearMinHeight: 6,
        refreshBackgroundColor: surface,
      ),

      // ========================================================
      // SELECTION CONTROLS
      // ========================================================

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return null;
          },
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimary;
            }
            return null;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return surfaceVariant;
          },
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: border,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),

      // ========================================================
      // TABS
      // ========================================================

      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: mutedText,
        indicatorColor: scheme.secondary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: border,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ========================================================
      // LIST TILES
      // ========================================================

      listTileTheme: ListTileThemeData(
        textColor: foreground,
        iconColor: scheme.primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
        ),
      ),

      // ========================================================
      // PAGE TRANSITIONS
      // ========================================================

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
