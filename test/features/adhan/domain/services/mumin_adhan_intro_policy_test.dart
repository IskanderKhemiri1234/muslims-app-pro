import 'package:flutter_test/flutter_test.dart';
import 'package:muslims_app/features/adhan/domain/services/mumin_adhan_intro_policy.dart';

void main() {
  group('MuminAdhanIntroPolicy', () {
    test('does not pause before the ten-second opening has elapsed', () {
      expect(
        MuminAdhanIntroPolicy.shouldPauseAt(
          const Duration(milliseconds: 9999),
          continuationStarted: false,
        ),
        isFalse,
      );
    });

    test('pauses at exactly ten seconds', () {
      expect(
        MuminAdhanIntroPolicy.shouldPauseAt(
          MuminAdhanIntroPolicy.automaticOpeningDuration,
          continuationStarted: false,
        ),
        isTrue,
      );
    });

    test('never applies the opening pause after the user continues', () {
      expect(
        MuminAdhanIntroPolicy.shouldPauseAt(
          const Duration(seconds: 45),
          continuationStarted: true,
        ),
        isFalse,
      );
    });
  });
}
