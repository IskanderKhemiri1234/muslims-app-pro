
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user-selected Adhan artwork.
///
/// Images are copied into the application's private documents directory.
/// Only the local file path is stored in SharedPreferences.
/// No image is uploaded or shared externally.
class MuminAdhanArtworkService {
  MuminAdhanArtworkService({
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  static const String _preferenceKey =
      'mumin_adhan_artwork_path';

  static const String _directoryName =
      'adhan_artwork';

  static const Set<String> _allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  final ImagePicker _imagePicker;

  /// Opens the system image picker and saves the selected image locally.
  ///
  /// Returns null when the user cancels the picker.
  Future<File?> pickAndSaveArtwork() async {
    final XFile? selectedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2400,
      maxHeight: 2400,
    );

    if (selectedImage == null) {
      return null;
    }

    final extension = _resolveExtension(selectedImage.path);

    final directory = await _getArtworkDirectory();

    final fileName =
        'adhan_${DateTime.now().microsecondsSinceEpoch}$extension';

    final destination = File(
      '${directory.path}${Platform.pathSeparator}$fileName',
    );

    final preferences = await SharedPreferences.getInstance();

    final previousPath = preferences.getString(_preferenceKey);

    try {
      final savedFile = await File(selectedImage.path).copy(
        destination.path,
      );

      final persisted = await preferences.setString(
        _preferenceKey,
        savedFile.path,
      );

      if (!persisted) {
        throw StateError(
          'Could not save the Adhan artwork preference.',
        );
      }

      await _deletePreviousManagedFile(previousPath);

      return savedFile;
    } catch (_) {
      if (await destination.exists()) {
        await destination.delete();
      }

      rethrow;
    }
  }

  /// Returns the saved artwork when it still exists.
  ///
  /// Removes stale preferences when the file is missing.
  Future<File?> getSavedArtwork() async {
    final preferences = await SharedPreferences.getInstance();

    final savedPath = preferences.getString(_preferenceKey);

    if (savedPath == null || savedPath.trim().isEmpty) {
      return null;
    }

    final file = File(savedPath);

    if (await file.exists()) {
      return file;
    }

    await preferences.remove(_preferenceKey);

    return null;
  }

  /// Removes the selected artwork and its stored preference.
  Future<void> clearArtwork() async {
    final preferences = await SharedPreferences.getInstance();

    final savedPath = preferences.getString(_preferenceKey);

    await preferences.remove(_preferenceKey);

    await _deletePreviousManagedFile(savedPath);
  }

  /// Indicates whether a valid saved artwork is available.
  Future<bool> get hasArtwork async {
    return await getSavedArtwork() != null;
  }

  Future<Directory> _getArtworkDirectory() async {
    final documentsDirectory =
        await getApplicationDocumentsDirectory();

    final directory = Directory(
      '${documentsDirectory.path}'
      '${Platform.pathSeparator}'
      '$_directoryName',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  String _resolveExtension(String sourcePath) {
    final separatorIndex = sourcePath.lastIndexOf(
      Platform.pathSeparator,
    );

    final fileName = sourcePath.substring(separatorIndex + 1);

    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex < 0) {
      return '.jpg';
    }

    final extension = fileName.substring(dotIndex).toLowerCase();

    if (!_allowedExtensions.contains(extension)) {
      return '.jpg';
    }

    return extension;
  }

  Future<void> _deletePreviousManagedFile(
    String? previousPath,
  ) async {
    if (previousPath == null || previousPath.trim().isEmpty) {
      return;
    }

    try {
      final directory = await _getArtworkDirectory();

      final normalizedDirectory =
          '${directory.path}${Platform.pathSeparator}';

      final normalizedPreviousPath =
          File(previousPath).absolute.path;

      if (!normalizedPreviousPath.startsWith(
        normalizedDirectory,
      )) {
        return;
      }

      final previousFile = File(normalizedPreviousPath);

      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: previous Adhan artwork cleanup failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
