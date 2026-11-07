
/// Describes the trust level of a geographic fix used for prayer
/// calculations.
///
/// This assessment describes location quality only. It does not claim
/// that astronomical prayer calculations are accurate to the same number
/// of metres or seconds.
enum LocationAccuracyLevel {
  precise,
  good,
  approximate,
  unreliable,
}

/// Immutable assessment of a location fix.
///
/// The thresholds are intentionally conservative:
/// - up to 15 m: precise
/// - up to 50 m: good
/// - up to 150 m: approximate
/// - above 150 m: unreliable
///
/// Cached fixes have stricter age limits than live GPS fixes.
class LocationAccuracyAssessment {
  const LocationAccuracyAssessment({
    required this.level,
    required this.accuracyMeters,
    required this.age,
    required this.isCached,
  });

  final LocationAccuracyLevel level;
  final double accuracyMeters;
  final Duration age;
  final bool isCached;

  static const double preciseAccuracyMeters = 15;
  static const double goodAccuracyMeters = 50;
  static const double approximateAccuracyMeters = 150;

  static const Duration maximumLiveAge = Duration(minutes: 2);
  static const Duration maximumCachedPreciseAge =
      Duration(minutes: 5);
  static const Duration maximumCachedGoodAge =
      Duration(minutes: 30);
  static const Duration maximumCachedApproximateAge =
      Duration(hours: 6);

  bool get isReliable =>
      level != LocationAccuracyLevel.unreliable;

  bool get isPrecise =>
      level == LocationAccuracyLevel.precise;

  bool get canBeUsedForPrayerCalculation => isReliable;

  String get localizationKey {
    switch (level) {
      case LocationAccuracyLevel.precise:
        return 'location_accuracy_precise';
      case LocationAccuracyLevel.good:
        return 'location_accuracy_good';
      case LocationAccuracyLevel.approximate:
        return 'location_accuracy_approximate';
      case LocationAccuracyLevel.unreliable:
        return 'location_accuracy_unreliable';
    }
  }

  static LocationAccuracyAssessment evaluate({
    required double accuracyMeters,
    required DateTime timestamp,
    required DateTime now,
    required bool isCached,
  }) {
    final age = now.difference(timestamp);

    if (!accuracyMeters.isFinite ||
        accuracyMeters <= 0 ||
        age.isNegative ||
        accuracyMeters > approximateAccuracyMeters) {
      return LocationAccuracyAssessment(
        level: LocationAccuracyLevel.unreliable,
        accuracyMeters: accuracyMeters,
        age: age,
        isCached: isCached,
      );
    }

    if (!isCached && age > maximumLiveAge) {
      return LocationAccuracyAssessment(
        level: LocationAccuracyLevel.unreliable,
        accuracyMeters: accuracyMeters,
        age: age,
        isCached: false,
      );
    }

    if (isCached) {
      if (age > maximumCachedApproximateAge) {
        return LocationAccuracyAssessment(
          level: LocationAccuracyLevel.unreliable,
          accuracyMeters: accuracyMeters,
          age: age,
          isCached: true,
        );
      }

      if (accuracyMeters <= preciseAccuracyMeters &&
          age <= maximumCachedPreciseAge) {
        return LocationAccuracyAssessment(
          level: LocationAccuracyLevel.precise,
          accuracyMeters: accuracyMeters,
          age: age,
          isCached: true,
        );
      }

      if (accuracyMeters <= goodAccuracyMeters &&
          age <= maximumCachedGoodAge) {
        return LocationAccuracyAssessment(
          level: LocationAccuracyLevel.good,
          accuracyMeters: accuracyMeters,
          age: age,
          isCached: true,
        );
      }

      return LocationAccuracyAssessment(
        level: LocationAccuracyLevel.approximate,
        accuracyMeters: accuracyMeters,
        age: age,
        isCached: true,
      );
    }

    if (accuracyMeters <= preciseAccuracyMeters) {
      return LocationAccuracyAssessment(
        level: LocationAccuracyLevel.precise,
        accuracyMeters: accuracyMeters,
        age: age,
        isCached: false,
      );
    }

    if (accuracyMeters <= goodAccuracyMeters) {
      return LocationAccuracyAssessment(
        level: LocationAccuracyLevel.good,
        accuracyMeters: accuracyMeters,
        age: age,
        isCached: false,
      );
    }

    return LocationAccuracyAssessment(
      level: LocationAccuracyLevel.approximate,
      accuracyMeters: accuracyMeters,
      age: age,
      isCached: false,
    );
  }
}
