
import 'dart:convert';

import 'package:adhan/adhan.dart';

/// A validated prayer calculation profile.
class PrayerCalculationProfile {
  const PrayerCalculationProfile({
    required this.id,
    required this.countryCode,
    required this.method,
    required this.madhab,
  });

  final String id;
  final String countryCode;
  final CalculationMethod method;
  final Madhab madhab;
}

/// Versioned and validated prayer rules engine.
///
/// Network access is deliberately kept outside this class.
/// A remote configuration must be fetched and authenticated
/// by another component before being passed to installConfiguration().
class PrayerRulesService {
  PrayerRulesService({
    required CalculationMethod fallbackMethod,
    Madhab fallbackMadhab = Madhab.shafi,
  })  : _fallbackMethod = fallbackMethod,
        _fallbackMadhab = fallbackMadhab;

  static const int supportedSchemaVersion = 1;
  static const int maximumConfigurationBytes = 65536;
  static const int maximumProfiles = 100;

  final CalculationMethod _fallbackMethod;
  final Madhab _fallbackMadhab;

  int _configurationVersion = 0;

  final Map<String, PrayerCalculationProfile> _profiles = {};

  int get configurationVersion => _configurationVersion;

  int get profileCount => _profiles.length;

  /// Indicates whether a configuration has been installed.
  ///
  /// This does not establish that the configuration is remote,
  /// authenticated, or trustworthy.
  bool get hasRemoteConfiguration => _profiles.isNotEmpty;

  /// Returns the built-in fallback profile.
  PrayerCalculationProfile get fallbackProfile {
    return PrayerCalculationProfile(
      id: 'built_in_default',
      countryCode: 'GLOBAL',
      method: _fallbackMethod,
      madhab: _fallbackMadhab,
    );
  }

  /// Selects the best available profile for a country.
  ///
  /// Priority:
  /// 1. Exact country match.
  /// 2. GLOBAL profile.
  /// 3. Built-in fallback.
  PrayerCalculationProfile resolve({
    required String countryCode,
  }) {
    final normalized = _normalizeCountryCode(countryCode);

    return _profiles[normalized] ??
        _profiles['GLOBAL'] ??
        fallbackProfile;
  }

  /// Installs a fully validated JSON configuration.
  ///
  /// The existing configuration remains unchanged if validation fails.
  /// Configuration versions must increase monotonically.
  void installConfiguration(String jsonSource) {
    if (jsonSource.isEmpty ||
        utf8.encode(jsonSource).length > maximumConfigurationBytes) {
      throw const FormatException(
        'Configuration size is invalid.',
      );
    }

    final decoded = jsonDecode(jsonSource);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Configuration root must be an object.',
      );
    }

    final schemaVersion = decoded['schemaVersion'];
    final version = decoded['version'];
    final profilesJson = decoded['profiles'];

    if (schemaVersion != supportedSchemaVersion) {
      throw const FormatException(
        'Unsupported configuration schema.',
      );
    }

    if (version is! int ||
        version <= _configurationVersion) {
      throw const FormatException(
        'Configuration version must be newer.',
      );
    }

    if (profilesJson is! List ||
        profilesJson.isEmpty ||
        profilesJson.length > maximumProfiles) {
      throw const FormatException(
        'Invalid profiles collection.',
      );
    }

    final parsedProfiles =
        <String, PrayerCalculationProfile>{};

    final profileIds = <String>{};

    for (final item in profilesJson) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Invalid profile entry.',
        );
      }

      final rawId = item['id'];
      final rawCountryCode = item['countryCode'];
      final methodName = item['method'];
      final madhabName = item['madhab'];

      if (rawId is! String ||
          rawId.trim().isEmpty ||
          rawId.trim().length > 64) {
        throw const FormatException(
          'Invalid profile ID.',
        );
      }

      if (rawCountryCode is! String) {
        throw const FormatException(
          'Invalid country code.',
        );
      }

      if (methodName is! String ||
          madhabName is! String) {
        throw const FormatException(
          'Invalid calculation settings.',
        );
      }

      final id = rawId.trim();
      final countryCode =
          _normalizeCountryCode(rawCountryCode);

      if (countryCode != 'GLOBAL' &&
          !RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
        throw const FormatException(
          'Country code must be ISO alpha-2 or GLOBAL.',
        );
      }

      if (!profileIds.add(id)) {
        throw const FormatException(
          'Duplicate profile ID.',
        );
      }

      if (parsedProfiles.containsKey(countryCode)) {
        throw const FormatException(
          'Duplicate country profile.',
        );
      }

      final method = _findMethod(methodName);
      final madhab = _findMadhab(madhabName);

      if (method == null || madhab == null) {
        throw const FormatException(
          'Unknown calculation method or madhab.',
        );
      }

      parsedProfiles[countryCode] =
          PrayerCalculationProfile(
        id: id,
        countryCode: countryCode,
        method: method,
        madhab: madhab,
      );
    }

    // Atomic in-memory replacement:
    // no mutation occurs before all entries are validated.
    _profiles
      ..clear()
      ..addAll(parsedProfiles);

    _configurationVersion = version;
  }

  /// Removes installed profiles and restores built-in fallback behavior.
  ///
  /// The last accepted version is intentionally preserved.
  /// This prevents older configurations from being reinstalled.
  void resetToDefaults() {
    _profiles.clear();
  }

  CalculationMethod? _findMethod(String name) {
    for (final method in CalculationMethod.values) {
      if (method.name == name) {
        return method;
      }
    }

    return null;
  }

  Madhab? _findMadhab(String name) {
    switch (name) {
      case 'hanafi':
        return Madhab.hanafi;

      case 'shafi':
        return Madhab.shafi;

      default:
        return null;
    }
  }

  String _normalizeCountryCode(String value) {
    return value.trim().toUpperCase();
  }
}
