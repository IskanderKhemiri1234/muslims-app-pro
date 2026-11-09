import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class MuminAppUpdateInfo {
  const MuminAppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.apkUri,
    required this.isUpdateAvailable,
  });

  final String currentVersion;
  final String latestVersion;
  final Uri apkUri;
  final bool isUpdateAvailable;
}

class MuminAppUpdateService {
  static final Uri _latestReleaseUri = Uri.https(
    'api.github.com',
    '/repos/IskanderKhemiri1234/muslims-app-pro/releases/latest',
  );

  Future<MuminAppUpdateInfo> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final response = await http
        .get(
          _latestReleaseUri,
          headers: const {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw StateError(
        'Update service returned HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid release response.');
    }

    final tag = decoded['tag_name'];
    if (tag is! String || tag.trim().isEmpty) {
      throw const FormatException('Release version is missing.');
    }

    final latestVersion = tag.trim().replaceFirst(
      RegExp(r'^[vV]'),
      '',
    );
    final assets = decoded['assets'];
    if (assets is! List) {
      throw const FormatException('Release assets are missing.');
    }

    Uri? apkUri;
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = asset['name'];
      final downloadUrl = asset['browser_download_url'];
      if (name is String &&
          name.toLowerCase().endsWith('.apk') &&
          downloadUrl is String) {
        apkUri = Uri.tryParse(downloadUrl);
        if (apkUri != null && apkUri.scheme == 'https') break;
        apkUri = null;
      }
    }

    if (apkUri == null) {
      throw const FormatException(
        'The latest release does not contain an APK.',
      );
    }

    final currentVersion = packageInfo.version;
    return MuminAppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      apkUri: apkUri,
      isUpdateAvailable:
          _compareVersions(latestVersion, currentVersion) > 0,
    );
  }

  int _compareVersions(String first, String second) {
    final firstParts = RegExp(r'\d+')
        .allMatches(first)
        .map((match) => int.parse(match.group(0)!))
        .toList();
    final secondParts = RegExp(r'\d+')
        .allMatches(second)
        .map((match) => int.parse(match.group(0)!))
        .toList();

    final length = firstParts.length > secondParts.length
        ? firstParts.length
        : secondParts.length;

    for (var index = 0; index < length; index++) {
      final firstPart =
          index < firstParts.length ? firstParts[index] : 0;
      final secondPart =
          index < secondParts.length ? secondParts[index] : 0;

      if (firstPart != secondPart) {
        return firstPart.compareTo(secondPart);
      }
    }

    return 0;
  }
}
