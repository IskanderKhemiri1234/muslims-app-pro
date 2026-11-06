
import 'package:flutter/material.dart';

/// Central visual tokens for the Mumin Pro design system.
///
/// Keep all shared visual values here so screens and components
/// remain consistent across the application.
abstract final class MuminColors {
  // Primary brand palette.
  static const Color midnightEmerald = Color(0xFF071C17);
  static const Color deepEmerald = Color(0xFF063E31);
  static const Color emerald = Color(0xFF075B46);
  static const Color emeraldLight = Color(0xFF147A60);

  // Signature gold palette.
  static const Color gold = Color(0xFFD8B66A);
  static const Color goldLight = Color(0xFFE8CE91);
  static const Color goldDark = Color(0xFFB18B42);

  // Neutral palette.
  static const Color ivory = Color(0xFFF4F0E6);
  static const Color warmWhite = Color(0xFFFFFCF5);
  static const Color mistEmerald = Color(0xFFA9C5B8);
  static const Color mutedText = Color(0xFF82978E);

  // Dark surfaces.
  static const Color darkBackground = Color(0xFF071C17);
  static const Color darkSurface = Color(0xFF0D2921);
  static const Color darkElevated = Color(0xFF12382D);
  static const Color darkBorder = Color(0xFF25473B);

  // Light surfaces.
  static const Color lightBackground = Color(0xFFF4F0E6);
  static const Color lightSurface = Color(0xFFFFFCF5);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE4DDCD);

  // Semantic colors.
  static const Color success = Color(0xFF55A982);
  static const Color warning = Color(0xFFE4B45D);
  static const Color error = Color(0xFFD96C68);
  static const Color info = Color(0xFF76AFC0);

  // Overlay colors.
  static const Color darkOverlay = Color(0x99071C17);
  static const Color goldOverlay = Color(0x26D8B66A);
  static const Color glassBorder = Color(0x40FFFFFF);
}

/// Central spacing scale.
///
/// One logical unit is expressed in Flutter logical pixels.
abstract final class MuminSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double section = 40;
  static const double screen = 48;
}

/// Shared corner-radius scale.
abstract final class MuminRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 30;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(
    Radius.circular(lg),
  );

  static const BorderRadius premiumCard = BorderRadius.all(
    Radius.circular(xl),
  );

  static const BorderRadius dialog = BorderRadius.all(
    Radius.circular(xxl),
  );

  static const BorderRadius pillShape = BorderRadius.all(
    Radius.circular(pill),
  );
}

/// Cinematic motion timing for the application.
abstract final class MuminMotion {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration smooth = Duration(milliseconds: 420);
  static const Duration cinematic = Duration(milliseconds: 650);
  static const Duration ambient = Duration(milliseconds: 1200);

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeInOutQuart;
  static const Curve gentle = Curves.easeInOut;
}

/// Shared elevation and shadow definitions.
abstract final class MuminElevation {
  static const double flat = 0;
  static const double subtle = 2;
  static const double card = 6;
  static const double floating = 12;
  static const double overlay = 20;

  static const List<BoxShadow> emeraldGlow = [
    BoxShadow(
      color: Color(0x26075B46),
      blurRadius: 24,
      spreadRadius: 1,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> goldGlow = [
    BoxShadow(
      color: Color(0x26D8B66A),
      blurRadius: 20,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> darkCard = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 18,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];
}

/// Brand gradients used by premium surfaces and hero sections.
abstract final class MuminGradients {
  static const LinearGradient emerald = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      MuminColors.emeraldLight,
      MuminColors.emerald,
      MuminColors.deepEmerald,
    ],
  );

  static const LinearGradient midnight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF12382D),
      MuminColors.midnightEmerald,
    ],
  );

  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      MuminColors.goldLight,
      MuminColors.gold,
      MuminColors.goldDark,
    ],
  );

  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x1FFFFFFF),
      Color(0x08FFFFFF),
    ],
  );

  static const LinearGradient spiritualGlow = RadialGradient(
    center: Alignment.topRight,
    radius: 1.2,
    colors: [
      Color(0x337A9D69),
      Color(0x00071C17),
    ],
  );
}

/// Standard typography dimensions.
///
/// Font families will be connected centrally after verifying
/// the Arabic, English, and French font assets in the repository.
abstract final class MuminTypography {
  static const String fontFamily = 'Roboto';

  static const double displayLarge = 36;
  static const double displayMedium = 30;
  static const double headlineLarge = 26;
  static const double headlineMedium = 22;
  static const double titleLarge = 20;
  static const double titleMedium = 16;
  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;
  static const double labelLarge = 14;
  static const double labelSmall = 11;

  static const double tightLineHeight = 1.2;
  static const double normalLineHeight = 1.5;
  static const double relaxedLineHeight = 1.75;
}
