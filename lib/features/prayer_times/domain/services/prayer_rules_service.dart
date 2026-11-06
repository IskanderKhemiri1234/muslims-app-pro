
import 'dart:convert';

import 'package:adhan/adhan.dart';

/// Stable error codes for prayer-rules failures.
///
/// Presentation layers can translate [localizationKey] into Arabic,
/// English or French without making the domain layer depend on Flutter.
enum PrayerRulesErrorCode {
  invalidConfigurationSize,
  invalidJson,
  invalidConfigurationRoot,
  unsupportedSchemaVersion,
  invalidConfigurationVersion,
  invalidProfilesCollection,
  invalidProfileEntry,
  invalidProfileId,
  invalidCountryCode,
  invalidCalculationSettings,
  duplicateProfileId,
  duplicateCountryProfile,
  unknownCalculationMethod,
  unknownMadhab,
}

extension PrayerRulesErrorLocalization on PrayerRulesErrorCode {
  String get localizationKey {
    switch (this) {
      case PrayerRulesErrorCode.invalidConfigurationSize:
        return 'prayer_rules_invalid_configuration_size';

      case PrayerRulesErrorCode.invalidJson:
        return 'prayer_rules_invalid_json';

      case PrayerRulesErrorCode.invalidConfigurationRoot:
        return 'prayer_rules_invalid_configuration_root';

      case PrayerRulesErrorCode.unsupportedSchemaVersion:
        return 'prayer_rules_unsupported_schema';

      case PrayerRulesErrorCode.invalidConfigurationVersion:
        return 'prayer_rules_invalid_version';

      case PrayerRulesErrorCode.invalidProfilesCollection:
        return 'prayer_rules_invalid_profiles';

      case PrayerRulesErrorCode.invalidProfileEntry:
        return 'prayer_rules_invalid_profile';

      case PrayerRulesErrorCode.invalidProfileId:
        return 'prayer_rules_invalid_profile_id';

      case PrayerRulesErrorCode.invalidCountryCode:
        return 'prayer_rules_invalid_country_code';

      case PrayerRulesErrorCode.invalidCalculationSettings:
        return 'prayer_rules_invalid_calculation_settings';

      case PrayerRulesErrorCode.duplicateProfileId:
        return 'prayer_rules_duplicate_profile_id';

      case PrayerRulesErrorCode.duplicateCountryProfile:
        return 'prayer_rules_duplicate_country_profile';

      case PrayerRulesErrorCode.unknownCalculationMethod:
        return 'prayer_rules_unknown_calculation_method';

      case PrayerRulesErrorCode.unknownMadhab:
        return 'prayer_rules_unknown_madhab';
    }
  }
}

/// A typed configuration error.
///
/// Extending FormatException preserves compatibility with callers
/// that already handle invalid configuration using FormatException.
class PrayerRulesException extends FormatException {
  const PrayerRulesException(
    this.code, {
    String? message,
    this.profileId,
    this.countryCode,
  }) : super(
          message ?? 'Invalid prayer rules configuration.',
        );

  final PrayerRulesErrorCode code;

  final String? profileId;

  final String? countryCode;

  String get localizationKey => code.localizationKey;
}

/// A validated prayer calculation profile.
///
/// Each profile represents one country or the GLOBAL fallback.
/// The calculation method and madhab are strongly typed.
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

  /// Stable identifier suitable for diagnostics and persistence.
  String get methodId => method.name;

  /// Stable identifier suitable for diagnostics and persistence.
  String get madhabId {
    return madhab == Madhab.hanafi ? 'hanafi' : 'shafi';
  }
}

/// Versioned and validated prayer-rules engine.
///
/// Responsibilities:
/// - Resolve a country-specific calculation profile.
/// - Provide a safe built-in fallback.
/// - Validate configuration data before installation.
/// - Prevent older configuration versions from replacing newer ones.
///
/// Deliberately outside this service:
/// - GPS and location permissions.
/// - Timezone discovery.
/// - Daylight-saving transitions.
/// - Prayer-time calculation.
/// - Network requests and remote authentication.
///
/// A remote configuration must be fetched, authenticated and verified
/// by another component before being passed to installConfiguration().
class PrayerRulesService {
  PrayerRulesService({
    required CalculationMethod fallbackMethod,
    Madhab fallbackMadhab = Madhab.shafi,
  })  : _fallbackMethod = fallbackMethod,
        _fallbackMadhab = fallbackMadhab;

  /// Current supported JSON schema.
  static const int supportedSchemaVersion = 1;

  /// Maximum accepted UTF-8 configuration size.
  static const int maximumConfigurationBytes = 65536;

  /// Maximum number of country profiles in one configuration.
  static const int maximumProfiles = 100;

  /// Maximum accepted profile identifier length.
  static const int maximumProfileIdLength = 64;

  /// Maximum accepted country code length before validation.
  static const int maximumCountryCodeLength = 16;

  final CalculationMethod _fallbackMethod;

  final Madhab _fallbackMadhab;

  int _configurationVersion = 0;

  Map<String, PrayerCalculationProfile> _profiles =
      <String, PrayerCalculationProfile>{};

  /// Version of the last successfully installed configuration.
  ///
  /// This value is intentionally preserved by resetToDefaults().
  int get configurationVersion => _configurationVersion;

  /// Number of installed country profiles.
  int get profileCount => _profiles.length;

  /// Indicates whether any configuration has been installed.
  ///
  /// The legacy getter name is retained for compatibility.
  /// It does not prove that a configuration came from a remote server.
  @Deprecated(
    'Use hasInstalledConfiguration instead. '
    'This service does not establish remote authenticity.',
  )
  bool get hasRemoteConfiguration => hasInstalledConfiguration;

  /// Indicates whether a validated configuration is installed.
  bool get hasInstalledConfiguration => _profiles.isNotEmpty;

  /// Returns an immutable snapshot of the installed profiles.
  Map<String, PrayerCalculationProfile> get installedProfiles {
    return Map<String, PrayerCalculationProfile>.unmodifiable(
      _profiles,
    );
  }

  /// Returns the built-in fallback profile.
  ///
  /// The fallback is not inserted into the installed profile map.
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
  /// 1. Exact ISO alpha-2 country match.
  /// 2. Installed GLOBAL profile.
  /// 3. Built-in fallback.
  ///
  /// Invalid or missing country codes safely fall back to GLOBAL.
  PrayerCalculationProfile resolve({
    required String countryCode,
  }) {
    final normalized = _normalizeCountryCode(countryCode);

    if (normalized != null) {
      final exactMatch = _profiles[normalized];

      if (exactMatch != null) {
        return exactMatch;
      }
    }

    return _profiles['GLOBAL'] ?? fallbackProfile;
  }

  /// Installs a fully validated JSON configuration.
  ///
  /// The current configuration remains unchanged if any validation
  /// step fails.
  ///
  /// Configuration versions must increase monotonically.
  ///
  /// Expected JSON structure:
  ///
  /// {
  ///   "schemaVersion": 1,
  ///   "version": 1,
  ///   "profiles": [
  ///     {
  ///       "id": "morocco_default",
  ///       "countryCode": "MA",
  ///       "method": "muslim_world_league",
  ///       "madhab": "maliki"
  ///     }
  ///   ]
  /// }
  ///
  /// Only madhabs supported by the installed adhan package are accepted.
  /// In this project that means hanafi and shafi.
  void installConfiguration(String jsonSource) {
    _validateConfigurationSize(jsonSource);

    final Object? decoded;

    try {
      decoded = jsonDecode(jsonSource);
    } on FormatException {
      throw const PrayerRulesException(
        PrayerRulesErrorCode.invalidJson,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const PrayerRulesException(
        PrayerRulesErrorCode.invalidConfigurationRoot,
      );
    }

    final schemaVersion = decoded['schemaVersion'];
    final version = decoded['version'];
    final profilesJson = decoded['profiles'];

    _validateSchemaVersion(schemaVersion);

    _validateConfigurationVersion(version);

    _validateProfilesCollection(profilesJson);

    final parsedProfiles =
        <String, PrayerCalculationProfile>{};

    final profileIds = <String>{};

    for (final item in profilesJson) {
      if (item is! Map<String, dynamic>) {
        throw const PrayerRulesException(
          PrayerRulesErrorCode.invalidProfileEntry,
        );
      }

      final profile = _parseProfile(item);

      if (!profileIds.add(profile.id)) {
        throw PrayerRulesException(
          PrayerRulesErrorCode.duplicateProfileId,
          profileId: profile.id,
          countryCode: profile.countryCode,
        );
      }

      if (parsedProfiles.containsKey(profile.countryCode)) {
        throw PrayerRulesException(
          PrayerRulesErrorCode.duplicateCountryProfile,
          profileId: profile.id,
          countryCode: profile.countryCode,
        );
      }

      parsedProfiles[profile.countryCode] = profile;
    }

    // Atomic replacement:
    // The existing map is untouched until every profile is valid.
    final nextProfiles =
        Map<String, PrayerCalculationProfile>.unmodifiable(
      parsedProfiles,
    );

    _profiles = nextProfiles;

    _configurationVersion = version as int;
  }

  /// Removes installed profiles and restores built-in fallback behavior.
  ///
  /// The last accepted version is intentionally preserved.
  /// This prevents older configurations from being reinstalled.
  void resetToDefaults() {
    _profiles = <String, PrayerCalculationProfile>{};
  }

  // ---------------------------------------------------------------------------
  // CONFIGURATION VALIDATION
  // ---------------------------------------------------------------------------

  void _validateConfigurationSize(String jsonSource) {
    if (jsonSource.isEmpty) {
      throw const PrayerRulesException(
        PrayerRulesErrorCode.invalidConfigurationSize,
      );
    }

    final byteLength = utf8.encode(jsonSource).length;

    if (byteLength > maximumConfigurationBytes) {
      throw const PrayerRulesException(
        PrayerRulesErrorCode.invalidConfigurationSize,
      );
    }
  }

  void _validateSchemaVersion(Object? value) {
    if (value != supportedSchemaVersion) {
      throw const PrayerRulesException(
        PrayerRulesErrorCode.unsupportedSchemaVersion,
      );
    }
  }

  void _validateConfigurationVersion(Object? value) {
    if (value is! int ||
        value <= _configurationVersion ||
        value < 1) {
      throw const PrayerRulesException(
        PrayerRulesErrorCode.invalidConfigurationVersion,
      );
    }
  }

  void _validateProfilesCollection(Object? value) {
    if (value is! List ||
        value.isEmpty ||
        value.length > maximumProfiles) {
      throw const PrayerRulesException(
        PrayerRulesErrorCode.invalidProfilesCollection,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // PROFILE PARSING
  // ---------------------------------------------------------------------------

  PrayerCalculationProfile _parseProfile(
    Map<String, dynamic> item,
  ) {
    final rawId = item['id'];
    final rawCountryCode = item['countryCode'];
    final rawMethod = item['method'];
    final rawMadhab = item['madhab'];

    final id = _normalizeProfileId(rawId);

    final countryCode = _normalizeRequiredCountryCode(
      rawCountryCode,
      profileId: id,
    );

    if (rawMethod is! String || rawMadhab is! String) {
      throw PrayerRulesException(
        PrayerRulesErrorCode.invalidCalculationSettings,
        profileId: id,
        countryCode: countryCode,
      );
    }

    final method = _findMethod(rawMethod);

    if (method == null) {
      throw PrayerRulesException(
        PrayerRulesErrorCode.unknownCalculationMethod,
        profileId: id,
        countryCode: countryCode,
      );
    }

    final madhab = _findMadhab(rawMadhab);

    if (madhab == null) {
      throw PrayerRulesException(
        PrayerRulesErrorCode.unknownMadhab,
        profileId: id,
        countryCode: countryCode,
      );
    }

    return PrayerCalculationProfile(
      id: id,
      countryCode: countryCode,
      method: method,
      madhab: madhab,
    );
  }

  String _normalizeProfileId(Object? value) {
    if (value is! String) {
      throw const PrayerRulesException(
        PrayerRulesErrorCode.invalidProfileId,
      );
    }

    final normalized = value.trim();

    if (normalized.isEmpty ||
        normalized.length > maximumProfileIdLength ||
        !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$')
            .hasMatch(normalized)) {
      throw const PrayerRulesException(
        PrayerRulesErrorCode.invalidProfileId,
      );
    }

    return normalized;
  }

  String _normalizeRequiredCountryCode(
    Object? value, {
    required String profileId,
  }) {
    if (value is! String) {
      throw PrayerRulesException(
        PrayerRulesErrorCode.invalidCountryCode,
        profileId: profileId,
      );
    }

    final normalized = _normalizeCountryCode(value);

    if (normalized == null) {
      throw PrayerRulesException(
        PrayerRulesErrorCode.invalidCountryCode,
        profileId: profileId,
      );
    }

    return normalized;
  }

  /// Normalizes an ISO alpha-2 country code or GLOBAL.
  ///
  /// Invalid values return null instead of throwing during resolution.
  String? _normalizeCountryCode(String value) {
    final normalized = value.trim().toUpperCase();

    if (normalized.isEmpty ||
        normalized.length > maximumCountryCodeLength) {
      return null;
    }

    if (normalized == 'GLOBAL') {
      return normalized;
    }

    if (!RegExp(r'^[A-Z]{2}$').hasMatch(normalized)) {
      return null;
    }

    return normalized;
  }

  // ---------------------------------------------------------------------------
  // CALCULATION METHOD AND MADHAB RESOLUTION
  // ---------------------------------------------------------------------------

  CalculationMethod? _findMethod(String name) {
    final normalized = name.trim().toLowerCase();

    if (normalized.isEmpty) {
      return null;
    }

    for (final method in CalculationMethod.values) {
      if (method.name.toLowerCase() == normalized) {
        return method;
      }
    }

    return null;
  }

  Madhab? _findMadhab(String name) {
    switch (name.trim().toLowerCase()) {
      case 'hanafi':
        return Madhab.hanafi;

      case 'shafi':
        return Madhab.shafi;

      default:
        return null;
    }
  }
}
