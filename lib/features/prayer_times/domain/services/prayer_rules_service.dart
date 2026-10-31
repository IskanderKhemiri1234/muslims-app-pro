
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
/// A remote configuration must be fetched by another component
/// and passed to installConfiguration().
class PrayerRulesService {
  PrayerRulesService({
    required CalculationMethod fallbackMethod,
    Madhab fallbackMadhab = Madhab.shafi,
  })  : _fallbackMethod = fallbackMethod,
        _fallbackMadhab = fallbackMadhab;

  static const int supportedSchemaVersion = 1;
  static const int maximumConfigurationLength = 65536;

  final CalculationMethod _fallbackMethod;
  final Madhab _fallbackMadhab;

  int _configurationVersion = 0;

  final Map<String, PrayerCalculationProfile> _profiles = {};

  int get configurationVersion => _configurationVersion;

  int get profileCount => _profiles.length;

  bool get hasRemoteConfiguration => _profiles.isNotEmpty;

  /// Return a safe default profile.
  PrayerCalculationProfile get fallbackProfile {
    return PrayerCalculationProfile(
      id: 'built_in_default',
      countryCode: 'GLOBAL',
      method: _fallbackMethod,
      madhab: _fallbackMadhab,
    );
  }

  /// Select the best available profile for a country.
  ///
  /// If no matching country profile exists, use GLOBAL.
  /// If neither exists, use the built-in default.
  PrayerCalculationProfile resolve({
    required String countryCode,
  }) {
    final normalized = _normalizeCountryCode(countryCode);

    return _profiles[normalized] ??
        _profiles['GLOBAL'] ??
        fallbackProfile;
  }

  /// Install a validated JSON configuration.
  ///
  /// The current configuration remains unchanged if validation
  /// fails. Older versions are rejected.
  void installConfiguration(String jsonSource) {
    if (jsonSource.isEmpty ||
        jsonSource.length > maximumConfigurationLength) {
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

    if (version is! int || version <= _configurationVersion) {
      throw const FormatException(
        'Configuration version must be newer.',
      );
    }

    if (profilesJson is! List ||
        profilesJson.isEmpty ||
        profilesJson.length > 100) {
      throw const FormatException(
        'Invalid profiles collection.',
      );
    }

    final parsedProfiles =
        <String, PrayerCalculationProfile>{};

    for (final item in profilesJson) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Invalid profile entry.',
        );
      }

      final id = item['id'];
      final countryCode = item['countryCode'];
      final methodName = item['method'];
      final madhabName = item['madhab'];

      if (id is! String ||
          id.trim().isEmpty ||
          id.length > 64) {
        throw const FormatException(
          'Invalid profile ID.',
        );
      }

      if (countryCode is! String) {
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

      final normalizedCountry =
          _normalizeCountryCode(countryCode);

      if (normalizedCountry != 'GLOBAL' &&
          !RegExp(r'^[A-Z]{2}$').hasMatch(normalizedCountry)) {
        throw const FormatException(
          'Country code must be ISO alpha-2 or GLOBAL.',
        );
      }

      if (parsedProfiles.containsKey(normalizedCountry)) {
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

      parsedProfiles[normalizedCountry] =
          PrayerCalculationProfile(
        id: id.trim(),
        countryCode: normalizedCountry,
        method: method,
        madhab: madhab,
      );
    }

    // Commit only after every profile has passed validation.
    _profiles
      ..clear()
      ..addAll(parsedProfiles);

    _configurationVersion = version;
  }

  /// Remove remote profiles and return to built-in defaults.
  void resetToDefaults() {
    _profiles.clear();
    _configurationVersion = 0;
  }

  CalculationMethod? _findMethod(String name) {
    for (final value in CalculationMethod.values) {
      if (value.name == name) {
        return value;
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
