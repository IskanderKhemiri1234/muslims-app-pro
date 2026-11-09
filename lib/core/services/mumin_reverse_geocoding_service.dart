import 'package:flutter/services.dart';

/// A best-effort, device-backed reverse-geocoding result.
///
/// Coordinates remain the source of truth for prayer calculations.
/// Place labels are presentation metadata only.
class MuminPlaceName {
  const MuminPlaceName({
    this.placeName,
    this.city,
    this.region,
    this.country,
    this.formattedAddress,
  });

  final String? placeName;
  final String? city;
  final String? region;
  final String? country;
  final String? formattedAddress;

  bool get hasUsefulName =>
      _hasText(placeName) ||
      _hasText(city) ||
      _hasText(region) ||
      _hasText(country);

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}

/// Resolves coordinates to human-readable place names using Android's
/// installed geocoding provider. It does not bundle or upload GPS history.
class MuminReverseGeocodingService {
  static const MethodChannel _channel = MethodChannel(
    'com.iskander.muslimspro/app_info',
  );

  Future<MuminPlaceName?> resolve({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    final normalizedLanguage = const {'ar', 'en', 'fr'}
            .contains(languageCode.trim().toLowerCase())
        ? languageCode.trim().toLowerCase()
        : 'en';

    try {
      final response =
          await _channel.invokeMapMethod<String, dynamic>(
        'reverseGeocode',
        <String, Object>{
          'latitude': latitude,
          'longitude': longitude,
          'languageCode': normalizedLanguage,
        },
      );

      if (response == null) return null;

      String? readText(String key) {
        final value = response[key];
        if (value is! String || value.trim().isEmpty) return null;
        return value.trim();
      }

      final result = MuminPlaceName(
        placeName: readText('placeName'),
        city: readText('city'),
        region: readText('region'),
        country: readText('country'),
        formattedAddress: readText('formattedAddress'),
      );

      return result.hasUsefulName ? result : null;
    } on PlatformException catch (error) {
      // Geocoding availability depends on the Android device/provider.
      // Keep the existing coordinate-based prayer experience usable.
      // ignore: avoid_print
      print('Mumin reverse geocoding unavailable: ${error.code}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
