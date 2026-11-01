
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/qibla_landmark.dart';

/// Reads and validates Qibla Atlas landmarks from a bundled JSON asset.
///
/// This data source has no network dependency.
class QiblaLandmarkLocalDataSource {
  QiblaLandmarkLocalDataSource({
    AssetBundle? assetBundle,
    this.assetPath = 'assets/qibla/data/landmarks.json',
  }) : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;
  final String assetPath;

  /// Loads all landmarks from the local JSON asset.
  ///
  /// Throws [QiblaLandmarkDataException] if the asset is missing,
  /// malformed, or contains invalid records.
  Future<List<QiblaLandmark>> loadLandmarks() async {
    try {
      final jsonString = await _assetBundle.loadString(assetPath);
      final decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        throw const QiblaLandmarkDataException(
          'The landmarks JSON root must be a list.',
        );
      }

      final landmarks = <QiblaLandmark>[];
      final identifiers = <String>{};

      for (var index = 0; index < decoded.length; index++) {
        final record = decoded[index];

        if (record is! Map) {
          throw QiblaLandmarkDataException(
            'Invalid landmark record at index $index.',
          );
        }

        final landmark = _parseLandmark(
          Map<String, dynamic>.from(record),
          index,
        );

        if (!identifiers.add(landmark.id)) {
          throw QiblaLandmarkDataException(
            'Duplicate landmark identifier: ${landmark.id}.',
          );
        }

        landmarks.add(landmark);
      }

      return List<QiblaLandmark>.unmodifiable(landmarks);
    } on QiblaLandmarkDataException {
      rethrow;
    } on FormatException catch (error) {
      throw QiblaLandmarkDataException(
        'Invalid landmarks JSON: ${error.message}',
      );
    } on FlutterError catch (error) {
      throw QiblaLandmarkDataException(
        'Unable to load local landmarks asset: ${error.message}',
      );
    }
  }

  QiblaLandmark _parseLandmark(
    Map<String, dynamic> json,
    int index,
  ) {
    final id = _requiredString(json, 'id', index);
    final nameAr = _requiredString(json, 'nameAr', index);
    final nameEn = _requiredString(json, 'nameEn', index);
    final countryCode = _requiredString(
      json,
      'countryCode',
      index,
    ).toUpperCase();

    if (!RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
      throw QiblaLandmarkDataException(
        'Invalid ISO country code in record $index.',
      );
    }

    final latitude = _requiredDouble(json, 'latitude', index);
    final longitude = _requiredDouble(json, 'longitude', index);

    if (latitude < -90 || latitude > 90) {
      throw QiblaLandmarkDataException(
        'Latitude out of range in record $index.',
      );
    }

    if (longitude < -180 || longitude > 180) {
      throw QiblaLandmarkDataException(
        'Longitude out of range in record $index.',
      );
    }

    final category = _parseCategory(
      _requiredString(json, 'category', index),
      index,
    );

    final imageAsset = _optionalString(json, 'imageAsset');
    if (imageAsset != null &&
        (!_isLocalAssetPath(imageAsset))) {
      throw QiblaLandmarkDataException(
        'Invalid local image asset path in record $index.',
      );
    }

    final sourceUrl = _optionalString(json, 'sourceUrl');
    if (sourceUrl != null && !_isValidSourceUrl(sourceUrl)) {
      throw QiblaLandmarkDataException(
        'Invalid source URL in record $index.',
      );
    }

    final lastVerifiedAt = _optionalString(
      json,
      'lastVerifiedAt',
    );

    if (lastVerifiedAt != null &&
        DateTime.tryParse(lastVerifiedAt) == null) {
      throw QiblaLandmarkDataException(
        'Invalid verification date in record $index.',
      );
    }

    return QiblaLandmark(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      category: category,
      latitude: latitude,
      longitude: longitude,
      countryCode: countryCode,
      descriptionAr: _optionalString(json, 'descriptionAr'),
      descriptionEn: _optionalString(json, 'descriptionEn'),
      imageAsset: imageAsset,
      sourceName: _optionalString(json, 'sourceName'),
      sourceUrl: sourceUrl,
      license: _optionalString(json, 'license'),
      lastVerifiedAt: lastVerifiedAt,
      isFeatured: _optionalBool(
        json,
        'isFeatured',
        defaultValue: false,
      ),
    );
  }

  String _requiredString(
    Map<String, dynamic> json,
    String key,
    int index,
  ) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw QiblaLandmarkDataException(
        'Missing or invalid "$key" in record $index.',
      );
    }

    return value.trim();
  }

  String? _optionalString(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];

    if (value == null) return null;

    if (value is! String) {
      throw QiblaLandmarkDataException(
        'Optional field "$key" must be a string.',
      );
    }

    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  double _requiredDouble(
    Map<String, dynamic> json,
    String key,
    int index,
  ) {
    final value = json[key];

    if (value is! num || !value.toDouble().isFinite) {
      throw QiblaLandmarkDataException(
        'Missing or invalid "$key" in record $index.',
      );
    }

    return value.toDouble();
  }

  bool _optionalBool(
    Map<String, dynamic> json,
    String key, {
    required bool defaultValue,
  }) {
    final value = json[key];

    if (value == null) return defaultValue;

    if (value is! bool) {
      throw QiblaLandmarkDataException(
        'Optional field "$key" must be a boolean.',
      );
    }

    return value;
  }

  QiblaLandmarkCategory _parseCategory(
    String value,
    int index,
  ) {
    for (final category in QiblaLandmarkCategory.values) {
      if (category.name == value) {
        return category;
      }
    }

    throw QiblaLandmarkDataException(
      'Unknown landmark category "$value" in record $index.',
    );
  }

  bool _isLocalAssetPath(String path) {
    return path.startsWith('assets/') &&
        !path.startsWith('/') &&
        !path.contains('..') &&
        !path.contains('://');
  }

  bool _isValidSourceUrl(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }
}

/// Represents invalid or unavailable local landmark data.
class QiblaLandmarkDataException implements Exception {
  const QiblaLandmarkDataException(this.message);

  final String message;

  @override
  String toString() => 'QiblaLandmarkDataException: $message';
}
