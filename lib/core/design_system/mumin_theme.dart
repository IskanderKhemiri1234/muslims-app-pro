import 'package:flutter/material.dart';

import 'mumin_design_tokens.dart';

/// Central Material 3 theme configuration for Mumin Pro.
///
/// This class consumes the shared design tokens and exposes matching
/// light and dark themes. Keep screen-specific styling out of this file.
abstract final class MuminTheme {
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = isDark
        ? MuminColors.darkBackground
        : MuminColors.lightBackground;

    final surface = isDark
        ? MuminColors.darkSurface
        : MuminColors.lightSurface;

    final elevatedSurface = isDark
        ? MuminColors.darkElevated
        : MuminColors.lightElevated;

    final border = isDark
        ? MuminColors.darkBorder
        : MuminColors.lightBorder;

    final foreground = isDark
        ? MuminColors.ivory
        : MuminColors.midnightEmerald;

    final mutedForeground = isDark
        ? MuminColors.mistEmerald
        : MuminColors.mutedText;

    final primary = isDark
        ? MuminColors.emeraldLight
        : MuminColors.emerald;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: MuminColors.gold,
      onSecondary: MuminColors.midnightEmerald,
      error: MuminColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: foreground,
      surfaceContainerHighest: elevatedSurface,
      onSurfaceVariant: mutedForeground,
      outline: border,
      outlineVariant: border.withValues(alpha: 0.65),
      shadow: Colors.black,
      scrim: MuminColors.darkOverlay,
      inverseSurface: isDark
          ? MuminColors.ivory
          : MuminColors.midnightEmerald,
      onInverseSurface: isDark
          ? MuminColors.midnightEmerald
          : MuminColors.ivory,
      inversePrimary: isDark
          ? MuminColors.emerald
          : MuminColors.emeraldLight,
      tertiary: MuminColors.goldLight,
      onTertiary: MuminColors.midnightEmerald,
      surfaceTint: primary,
    );

    final textTheme = _buildTextTheme(
      brightness: brightness,
      foreground: foreground,
      mutedForeground: mutedForeground,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(MuminRadius.lg),
      borderSide: BorderSide(color: border),
    );

    final focusedInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(MuminRadius.lg),
      borderSide: BorderSide(
        color: primary,
        width: 1.6,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: border,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      applyElevationOverlayColor: isDark,
      fontFamily: MuminTypography.fontFamily,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(
          color: foreground,
          size: 23,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : MuminElevation.subtle,
        shadowColor: Colors.black.withValues(
          alpha: isDark ? 0.18 : 0.06,
        ),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: MuminRadius.card,
          side: BorderSide(
            color: border.withValues(alpha: 0.85),
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          elevation: 0,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: MuminSpacing.xxl,
            vertical: MuminSpacing.lg,
          ),
          textStyle: const TextStyle(
            fontSize: MuminTypography.labelLarge,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: MuminRadius.card,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: MuminSpacing.xxl,
            vertical: MuminSpacing.lg,
          ),
          textStyle: const TextStyle(
            fontSize: MuminTypography.labelLarge,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: MuminRadius.card,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: MuminSpacing.xl,
            vertical: MuminSpacing.md,
          ),
          side: BorderSide(
            color: primary.withValues(alpha: 0.65),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: MuminRadius.card,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MuminRadius.sm),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevatedSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MuminSpacing.lg,
          vertical: MuminSpacing.lg,
        ),
        hintStyle: TextStyle(
          color: mutedForeground,
          fontSize: MuminTypography.bodyMedium,
        ),
        labelStyle: TextStyle(
          color: mutedForeground,
          fontSize: MuminTypography.bodyMedium,
        ),
        prefixIconColor: mutedForeground,
        suffixIconColor: mutedForeground,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: focusedInputBorder,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MuminRadius.lg),
          borderSide: const BorderSide(
            color: MuminColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MuminRadius.lg),
          borderSide: const BorderSide(
            color: MuminColors.error,
            width: 1.6,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: foreground,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MuminRadius.md),
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
  backgroundColor: MuminColors.gold,
  foregroundColor: MuminColors.midnightEmerald,
  elevation: MuminElevation.card,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(MuminRadius.lg),
  ),
),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: primary.withValues(
          alpha: isDark ? 0.24 : 0.12,
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 23,
              color: selected ? primary : mutedForeground,
            );
          },
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: MuminTypography.labelSmall,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? primary : mutedForeground,
            );
          },
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: mutedForeground,
        selectedLabelStyle: const TextStyle(
          fontSize: MuminTypography.labelSmall,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: MuminTypography.labelSmall,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: MuminElevation.floating,
        shape: RoundedRectangleBorder(
          borderRadius: MuminRadius.dialog,
          side: BorderSide(color: border),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: mutedForeground,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: MuminElevation.floating,
        modalElevation: MuminElevation.overlay,
        showDragHandle: true,
        dragHandleColor: mutedForeground.withValues(alpha: 0.45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(MuminRadius.xxl),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? MuminColors.darkElevated
            : MuminColors.midnightEmerald,
        contentTextStyle: const TextStyle(
          color: MuminColors.ivory,
          fontSize: MuminTypography.bodyMedium,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: MuminElevation.card,
        shape: RoundedRectangleBorder(
          borderRadius: MuminRadius.card,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
        circularTrackColor: border,
        linearMinHeight: 5,
        refreshBackgroundColor: surface,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return primary;
            }
            return null;
          },
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MuminRadius.xs),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return null;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return primary;
            }
            return elevatedSurface;
          },
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: border,
        thumbColor: MuminColors.gold,
        overlayColor: primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: mutedForeground,
        indicatorColor: MuminColors.gold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: border,
        labelStyle: const TextStyle(
          fontSize: MuminTypography.labelLarge,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: MuminTypography.labelLarge,
          fontWeight: FontWeight.w500,
        ),
      ),

      listTileTheme: ListTileThemeData(
        textColor: foreground,
        iconColor: primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MuminSpacing.lg,
          vertical: MuminSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: MuminRadius.card,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme({
    required Brightness brightness,
    required Color foreground,
    required Color mutedForeground,
  }) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return base.apply(
      fontFamily: MuminTypography.fontFamily,
      bodyColor: foreground,
      displayColor: foreground,
    ).copyWith(
      displayLarge: TextStyle(
        color: foreground,
        fontSize: MuminTypography.displayLarge,
        fontWeight: FontWeight.w800,
        height: MuminTypography.tightLineHeight,
      ),
      displayMedium: TextStyle(
        color: foreground,
        fontSize: MuminTypography.displayMedium,
        fontWeight: FontWeight.w800,
        height: MuminTypography.tightLineHeight,
      ),
      headlineLarge: TextStyle(
        color: foreground,
        fontSize: MuminTypography.headlineLarge,
        fontWeight: FontWeight.w800,
        height: MuminTypography.normalLineHeight,
      ),
      headlineMedium: TextStyle(
        color: foreground,
        fontSize: MuminTypography.headlineMedium,
        fontWeight: FontWeight.w700,
        height: MuminTypography.normalLineHeight,
      ),
      titleLarge: TextStyle(
        color: foreground,
        fontSize: MuminTypography.titleLarge,
        fontWeight: FontWeight.w800,
        height: MuminTypography.normalLineHeight,
      ),
      titleMedium: TextStyle(
        color: foreground,
        fontSize: MuminTypography.titleMedium,
        fontWeight: FontWeight.w700,
        height: MuminTypography.normalLineHeight,
      ),
      bodyLarge: TextStyle(
        color: foreground,
        fontSize: MuminTypography.bodyLarge,
        height: MuminTypography.relaxedLineHeight,
      ),
      bodyMedium: TextStyle(
        color: foreground,
        fontSize: MuminTypography.bodyMedium,
        height: MuminTypography.normalLineHeight,
      ),
      bodySmall: TextStyle(
        color: mutedForeground,
        fontSize: MuminTypography.bodySmall,
        height: MuminTypography.normalLineHeight,
      ),
      labelLarge: TextStyle(
        color: foreground,
        fontSize: MuminTypography.labelLarge,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: TextStyle(
        color: mutedForeground,
        fontSize: MuminTypography.labelSmall,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
