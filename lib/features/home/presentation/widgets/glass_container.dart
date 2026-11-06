
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/design_system/mumin_design_tokens.dart';

/// Shared glass surface used throughout Mumin Pro.
///
/// Performance principles:
/// - Translucent surfaces are used by default without backdrop filtering.
/// - Backdrop blur remains opt-in for components that genuinely need it.
/// - A single rounded clipping boundary is used for the surface.
/// - Colors and borders adapt automatically to the active theme.
/// - The original public constructor remains backward compatible.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.borderColor,
    this.color,
    this.blurSigma = 12,
    this.enableBlur = false,
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
            ? colorScheme.surface.withValues(alpha: 0.82)
            : colorScheme.surface.withValues(alpha: 0.92));

    final effectiveBorderColor = borderColor ??
        (isDark
            ? MuminColors.glassBorder.withValues(alpha: 0.72)
            : MuminColors.emerald.withValues(alpha: 0.14));

    final borderRadius = BorderRadius.circular(radius);

    final decoration = BoxDecoration(
      color: effectiveColor,
      borderRadius: borderRadius,
      border: borderWidth > 0
          ? Border.all(
              color: effectiveBorderColor,
              width: borderWidth,
            )
          : null,
      boxShadow: isDark
          ? const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ]
          : const [
              BoxShadow(
                color: Color(0x0D071C17),
                blurRadius: 12,
                offset: Offset(0, 4),
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

    final shouldApplyBlur = enableBlur && blurSigma > 0;

    final Widget content;

    if (shouldApplyBlur) {
      content = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: surface,
      );
    } else {
      content = surface;
    }

    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      child: content,
    );
  }
}
