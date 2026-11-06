
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/design_system/mumin_design_tokens.dart';

/// Reusable premium glass surface for Mumin Pro.
///
/// Features:
/// - Automatically adapts to light and dark themes.
/// - Uses the central Mumin design palette.
/// - Supports optional backdrop blur.
/// - Provides a predictable solid fallback for low-performance devices.
/// - Preserves the existing public constructor API.
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
  final double blurSigma;
  final bool enableBlur;
  final double borderWidth;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final effectiveColor = color ??
        (isDark
            ? colorScheme.surface.withValues(alpha: 0.76)
            : colorScheme.surface.withValues(alpha: 0.88));

    final effectiveBorderColor = borderColor ??
        (isDark
            ? MuminColors.glassBorder.withValues(alpha: 0.72)
            : MuminColors.emerald.withValues(alpha: 0.14));

    final effectiveRadius = BorderRadius.circular(radius);

    final decoration = BoxDecoration(
      color: effectiveColor,
      borderRadius: effectiveRadius,
      border: borderWidth == 0
          ? null
          : Border.all(
              color: effectiveBorderColor,
              width: borderWidth,
            ),
      boxShadow: isDark
          ? const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ]
          : const [
              BoxShadow(
                color: Color(0x10071C17),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
    );

    final surface = DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    final shouldBlur = enableBlur && blurSigma > 0;

    if (!shouldBlur) {
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
