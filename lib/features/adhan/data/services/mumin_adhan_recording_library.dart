
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A locally stored Adhan recording.
class MuminAdhanRecording {
  const MuminAdhanRecording({
    required this.name,
    required this.path,
    required this.sizeInBytes,
  });

  final String name;
  final String path;
  final int sizeInBytes;

  String get extension {
    final index = name.lastIndexOf('.');
    if (index < 0) return '';
    return name.substring(index + 1).toLowerCase();
  }

  String get sizeLabel {
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(0)} KB';
    }

    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Local Adhan recording library.
///
/// Supports:
/// - Importing audio files from the device.
/// - Keeping multiple recordings in private app storage.
/// - Selecting the active recording.
/// - Listing saved recordings.
/// - Removing recordings safely.
///
/// No audio is uploaded to an external server.
class MuminAdhanRecordingLibrary {
  MuminAdhanRecordingLibrary();

  static const String _directoryName = 'adhan_recordings';

  static const String _selectedRecordingKey =
      'mumin_adhan_selected_recording';

  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  static const List<String> supportedExtensions = [
    'mp3',
    'm4a',
    'aac',
    'wav',
    'ogg',
    'flac',
  ];

  /// Opens the system picker and imports the selected recording.
  ///
  /// Returns null if the user cancels the picker.
  Future<MuminAdhanRecording?> importRecording() async {
    final PlatformFile? selectedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
    );

    if (selectedFile == null) {
      return null;
    }

    final extension = _extensionOf(selectedFile.name);

    if (!supportedExtensions.contains(extension)) {
      throw FormatException(
        'Unsupported audio format: $extension',
      );
    }

    final fileLength =
        selectedFile.lengthSync() ?? await selectedFile.length();

    if (fileLength == null || fileLength <= 0) {
      throw const FormatException(
        'The selected audio file is empty or unreadable.',
      );
    }

    if (fileLength > maxFileSizeBytes) {
      throw const FormatException(
        'The audio file exceeds the 50 MB limit.',
      );
    }

    final directory = await _getLibraryDirectory();

    final safeName = _safeFileName(selectedFile.name);
    final uniqueName =
        '${DateTime.now().microsecondsSinceEpoch}_$safeName';

    final destination = File(
      '${directory.path}${Platform.pathSeparator}$uniqueName',
    );

    try {
      final sourcePath = selectedFile.path;

      if (sourcePath != null && sourcePath.isNotEmpty) {
        await File(sourcePath).copy(destination.path);
      } else {
        final bytes = await selectedFile.readAsBytes();

        if (bytes.isEmpty) {
          throw const FormatException(
            'The selected audio file contains no data.',
          );
        }

        if (bytes.length > maxFileSizeBytes) {
          throw const FormatException(
            'The audio file exceeds the 50 MB limit.',
          );
        }

        await destination.writeAsBytes(
          bytes,
          flush: true,
        );
      }

      final savedLength = await destination.length();

      if (savedLength != fileLength) {
        throw const FileSystemException(
          'The imported recording failed its size verification.',
        );
      }

      final recording = MuminAdhanRecording(
        name: uniqueName,
        path: destination.path,
        sizeInBytes: savedLength,
      );

      await selectRecording(recording.path);

      return recording;
    } catch (_) {
      if (await destination.exists()) {
        await destination.delete();
      }

      rethrow;
    }
  }

  /// Returns all recordings stored in the application library.
  Future<List<MuminAdhanRecording>> listRecordings() async {
    final directory = await _getLibraryDirectory();

    final recordings = <MuminAdhanRecording>[];

    await for (final entity in directory.list(
      followLinks: false,
    )) {
      if (entity is! File) continue;

      final extension = _extensionOf(entity.path);

      if (!supportedExtensions.contains(extension)) {
        continue;
      }

      try {
        final length = await entity.length();

        if (length <= 0) continue;

        recordings.add(
          MuminAdhanRecording(
            name: entity.uri.pathSegments.last,
            path: entity.path,
            sizeInBytes: length,
          ),
        );
      } on FileSystemException {
        // Ignore files that are no longer accessible.
      }
    }

    recordings.sort(
      (a, b) => a.name.compareTo(b.name),
    );

    return List.unmodifiable(recordings);
  }

  /// Returns the currently selected recording, if it exists.
  Future<MuminAdhanRecording?> getSelectedRecording() async {
    final preferences = await SharedPreferences.getInstance();

    final selectedPath = preferences.getString(
      _selectedRecordingKey,
    );

    if (selectedPath == null || selectedPath.isEmpty) {
      return null;
    }

    final file = File(selectedPath);

    if (!await _isManagedFile(file)) {
      await preferences.remove(_selectedRecordingKey);
      return null;
    }

    try {
      if (!await file.exists()) {
        await preferences.remove(_selectedRecordingKey);
        return null;
      }

      final length = await file.length();

      if (length <= 0) {
        await preferences.remove(_selectedRecordingKey);
        return null;
      }

      return MuminAdhanRecording(
        name: file.uri.pathSegments.last,
        path: file.path,
        sizeInBytes: length,
      );
    } on FileSystemException {
      return null;
    }
  }

  /// Selects a recording already stored in the private library.
  Future<void> selectRecording(String path) async {
    final file = File(path);

    if (!await _isManagedFile(file)) {
      throw ArgumentError(
        'The recording does not belong to the Mumin Pro library.',
      );
    }

    if (!await file.exists()) {
      throw FileSystemException(
        'The selected recording does not exist.',
        path,
      );
    }

    final preferences = await SharedPreferences.getInstance();

    final saved = await preferences.setString(
      _selectedRecordingKey,
      file.path,
    );

    if (!saved) {
      throw StateError(
        'Could not save the selected Adhan recording.',
      );
    }
  }

  /// Deletes a recording from the private library.
  ///
  /// If it was selected, the active selection is cleared.
  Future<void> deleteRecording(String path) async {
    final file = File(path);

    if (!await _isManagedFile(file)) {
      throw ArgumentError(
        'Cannot delete a file outside the Adhan library.',
      );
    }

    final preferences = await SharedPreferences.getInstance();

    final selectedPath = preferences.getString(
      _selectedRecordingKey,
    );

    if (selectedPath == file.path) {
      await preferences.remove(_selectedRecordingKey);
    }

    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Clears the selected recording without deleting library files.
  Future<void> clearSelection() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_selectedRecordingKey);
  }

  Future<Directory> _getLibraryDirectory() async {
    final documents = await getApplicationDocumentsDirectory();

    final directory = Directory(
      '${documents.path}'
      '${Platform.pathSeparator}'
      '$_directoryName',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<bool> _isManagedFile(File file) async {
    final directory = await _getLibraryDirectory();

    final managedPrefix =
        '${directory.absolute.path}${Platform.pathSeparator}';

    final absolutePath = file.absolute.path;

    return absolutePath.startsWith(managedPrefix);
  }

  String _extensionOf(String fileName) {
    final index = fileName.lastIndexOf('.');

    if (index < 0) return '';

    return fileName.substring(index + 1).toLowerCase();
  }

  String _safeFileName(String originalName) {
    final extension = _extensionOf(originalName);

    final nameWithoutExtension = originalName.contains('.')
        ? originalName.substring(
            0,
            originalName.lastIndexOf('.'),
          )
        : originalName;

    final safeName = nameWithoutExtension
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    final normalizedName =
        safeName.isEmpty ? 'adhan_recording' : safeName;

    return '$normalizedName.$extension';
  }
}
