
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/prayer_controller.dart';

class CountdownWidget extends StatelessWidget {
  const CountdownWidget({
    super.key,
    required this.controller,
  });

  final PrayerController controller;

  static const Duration _animationDuration =
      Duration(milliseconds: 220);

  String _twoDigits(int value) =>
      value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<DateTime>(
        valueListenable: controller.clockListenable,
        builder: (context, now, child) {
          final target = controller.nextPrayerTime;
          final difference = target?.difference(now);

          final duration =
              difference == null || difference.isNegative
                  ? Duration.zero
                  : difference;

          final hours = duration.inHours;
          final minutes =
              duration.inMinutes.remainder(60);
          final seconds =
              duration.inSeconds.remainder(60);

          return Semantics(
            label: 'Time remaining: '
                '$hours hours, $minutes minutes, '
                '$seconds seconds',
            child: ExcludeSemantics(
              child: Row(
                textDirection: TextDirection.ltr,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TimeUnit(
                    value: _twoDigits(hours),
                    label: 'HRS',
                    duration: _animationDuration,
                  ),
                  const _TimeSeparator(),
                  _TimeUnit(
                    value: _twoDigits(minutes),
                    label: 'MIN',
                    duration: _animationDuration,
                  ),
                  const _TimeSeparator(),
                  _TimeUnit(
                    value: _twoDigits(seconds),
                    label: 'SEC',
                    highlighted: true,
                    duration: _animationDuration,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  const _TimeUnit({
    required this.value,
    required this.label,
    required this.duration,
    this.highlighted = false,
  });

  final String value;
  final String label;
  final Duration duration;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: duration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              value,
              key: ValueKey<String>(value),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: highlighted
                    ? AppColors.goldLight
                    : Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w800,
                fontFeatures: const [
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  const _TimeSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: 13,
      ),
      child: Text(
        ':',
        style: TextStyle(
          color: AppColors.gold,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
