import 'package:flutter/material.dart';

import '../design_system/mumin_theme.dart';

/// Backward-compatible facade for legacy screens.
///
/// MuminTheme is the single source of truth for application-wide styling.
/// Keep this facade until all legacy imports have been migrated.
abstract final class AppTheme {
  static ThemeData get light => MuminTheme.light;

  static ThemeData get dark => MuminTheme.dark;
}
