
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A reusable glass-morphism surface.
///
/// Features:
/// - Bounded backdrop blur.
/// - Theme-aware surface and border colors.
/// - Optional custom surface and border colors.
/// - Reduced-transparency support.
/// - Backwards-compatible constructor.
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
  }) : assert(radius >= 0),
       assert(blurSigma >= 0);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color? color;

  /// Blur intensity applied behind the surface.
  final double blurSigma;

  /// Allows disabling blur for performance or accessibility.
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final reduceTransparency =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final effectiveColor = color ??
        (isDark
            ? Colors.white.withValues(alpha: 0.055)
            : Colors.white.withValues(alpha: 0.72));

    final effectiveBorderColor = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.10)
            : AppColors.emerald.withValues(alpha: 0.10));

    final shouldBlur = enableBlur &&
        !reduceTransparency &&
        blurSigma > 0;

    final decoration = BoxDecoration(
      color: effectiveColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: effectiveBorderColor,
        width: 1,
      ),
    );

    final surface = DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (!shouldBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: surface,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
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
