
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mumin_adhan_recording_library.dart';

/// Stores an independent Adhan recording selection for each prayer.
///
/// All selected files must belong to the private Mumin Pro library.
/// The previous global recording selection remains untouched.
class MuminAdhanPrayerRecordingPreferences {
  MuminAdhanPrayerRecordingPreferences({
    MuminAdhanRecordingLibrary? library,
  }) : _library = library ?? MuminAdhanRecordingLibrary();

  static const String _keyPrefix =
      'mumin_adhan_recording_for_prayer_';

  final MuminAdhanRecordingLibrary _library;

  static const List<Prayer> supportedPrayers = [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  String _key(Prayer prayer) {
    _validatePrayer(prayer);
    return '$_keyPrefix${prayer.name}';
  }

  /// Assigns a recording to one prayer only.
  Future<void> selectForPrayer(
    Prayer prayer,
    MuminAdhanRecording recording,
  ) async {
    final recordings = await _library.listRecordings();

    final exists = recordings.any(
      (item) => item.path == recording.path,
    );

    if (!exists) {
      throw ArgumentError(
        'The selected recording is not in the Mumin Pro library.',
      );
    }

    final preferences = await SharedPreferences.getInstance();

    final saved = await preferences.setString(
      _key(prayer),
      recording.path,
    );

    if (!saved) {
      throw StateError(
        'Could not save the recording selection for ${prayer.name}.',
      );
    }
  }

  /// Returns the recording assigned to a prayer.
  ///
  /// Returns null when no valid independent recording exists.
  /// When fallbackToGeneral is true, the previous global selection
  /// is returned without changing the independent preference.
  Future<MuminAdhanRecording?> getForPrayer(
    Prayer prayer, {
    bool fallbackToGeneral = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    final selectedPath = preferences.getString(_key(prayer));

    if (selectedPath != null && selectedPath.isNotEmpty) {
      final recordings = await _library.listRecordings();

      for (final recording in recordings) {
        if (recording.path == selectedPath) {
          return recording;
        }
      }

      // Remove stale selections if a file was deleted externally.
      await preferences.remove(_key(prayer));
    }

    if (!fallbackToGeneral) return null;

    return _library.getSelectedRecording();
  }

  /// Returns all independent prayer selections.
  ///
  /// Missing selections are omitted from the returned map.
  Future<Map<Prayer, MuminAdhanRecording>> getAll() async {
    final result = <Prayer, MuminAdhanRecording>{};

    for (final prayer in supportedPrayers) {
      final recording = await getForPrayer(prayer);

      if (recording != null) {
        result[prayer] = recording;
      }
    }

    return Map<Prayer, MuminAdhanRecording>.unmodifiable(
      result,
    );
  }

  /// Removes the independent selection for one prayer.
  ///
  /// It does not delete the audio file or affect other prayers.
  Future<void> clearPrayer(Prayer prayer) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_key(prayer));
  }

  /// Removes all independent prayer selections.
  ///
  /// Audio files and the legacy global selection are preserved.
  Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();

    for (final prayer in supportedPrayers) {
      await preferences.remove(_key(prayer));
    }
  }

  void _validatePrayer(Prayer prayer) {
    if (!supportedPrayers.contains(prayer)) {
      throw ArgumentError.value(
        prayer,
        'prayer',
        'Only the five daily prayers support independent recordings.',
      );
    }
  }
}
