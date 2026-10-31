
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result returned by a geographic timezone provider.
class TimezoneLookupResult {
  final String timezoneId;
  final String? countryCode;

  const TimezoneLookupResult({
    required this.timezoneId,
    this.countryCode,
  });
}

/// Contract for timezone lookup providers.
abstract class TimezoneLookupDataSource {
  Future<TimezoneLookupResult> lookup({
    required double latitude,
    required double longitude,
  });
}

/// GeoNames implementation.
///
/// Register your own GeoNames username:
/// https://www.geonames.org/login
class GeoNamesTimezoneDataSource
    implements TimezoneLookupDataSource {
  final http.Client client;
  final String username;
  final Duration timeout;

  GeoNamesTimezoneDataSource({
    required this.username,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : client = client ?? http.Client() {
    if (username.trim().isEmpty) {
      throw ArgumentError('GeoNames username is required.');
    }
  }

  @override
  Future<TimezoneLookupResult> lookup({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'api.geonames.org',
      '/timezoneJSON',
      {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'username': username.trim(),
      },
    );

    final response = await client
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
          },
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Timezone provider returned HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid timezone provider response.',
      );
    }

    // GeoNames reports provider errors in a status object.
    if (decoded.containsKey('status')) {
      final status = decoded['status'];

      final message = status is Map
          ? status['message']?.toString()
          : null;

      throw Exception(
        message ?? 'Timezone lookup failed.',
      );
    }

    final timezoneId = decoded['timezoneId'];

    if (timezoneId is! String || timezoneId.trim().isEmpty) {
      throw const FormatException(
        'Timezone ID is missing from provider response.',
      );
    }

    final countryCode = decoded['countryCode'];

    return TimezoneLookupResult(
      timezoneId: timezoneId.trim(),
      countryCode: countryCode is String
          ? countryCode.trim().toUpperCase()
          : null,
    );
  }

  void close() {
    client.close();
  }
}
