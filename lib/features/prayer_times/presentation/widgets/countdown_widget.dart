
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/prayer_controller.dart';

class CountdownWidget extends StatelessWidget {
  const CountdownWidget({
    super.key,
    required this.controller,
  });

  final PrayerController controller;

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: controller.clock,
      builder: (context, now, child) {
        final target = controller.nextPrayerTime;

        final duration = target == null
            ? Duration.zero
            : target.difference(now).isNegative
                ? Duration.zero
                : target.difference(now);

        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);

        return Row(
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _TimeUnit(
              value: _twoDigits(hours),
              label: 'HRS',
            ),
            const _TimeSeparator(),
            _TimeUnit(
              value: _twoDigits(minutes),
              label: 'MIN',
            ),
            const _TimeSeparator(),
            _TimeUnit(
              value: _twoDigits(seconds),
              label: 'SEC',
              highlighted: true,
            ),
          ],
        );
      },
    );
  }
}

class _TimeUnit extends StatelessWidget {
  const _TimeUnit({
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  final String value;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            value,
            key: ValueKey(value),
            style: TextStyle(
              color: highlighted
                  ? AppColors.goldLight
                  : Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w800,
              fontFeatures: const [],
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
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  const _TimeSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 13,
      ),
      child: Text(
        ':',
        style: TextStyle(
          color: AppColors.gold.withValues(alpha: 0.8),
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
