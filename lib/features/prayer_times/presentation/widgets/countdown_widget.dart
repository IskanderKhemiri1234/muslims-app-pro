import 'package:flutter/material.dart';

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
        final duration = controller.remaining;

        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);

        return Text(
          '${_twoDigits(hours)}:'
          '${_twoDigits(minutes)}:'
          '${_twoDigits(seconds)}',
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
