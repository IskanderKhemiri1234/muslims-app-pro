
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/qibla_landmark.dart';

class QiblaLandmarkLocalDataSource {
  QiblaLandmarkLocalDataSource({
    AssetBundle? assetBundle,
    this.assetPath = 'assets/qibla/data/landmarks.json',
  }) : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;
  final String assetPath;

  Future<List<QiblaLandmark>> loadLandmarks() async {
    try {
      final String rawJson = await _assetBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(rawJson);

      if (decoded is! List) {
        throw const QiblaLandmarkDataException(
          'The landmarks JSON root must be a list.',
        );
      }

      final List<QiblaLandmark> landmarks = [];
      final Set<String> ids = {};

      for (var index = 0; index < decoded.length; index++) {
        final dynamic record = decoded[index];

        if (record is! Map) {
          throw QiblaLandmarkDataException(
            'Landmark at index $index must be a JSON object.',
          );
        }

        final landmark = _parseLandmark(
          Map<String, dynamic>.from(record),
          index,
        );

        if (!ids.add(landmark.id)) {
          throw QiblaLandmarkDataException(
            'Duplicate landmark ID: ${landmark.id}',
          );
        }

        landmarks.add(landmark);
      }

      return List.unmodifiable(landmarks);
    } on QiblaLandmarkDataException {
      rethrow;
    } catch (error) {
      throw QiblaLandmarkDataException(
        'Unable to load landmarks from $assetPath: $error',
      );
    }
  }

  QiblaLandmark _parseLandmark(
    Map<String, dynamic> json,
    int index,
  ) {
    final String id = _requiredString(json, 'id', index);
    final String nameAr = _requiredString(json, 'nameAr', index);
    final String nameEn = _requiredString(json, 'nameEn', index);
    final String countryCode =
        _requiredString(json, 'countryCode', index).toUpperCase();

    if (!RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
      _fail(index, 'countryCode must contain exactly two letters.');
    }

    final double latitude = _requiredDouble(json, 'latitude', index);
    final double longitude = _requiredDouble(json, 'longitude', index);

    if (latitude < -90 || latitude > 90) {
      _fail(index, 'latitude must be between -90 and 90.');
    }

    if (longitude < -180 || longitude > 180) {
      _fail(index, 'longitude must be between -180 and 180.');
    }

    final QiblaLandmarkCategory category =
        _parseCategory(json['category'], index);

    final List<QiblaLandmarkSource> sources =
        _parseSources(json['sources'], index);

    final List<QiblaLandmarkImage> images =
        _parseImages(json['images'], index);

    final List<QiblaLandmarkHistoricalEvent> historicalEvents =
        _parseHistoricalEvents(
      json['historicalEvents'],
      index,
    );

    final Set<String> sourceIds =
        sources.map((source) => source.id).toSet();

    for (final event in historicalEvents) {
      for (final sourceId in event.sourceIds) {
        if (!sourceIds.contains(sourceId)) {
          _fail(
            index,
            'Historical event "${event.id}" references '
            'an unknown source "$sourceId".',
          );
        }
      }
    }

    final String? imageAsset =
        _optionalString(json, 'imageAsset', index);

    final String? sourceName =
        _optionalString(json, 'sourceName', index);

    final String? sourceUrl =
        _optionalString(json, 'sourceUrl', index);

    final String? license =
        _optionalString(json, 'license', index);

    final String? lastVerifiedAt =
        _optionalString(json, 'lastVerifiedAt', index);

    _validateAssetPath(imageAsset, index);
    _validateUrl(sourceUrl, index, 'sourceUrl');

    if (lastVerifiedAt != null &&
        DateTime.tryParse(lastVerifiedAt) == null) {
      _fail(index, 'lastVerifiedAt must be a valid ISO date.');
    }

    return QiblaLandmark(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      category: category,
      latitude: latitude,
      longitude: longitude,
      countryCode: countryCode,
      descriptionAr: _optionalString(json, 'descriptionAr', index),
      descriptionEn: _optionalString(json, 'descriptionEn', index),
      cityAr: _optionalString(json, 'cityAr', index),
      cityEn: _optionalString(json, 'cityEn', index),
      regionAr: _optionalString(json, 'regionAr', index),
      regionEn: _optionalString(json, 'regionEn', index),
      historicalPeriodAr:
          _optionalString(json, 'historicalPeriodAr', index),
      historicalPeriodEn:
          _optionalString(json, 'historicalPeriodEn', index),
      establishedYear:
          _optionalInt(json, 'establishedYear', index),
      images: images,
      historicalEvents: historicalEvents,
      sources: sources,
      imageAsset: imageAsset,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      license: license,
      lastVerifiedAt: lastVerifiedAt,
      isFeatured: _optionalBool(
        json,
        'isFeatured',
        false,
        index,
      ),
    );
  }

  QiblaLandmarkCategory _parseCategory(
    dynamic value,
    int index,
  ) {
    if (value is! String || value.trim().isEmpty) {
      _fail(index, 'category is required.');
    }

    final categoryName = value.trim();

    for (final category in QiblaLandmarkCategory.values) {
      if (category.name == categoryName) {
        return category;
      }
    }

    _fail(index, 'Unknown category "$categoryName".');
  }

  List<QiblaLandmarkSource> _parseSources(
    dynamic value,
    int index,
  ) {
    if (value == null) return const [];

    if (value is! List) {
      _fail(index, 'sources must be a list.');
    }

    final result = <QiblaLandmarkSource>[];
    final ids = <String>{};

    for (final item in value) {
      if (item is! Map) {
        _fail(index, 'Each source must be an object.');
      }

      final json = Map<String, dynamic>.from(item);

      final id = _requiredString(json, 'id', index);

      if (!ids.add(id)) {
        _fail(index, 'Duplicate source ID "$id".');
      }

      final url = _requiredString(json, 'url', index);
      _validateUrl(url, index, 'source.url');

      final accessedAt =
          _optionalString(json, 'accessedAt', index);

      if (accessedAt != null &&
          DateTime.tryParse(accessedAt) == null) {
        _fail(index, 'source.accessedAt must be a valid ISO date.');
      }

      result.add(
        QiblaLandmarkSource(
          id: id,
          name: _requiredString(json, 'name', index),
          url: url,
          sourceType: _requiredString(json, 'sourceType', index),
          accessedAt: accessedAt ?? '',
          publisher: _optionalString(json, 'publisher', index),
          license: _optionalString(json, 'license', index),
        ),
      );
    }

    return List.unmodifiable(result);
  }

  List<QiblaLandmarkImage> _parseImages(
    dynamic value,
    int index,
  ) {
    if (value == null) return const [];

    if (value is! List) {
      _fail(index, 'images must be a list.');
    }

    final result = <QiblaLandmarkImage>[];
    final paths = <String>{};
    final ids = <String>{};
    var primaryCount = 0;

    for (final item in value) {
      if (item is! Map) {
        _fail(index, 'Each image must be an object.');
      }

      final json = Map<String, dynamic>.from(item);

      final assetPath =
          _requiredString(json, 'assetPath', index);

      _validateAssetPath(assetPath, index);

      if (!paths.add(assetPath)) {
        _fail(index, 'Duplicate image asset path "$assetPath".');
      }

      final imageId =
          _optionalString(json, 'id', index) ?? assetPath;

      if (!ids.add(imageId)) {
        _fail(index, 'Duplicate image ID "$imageId".');
      }

      final creator = _requiredString(json, 'creator', index);
      final sourceName =
          _requiredString(json, 'sourceName', index);
      final sourceUrl =
          _requiredString(json, 'sourceUrl', index);
      final license = _requiredString(json, 'license', index);

      _validateUrl(sourceUrl, index, 'image.sourceUrl');

      final isPrimary = _optionalBool(
        json,
        'isPrimary',
        false,
        index,
      );

      if (isPrimary) primaryCount++;

      result.add(
        QiblaLandmarkImage(
          id: imageId,
          assetPath: assetPath,
          captionAr:
              _optionalString(json, 'captionAr', index) ?? '',
          captionEn:
              _optionalString(json, 'captionEn', index) ?? '',
          creator: creator,
          sourceName: sourceName,
          sourceUrl: sourceUrl,
          license: license,
          isPrimary: isPrimary,
          width: _optionalInt(json, 'width', index),
          height: _optionalInt(json, 'height', index),
        ),
      );
    }

    if (primaryCount > 1) {
      _fail(index, 'Only one image can be marked as primary.');
    }

    return List.unmodifiable(result);
  }

  List<QiblaLandmarkHistoricalEvent> _parseHistoricalEvents(
    dynamic value,
    int index,
  ) {
    if (value == null) return const [];

    if (value is! List) {
      _fail(index, 'historicalEvents must be a list.');
    }

    final result = <QiblaLandmarkHistoricalEvent>[];
    final ids = <String>{};

    for (final item in value) {
      if (item is! Map) {
        _fail(index, 'Each historical event must be an object.');
      }

      final json = Map<String, dynamic>.from(item);
      final id = _requiredString(json, 'id', index);

      if (!ids.add(id)) {
        _fail(index, 'Duplicate historical event ID "$id".');
      }

      final startYear =
          _optionalInt(json, 'startYear', index);
      final endYear =
          _optionalInt(json, 'endYear', index);

      if (startYear != null &&
          endYear != null &&
          startYear > endYear) {
        _fail(
          index,
          'Historical event "$id" has startYear after endYear.',
        );
      }

      final sourceIds = _parseStringList(
        json['sourceIds'],
        index,
        'historicalEvent.sourceIds',
      );

      result.add(
        QiblaLandmarkHistoricalEvent(
          id: id,
          titleAr: _requiredString(json, 'titleAr', index),
          titleEn: _requiredString(json, 'titleEn', index),
          descriptionAr:
              _requiredString(json, 'descriptionAr', index),
          descriptionEn:
              _requiredString(json, 'descriptionEn', index),
          dateLabelAr:
              _requiredString(json, 'dateLabelAr', index),
          dateLabelEn:
              _requiredString(json, 'dateLabelEn', index),
          sortOrder: _optionalInt(json, 'sortOrder', index) ?? 0,
          startYear: startYear,
          endYear: endYear,
          calendar: _optionalString(json, 'calendar', index),
          sourceIds: sourceIds,
        ),
      );
    }

    return List.unmodifiable(result);
  }

  List<String> _parseStringList(
    dynamic value,
    int index,
    String field,
  ) {
    if (value == null) return const [];

    if (value is! List) {
      _fail(index, '$field must be a list.');
    }

    final result = <String>[];

    for (final item in value) {
      if (item is! String || item.trim().isEmpty) {
        _fail(index, '$field must contain non-empty strings.');
      }

      final normalizedItem = item.trim();

      if (result.contains(normalizedItem)) {
        _fail(index, '$field contains duplicate values.');
      }

      result.add(normalizedItem);
    }

    return List.unmodifiable(result);
  }

  String _requiredString(
    Map<String, dynamic> json,
    String key,
    int index,
  ) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      _fail(
        index,
        '$key is required and must be a non-empty string.',
      );
    }

    return value.trim();
  }

  String? _optionalString(
    Map<String, dynamic> json,
    String key,
    int index,
  ) {
    final value = json[key];

    if (value == null) return null;

    if (value is! String) {
      _fail(index, '$key must be a string or null.');
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  double _requiredDouble(
    Map<String, dynamic> json,
    String key,
    int index,
  ) {
    final value = json[key];

    if (value is! num || !value.toDouble().isFinite) {
      _fail(index, '$key must be a finite number.');
    }

    return value.toDouble();
  }

  int? _optionalInt(
    Map<String, dynamic> json,
    String key,
    int index,
  ) {
    final value = json[key];

    if (value == null) return null;

    if (value is! int) {
      _fail(index, '$key must be an integer or null.');
    }

    return value;
  }

  bool _optionalBool(
    Map<String, dynamic> json,
    String key,
    bool defaultValue,
    int index,
  ) {
    final value = json[key];

    if (value == null) return defaultValue;

    if (value is! bool) {
      _fail(index, '$key must be a boolean.');
    }

    return value;
  }

  void _validateAssetPath(String? path, int index) {
    if (path == null) return;

    if (!path.startsWith('assets/') ||
        path.contains('..') ||
        path.contains('\\') ||
        path.startsWith('//')) {
      _fail(index, 'Invalid local asset path "$path".');
    }

    if (Uri.tryParse(path)?.hasScheme == true) {
      _fail(index, 'Image assets must use local paths, not URLs.');
    }
  }

  void _validateUrl(
    String? value,
    int index,
    String field,
  ) {
    if (value == null) return;

    final uri = Uri.tryParse(value);

    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      _fail(index, '$field must be a valid HTTP or HTTPS URL.');
    }
  }

  Never _fail(int index, String message) {
    throw QiblaLandmarkDataException(
      'Invalid landmark at index $index: $message',
    );
  }
}

class QiblaLandmarkDataException implements Exception {
  const QiblaLandmarkDataException(this.message);

  final String message;

  @override
  String toString() => 'QiblaLandmarkDataException: $message';
}
