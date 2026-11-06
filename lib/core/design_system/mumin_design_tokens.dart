
import 'package:flutter/material.dart';

/// Mumin Pro — Central Design Token System.
///
/// This file is the single source of truth for shared visual values.
/// Keep feature-specific styling out of this layer.
///
/// Compatibility:
/// Existing public token names are intentionally preserved so that
/// current widgets and themes can continue using this file.
abstract final class MuminColors {
  // ---------------------------------------------------------------------------
  // Brand identity
  // ---------------------------------------------------------------------------

  static const Color midnightEmerald = Color(0xFF071C17);
  static const Color deepEmerald = Color(0xFF063E31);
  static const Color emerald = Color(0xFF075B46);
  static const Color emeraldLight = Color(0xFF147A60);
  static const Color emeraldBright = Color(0xFF21866A);

  // ---------------------------------------------------------------------------
  // Signature gold
  // ---------------------------------------------------------------------------

  static const Color gold = Color(0xFFD8B66A);
  static const Color goldLight = Color(0xFFE8CE91);
  static const Color goldDark = Color(0xFFB18B42);
  static const Color goldMuted = Color(0xFF9C8048);

  // ---------------------------------------------------------------------------
  // Neutral palette
  // ---------------------------------------------------------------------------

  static const Color ivory = Color(0xFFF4F0E6);
  static const Color warmWhite = Color(0xFFFFFCF5);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color mistEmerald = Color(0xFFA9C5B8);
  static const Color mutedText = Color(0xFF82978E);
  static const Color neutralDark = Color(0xFF26352F);
  static const Color neutralLight = Color(0xFFECE9E0);

  // ---------------------------------------------------------------------------
  // Dark surfaces
  // ---------------------------------------------------------------------------

  static const Color darkBackground = Color(0xFF071C17);
  static const Color darkSurface = Color(0xFF0D2921);
  static const Color darkElevated = Color(0xFF12382D);
  static const Color darkBorder = Color(0xFF25473B);
  static const Color darkSurfaceVariant = Color(0xFF18372D);

  // ---------------------------------------------------------------------------
  // Light surfaces
  // ---------------------------------------------------------------------------

  static const Color lightBackground = Color(0xFFF4F0E6);
  static const Color lightSurface = Color(0xFFFFFCF5);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE4DDCD);
  static const Color lightSurfaceVariant = Color(0xFFECE7DA);

  // ---------------------------------------------------------------------------
  // Semantic colors
  // ---------------------------------------------------------------------------

  static const Color success = Color(0xFF55A982);
  static const Color successLight = Color(0xFFBCE8D2);

  static const Color warning = Color(0xFFE4B45D);
  static const Color warningLight = Color(0xFFFFE8B8);

  static const Color error = Color(0xFFD96C68);
  static const Color errorLight = Color(0xFFFFDADA);

  static const Color info = Color(0xFF76AFC0);
  static const Color infoLight = Color(0xFFD9ECFA);

  // ---------------------------------------------------------------------------
  // Text roles
  // ---------------------------------------------------------------------------

  static const Color textPrimaryDark = Color(0xFFF4F0E6);
  static const Color textSecondaryDark = Color(0xFFA9C5B8);
  static const Color textPrimaryLight = Color(0xFF071C17);
  static const Color textSecondaryLight = Color(0xFF65796F);

  static const Color textOnEmerald = Color(0xFFFFFFFF);
  static const Color textOnGold = Color(0xFF071C17);

  // ---------------------------------------------------------------------------
  // Interaction states
  // ---------------------------------------------------------------------------

  static const Color focus = Color(0xFF21866A);
  static const Color selection = Color(0x332AA77A);
  static const Color disabled = Color(0xFF82938A);
  static const Color pressed = Color(0x1F075B46);
  static const Color hover = Color(0x14075B46);

  // ---------------------------------------------------------------------------
  // Overlay and glass
  // ---------------------------------------------------------------------------

  static const Color darkOverlay = Color(0x99071C17);
  static const Color lightOverlay = Color(0x66000000);

  static const Color goldOverlay = Color(0x26D8B66A);
  static const Color emeraldOverlay = Color(0x26075B46);

  static const Color glassBorder = Color(0x40FFFFFF);
  static const Color glassHighlight = Color(0x1FFFFFFF);
  static const Color glassShadow = Color(0x26000000);

  // ---------------------------------------------------------------------------
  // Theme-aware semantic accessors
  // ---------------------------------------------------------------------------

  static Color background(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color surface(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  static Color elevatedSurface(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkElevated
        : lightElevated;
  }

  static Color border(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkBorder
        : lightBorder;
  }

  static Color primaryText(Brightness brightness) {
    return brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimaryLight;
  }

  static Color secondaryText(Brightness brightness) {
    return brightness == Brightness.dark
        ? textSecondaryDark
        : textSecondaryLight;
  }
}

/// ---------------------------------------------------------------------------
/// Spacing system
/// ---------------------------------------------------------------------------
///
/// All values are Flutter logical pixels.
/// Use these values instead of arbitrary spacing throughout the application.
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

  // Common layout values.
  static const double pageHorizontal = 20;
  static const double pageVertical = 24;
  static const double cardPadding = 16;
  static const double cardGap = 12;
  static const double sectionGap = 28;
  static const double compactGap = 6;
}

/// ---------------------------------------------------------------------------
/// Layout constraints
/// ---------------------------------------------------------------------------
///
/// Shared responsive layout values.
/// These are width thresholds, not device-model assumptions.
abstract final class MuminLayout {
  static const double compactWidth = 360;
  static const double mediumWidth = 600;
  static const double expandedWidth = 840;
  static const double largeWidth = 1200;

  static const double contentMaxWidth = 720;
  static const double wideContentMaxWidth = 1080;

  static const double minimumTouchTarget = 48;
  static const double minimumIconTouchTarget = 44;
}

/// ---------------------------------------------------------------------------
/// Corner radius system
/// ---------------------------------------------------------------------------

abstract final class MuminRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 30;
  static const double pill = 999;

  static const BorderRadius smallCard = BorderRadius.all(
    Radius.circular(sm),
  );

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

  static const BorderRadius bottomSheet = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );
}

/// ---------------------------------------------------------------------------
/// Motion system
/// ---------------------------------------------------------------------------
///
/// Keep motion purposeful and avoid unnecessary continuous animation.
/// Components should respect MediaQuery.disableAnimations.
abstract final class MuminMotion {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration smooth = Duration(milliseconds: 420);
  static const Duration cinematic = Duration(milliseconds: 650);
  static const Duration ambient = Duration(milliseconds: 1200);

  static const Duration reduced = Duration.zero;

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeInOutQuart;
  static const Curve gentle = Curves.easeInOut;
  static const Curve linear = Curves.linear;
}

/// ---------------------------------------------------------------------------
/// Elevation and shadows
/// ---------------------------------------------------------------------------

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

  static const List<BoxShadow> lightCard = [
    BoxShadow(
      color: Color(0x0D071C17),
      blurRadius: 14,
      spreadRadius: 0,
      offset: Offset(0, 5),
    ),
  ];

  static const List<BoxShadow> floatingSurface = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 10),
    ),
  ];
}

/// ---------------------------------------------------------------------------
/// Brand gradients
/// ---------------------------------------------------------------------------

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

  static const RadialGradient spiritualGlow = RadialGradient(
    center: Alignment.topRight,
    radius: 1.2,
    colors: [
      Color(0x337A9D69),
      Color(0x00071C17),
    ],
  );

  static const LinearGradient darkSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      MuminColors.darkElevated,
      MuminColors.darkBackground,
    ],
  );

  static const LinearGradient lightSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      MuminColors.lightElevated,
      MuminColors.lightBackground,
    ],
  );
}

/// ---------------------------------------------------------------------------
/// Typography system
/// ---------------------------------------------------------------------------
///
/// Roboto remains the safe fallback until the repository's Arabic and
/// Latin font assets and their pubspec declarations have been verified.
///
/// Do not reference unverified font-family names in application themes.
abstract final class MuminTypography {
  static const String fontFamily = 'Roboto';

  // Display.
  static const double displayLarge = 36;
  static const double displayMedium = 30;
  static const double displaySmall = 28;

  // Headlines.
  static const double headlineLarge = 26;
  static const double headlineMedium = 22;
  static const double headlineSmall = 20;

  // Titles.
  static const double titleLarge = 20;
  static const double titleMedium = 16;
  static const double titleSmall = 14;

  // Body.
  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;

  // Labels.
  static const double labelLarge = 14;
  static const double labelMedium = 12;
  static const double labelSmall = 11;

  // Line heights.
  static const double tightLineHeight = 1.2;
  static const double normalLineHeight = 1.5;
  static const double relaxedLineHeight = 1.75;

  // Letter spacing.
  static const double tightLetterSpacing = -0.4;
  static const double normalLetterSpacing = 0;
  static const double labelLetterSpacing = 0.2;

  // Reusable text styles.
  static const TextStyle displayLargeStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: displayLarge,
    fontWeight: FontWeight.w800,
    height: tightLineHeight,
    letterSpacing: tightLetterSpacing,
  );

  static const TextStyle displayMediumStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: displayMedium,
    fontWeight: FontWeight.w800,
    height: tightLineHeight,
  );

  static const TextStyle headlineLargeStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: headlineLarge,
    fontWeight: FontWeight.w800,
    height: normalLineHeight,
  );

  static const TextStyle headlineMediumStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: headlineMedium,
    fontWeight: FontWeight.w700,
    height: normalLineHeight,
  );

  static const TextStyle titleLargeStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: titleLarge,
    fontWeight: FontWeight.w800,
    height: normalLineHeight,
  );

  static const TextStyle titleMediumStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: titleMedium,
    fontWeight: FontWeight.w700,
    height: normalLineHeight,
  );

  static const TextStyle bodyLargeStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: bodyLarge,
    height: relaxedLineHeight,
  );

  static const TextStyle bodyMediumStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: bodyMedium,
    height: normalLineHeight,
  );

  static const TextStyle bodySmallStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: bodySmall,
    height: normalLineHeight,
  );

  static const TextStyle labelLargeStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: labelLarge,
    fontWeight: FontWeight.w700,
    letterSpacing: labelLetterSpacing,
  );

  static const TextStyle labelSmallStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: labelSmall,
    fontWeight: FontWeight.w600,
    letterSpacing: labelLetterSpacing,
  );
}
