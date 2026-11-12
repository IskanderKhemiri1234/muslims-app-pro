/// Defines the short automatic opening segment of the Adhan experience.
class MuminAdhanIntroPolicy {
  const MuminAdhanIntroPolicy._();

  /// The opening takbeers play automatically for exactly ten seconds.
  static const Duration automaticOpeningDuration = Duration(seconds: 10);

  /// Returns true once the automatic opening segment has elapsed.
  ///
  /// After the user explicitly continues the recording, the automatic pause
  /// must never interrupt playback again.
  static bool shouldPauseAt(
    Duration position, {
    required bool continuationStarted,
  }) {
    return !continuationStarted &&
        position >= automaticOpeningDuration;
  }
}
