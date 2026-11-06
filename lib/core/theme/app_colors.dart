
import 'package:flutter/material.dart';

import '../design_system/mumin_design_tokens.dart';

/// Backward-compatible color facade for features not yet migrated.
///
/// MuminColors is the single source of truth for the brand palette.
/// Keep feature-specific Quran colors here until their screens are migrated.
abstract final class AppColors {
  // Brand palette.
  static const Color emerald = MuminColors.emerald;
  static const Color emeraldLight = MuminColors.emeraldLight;
  static const Color emeraldDark = MuminColors.deepEmerald;
  static const Color deepGreen = MuminColors.midnightEmerald;

  // Gold palette.
  static const Color gold = MuminColors.gold;
  static const Color goldLight = MuminColors.goldLight;
  static const Color goldDark = MuminColors.goldDark;

  // Dark surfaces.
  static const Color darkBackground = MuminColors.darkBackground;
  static const Color darkSurface = MuminColors.darkSurface;
  static const Color darkSurfaceLight = MuminColors.darkElevated;
  static const Color darkSurfaceElevated = MuminColors.darkElevated;

  // Light surfaces.
  static const Color lightBackground = MuminColors.lightBackground;
  static const Color lightSurface = MuminColors.lightSurface;
  static const Color lightSurfaceSoft = Color(0xFFECE7DA);
  static const Color lightSurfaceElevated = MuminColors.lightElevated;

  // Text.
  static const Color textDark = MuminColors.midnightEmerald;
  static const Color textLight = MuminColors.ivory;
  static const Color muted = MuminColors.mistEmerald;
  static const Color mutedDark = MuminColors.mutedText;
  static const Color mutedLight = MuminColors.mistEmerald;

  // Borders.
  static const Color border = Color(0x337DAE98);
  static const Color borderLight = MuminColors.lightBorder;
  static const Color borderDark = MuminColors.darkBorder;

  // Semantic states.
  static const Color success = MuminColors.success;
  static const Color successLight = Color(0xFFBCE8D2);
  static const Color warning = MuminColors.warning;
  static const Color warningLight = Color(0xFFFFE8B8);
  static const Color error = MuminColors.error;
  static const Color errorLight = Color(0xFFFFDADA);
  static const Color info = MuminColors.info;
  static const Color infoLight = Color(0xFFD9ECFA);

  // Quran reading surfaces intentionally remain specialized.
  static const Color quranPaper = Color(0xFFFFFCF3);
  static const Color quranInk = Color(0xFF26382C);
  static const Color quranGold = Color(0xFFB99A58);
  static const Color quranPaperDark = Color(0xFF202A23);
  static const Color quranInkDark = Color(0xFFE8DFC9);

  // Overlays and interaction states.
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x14000000);
  static const Color focus = MuminColors.emeraldLight;
  static const Color selection = Color(0x332AA77A);
  static const Color disabled = Color(0xFF82938A);
  static const Color pressedOverlay = Color(0x1F075B46);

  // Feature surfaces and dividers.
  static const Color darkCard = Color(0xFF12382D);
  static const Color lightCard = MuminColors.lightElevated;
  static const Color darkDivider = MuminColors.darkBorder;
  static const Color lightDivider = MuminColors.lightBorder;

  // Prayer experience.
  static const Color prayerActive = MuminColors.gold;
  static const Color prayerUpcoming = MuminColors.emeraldLight;
  static const Color prayerCompleted = MuminColors.mutedText;

  // Qibla experience.
  static const Color qiblaNorth = MuminColors.emerald;
  static const Color qiblaDirection = MuminColors.gold;

  // Legacy gradient lists retained for existing widget APIs.
  static const List<Color> emeraldGradient = [
    MuminColors.emeraldLight,
    MuminColors.emerald,
    MuminColors.deepEmerald,
  ];

  static const List<Color> darkGradient = [
    MuminColors.darkElevated,
    MuminColors.darkBackground,
  ];

  static const List<Color> goldGradient = [
    MuminColors.goldLight,
    MuminColors.gold,
    MuminColors.goldDark,
  ];
}
