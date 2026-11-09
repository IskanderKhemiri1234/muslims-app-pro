import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MuminAppUpdateInfo {
  const MuminAppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.apkUri,
    required this.apkSize,
    required this.isUpdateAvailable,
  });

  final String currentVersion;
  final String latestVersion;
  final Uri apkUri;
  final int apkSize;
  final bool isUpdateAvailable;
}

class MuminAppUpdateService {
  static const MethodChannel _appInfoChannel = MethodChannel(
    'com.iskander.muslimspro/app_info',
  );

  static const String _userAgent = 'MuminPro-Android-Updater';
  static final Uri _latestReleaseUri = Uri.https(
    'api.github.com',
    '/repos/IskanderKhemiri1234/muslims-app-pro/releases/latest',
  );

  Future<MuminAppUpdateInfo> checkForUpdate() async {
    final currentVersion = await _appInfoChannel.invokeMethod<String>(
      'getAppVersion',
    );
    if (currentVersion == null || currentVersion.trim().isEmpty) {
      throw StateError('Unable to read the installed app version.');
    }

    final response = await http
        .get(
          _latestReleaseUri,
          headers: const {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
            'User-Agent': _userAgent,
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != HttpStatus.ok) {
      throw StateError(
        'Update service returned HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid release response.');
    }

    if (decoded['draft'] == true || decoded['prerelease'] == true) {
      throw const FormatException('The latest release is not stable.');
    }

    final tag = decoded['tag_name'];
    if (tag is! String || tag.trim().isEmpty) {
      throw const FormatException('Release version is missing.');
    }

    final latestVersion = tag.trim().replaceFirst(
      RegExp(r'^[vV]'),
      '',
    );
    if (!_isValidVersion(latestVersion)) {
      throw const FormatException('Release version is invalid.');
    }

    final assets = decoded['assets'];
    if (assets is! List) {
      throw const FormatException('Release assets are missing.');
    }

    Uri? apkUri;
    var apkSize = 0;
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      if (asset['name'] != 'app-release.apk') continue;

      final downloadUrl = asset['browser_download_url'];
      final size = asset['size'];
      if (downloadUrl is! String || size is! int || size <= 0) {
        throw const FormatException('The release APK metadata is invalid.');
      }

      final candidate = Uri.tryParse(downloadUrl);
      if (candidate == null ||
          candidate.scheme != 'https' ||
          candidate.host != 'github.com') {
        throw const FormatException('The release APK URL is invalid.');
      }

      apkUri = candidate;
      apkSize = size;
      break;
    }

    if (apkUri == null || apkSize <= 0) {
      throw const FormatException(
        'The latest stable release does not contain app-release.apk.',
      );
    }

    return MuminAppUpdateInfo(
      currentVersion: currentVersion.trim(),
      latestVersion: latestVersion,
      apkUri: apkUri,
      apkSize: apkSize,
      isUpdateAvailable:
          _compareVersions(latestVersion, currentVersion) > 0,
    );
  }

  /// Downloads the published APK and opens Android's explicit installer.
  /// Installation remains under the user's control.
  Future<void> downloadAndInstall(MuminAppUpdateInfo update) async {
    if (!update.isUpdateAvailable) {
      throw StateError('The installed app is already up to date.');
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', update.apkUri)
        ..headers.addAll(const {
          'Accept': 'application/octet-stream',
          'User-Agent': _userAgent,
        });

      final streamedResponse = await client
          .send(request)
          .timeout(const Duration(seconds: 90));

      if (streamedResponse.statusCode != HttpStatus.ok) {
        throw StateError(
          'APK download failed with HTTP ${streamedResponse.statusCode}.',
        );
      }

      final temporaryDirectory = await getTemporaryDirectory();
      final updateDirectory = Directory(
        '${temporaryDirectory.path}/mumin_updates',
      );
      await updateDirectory.create(recursive: true);

      final safeVersion = update.latestVersion.replaceAll(
        RegExp(r'[^0-9A-Za-z._-]'),
        '_',
      );
      final apkFile = File(
        '${updateDirectory.path}/mumin-pro-$safeVersion.apk',
      );

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final sink = apkFile.openWrite();
      try {
        await streamedResponse.stream.pipe(sink);
      } catch (_) {
        await sink.close();
        if (await apkFile.exists()) {
          await apkFile.delete();
        }
        rethrow;
      }

      final downloadedSize = await apkFile.length();
      if (downloadedSize != update.apkSize) {
        await apkFile.delete();
        throw FormatException(
          'APK size mismatch: expected ${update.apkSize}, '
          'received $downloadedSize.',
        );
      }

      await _appInfoChannel.invokeMethod<void>(
        'installApk',
        <String, Object>{'filePath': apkFile.path},
      );
    } finally {
      client.close();
    }
  }

  bool _isValidVersion(String version) {
    return RegExp(r'^\d+(?:\.\d+){2,}$').hasMatch(version);
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
      final firstPart = index < firstParts.length ? firstParts[index] : 0;
      final secondPart = index < secondParts.length ? secondParts[index] : 0;

      if (firstPart != secondPart) {
        return firstPart.compareTo(secondPart);
      }
    }

    return 0;
  }
}
