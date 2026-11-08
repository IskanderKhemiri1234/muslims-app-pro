
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/nearby_mosque_data_source_config.dart';

/// Mumin Pro — OpenStreetMap Overpass HTTP Client.
///
/// Responsible only for HTTP transport and JSON decoding.
/// Query construction and mosque parsing belong to separate classes.
final class OpenStreetMapOverpassClient {
  OpenStreetMapOverpassClient({
    http.Client? httpClient,
  })  : _client = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  final http.Client _client;
  final bool _ownsClient;

  bool _isClosed = false;

  /// Sends an Overpass QL query and returns its decoded JSON response.
  ///
  /// Configured fallback endpoints are tried when a server is unavailable,
  /// rate-limited, or returns a server-side error.
  ///
  /// Throws [ArgumentError] for an empty query.
  /// Throws [StateError] after this client has been closed.
  /// Throws [OverpassRequestException] when all usable attempts fail.
  Future<Map<String, dynamic>> execute(String query) async {
    if (_isClosed) {
      throw StateError('The Overpass client has been closed.');
    }

    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      throw ArgumentError.value(query, 'query', 'Query cannot be empty.');
    }

    final failures = <String>[];

    for (final endpoint
        in NearbyMosqueDataSourceConfig.endpoints) {
      if (!NearbyMosqueDataSourceConfig.isValidEndpoint(endpoint)) {
        failures.add('Invalid endpoint configuration: $endpoint');
        continue;
      }

      try {
        final response = await _client
            .post(
              Uri.parse(endpoint),
              headers: const {
                'Accept': 'application/json',
                'User-Agent':
                    NearbyMosqueDataSourceConfig.userAgent,
              },
              body: {
                'data': normalizedQuery,
              },
            )
            .timeout(
              NearbyMosqueDataSourceConfig.requestTimeout,
            );

        if (response.statusCode == 200) {
          return _decodeResponse(response.body);
        }

        final message =
            'HTTP ${response.statusCode} from $endpoint';

        failures.add(message);

        if (!_shouldTryNextEndpoint(response.statusCode)) {
          throw OverpassRequestException(
            message: message,
            statusCode: response.statusCode,
          );
        }
      } on OverpassRequestException {
        rethrow;
      } on FormatException catch (error) {
        failures.add('Invalid JSON from $endpoint: $error');
      } on http.ClientException catch (error) {
        failures.add('Connection failure at $endpoint: $error');
      } on Exception catch (error) {
        failures.add('Request failure at $endpoint: $error');
      }
    }

    throw OverpassRequestException(
      message: failures.isEmpty
          ? 'No usable Overpass endpoint was available.'
          : failures.join('\n'),
    );
  }

  Map<String, dynamic> _decodeResponse(String body) {
    final decoded = jsonDecode(body);

    if (decoded is! Map) {
      throw const FormatException(
        'Overpass response must be a JSON object.',
      );
    }

    final response = Map<String, dynamic>.from(decoded);

    final elements = response['elements'];

    if (elements is! List) {
      throw const FormatException(
        'Overpass response does not contain a valid elements list.',
      );
    }

    return response;
  }

  bool _shouldTryNextEndpoint(int statusCode) {
    return statusCode == 408 ||
        statusCode == 429 ||
        statusCode >= 500;
  }

  /// Closes the internally created HTTP client.
  ///
  /// An externally injected client remains owned by its caller.
  void close() {
    if (_isClosed) return;

    _isClosed = true;

    if (_ownsClient) {
      _client.close();
    }
  }
}

/// Represents an unsuccessful Overpass HTTP request.
final class OverpassRequestException implements Exception {
  const OverpassRequestException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return 'OverpassRequestException: $message';
    }

    return 'OverpassRequestException '
        '(HTTP $statusCode): $message';
  }
}
