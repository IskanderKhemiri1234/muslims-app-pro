
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A reusable, theme-aware glass surface.
///
/// Designed for bounded UI regions such as cards and panels.
/// Blur can be disabled independently for performance and accessibility.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.borderColor,
    this.color,
    this.blurSigma = 16,
    this.enableBlur = true,
    this.borderWidth = 1,
    this.clipBehavior = Clip.antiAlias,
  })  : assert(radius >= 0),
        assert(blurSigma >= 0),
        assert(borderWidth >= 0);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color? color;

  /// Blur intensity applied to content behind this surface.
  final double blurSigma;

  /// Whether backdrop blur is enabled.
  final bool enableBlur;

  /// Border thickness.
  final double borderWidth;

  /// Controls clipping around the rounded surface.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.maybeOf(context);

    final isDark = theme.brightness == Brightness.dark;

    // Reduced transparency and reduced motion are separate
    // accessibility preferences.
    final reduceTransparency =
        mediaQuery?.disableAnimations == true
            ? false
            : false;

    final effectiveColor = color ??
        (isDark
            ? Colors.white.withValues(alpha: 0.055)
            : Colors.white.withValues(alpha: 0.82));

    final effectiveBorderColor = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.10)
            : AppColors.emerald.withValues(alpha: 0.12));

    final effectiveRadius = BorderRadius.circular(radius);

    final decoration = BoxDecoration(
      color: effectiveColor,
      borderRadius: effectiveRadius,
      border: Border.all(
        color: effectiveBorderColor,
        width: borderWidth,
      ),
    );

    final surface = DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    // A solid surface is cheaper and more predictable than
    // BackdropFilter when blur is disabled.
    if (!enableBlur || blurSigma == 0 || reduceTransparency) {
      return ClipRRect(
        borderRadius: effectiveRadius,
        clipBehavior: clipBehavior,
        child: surface,
      );
    }

    return ClipRRect(
      borderRadius: effectiveRadius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: surface,
      ),
    );
  }
}
