
import 'dart:io';

import 'mumin_adhan_audio_handler.dart';
import 'mumin_adhan_recording_library.dart';

/// Coordinates the Adhan recording library and background audio engine.
///
/// Keeps file management separate from playback implementation.
class MuminAdhanRecordingPlaybackService {
  MuminAdhanRecordingPlaybackService({
    required MuminAdhanAudioHandler audioHandler,
    MuminAdhanRecordingLibrary? recordingLibrary,
  })  : _audioHandler = audioHandler,
        _recordingLibrary =
            recordingLibrary ?? MuminAdhanRecordingLibrary();

  final MuminAdhanAudioHandler _audioHandler;
  final MuminAdhanRecordingLibrary _recordingLibrary;

  String? _activePath;
  bool _isDisposed = false;

  bool get isPlaying => _audioHandler.isPlaying;

  Duration get position => _audioHandler.position;

  Duration? get duration => _audioHandler.duration;

  Stream get playerStateStream =>
      _audioHandler.playerStateStream;

  Stream<Duration> get positionStream =>
      _audioHandler.positionStream;

  /// Import a recording without starting playback.
  Future<MuminAdhanRecording?> importRecording() async {
    _ensureNotDisposed();

    return _recordingLibrary.importRecording();
  }

  /// Import a recording and immediately play it as a preview.
  Future<MuminAdhanRecording?> importAndPlay() async {
    _ensureNotDisposed();

    final recording =
        await _recordingLibrary.importRecording();

    if (recording == null) return null;

    await playRecording(recording);

    return recording;
  }

  /// Return all recordings saved in the private library.
  Future<List<MuminAdhanRecording>> getRecordings() {
    _ensureNotDisposed();

    return _recordingLibrary.listRecordings();
  }

  /// Return the currently selected recording.
  Future<MuminAdhanRecording?> getSelectedRecording() {
    _ensureNotDisposed();

    return _recordingLibrary.getSelectedRecording();
  }

  /// Select and play a recording from the library.
  Future<void> playRecording(
    MuminAdhanRecording recording,
  ) async {
    _ensureNotDisposed();

    final file = File(recording.path);

    if (!await file.exists()) {
      throw FileSystemException(
        'The Adhan recording could not be found.',
        recording.path,
      );
    }

    await _recordingLibrary.selectRecording(
      recording.path,
    );

    await _audioHandler.playFile(
      recording.path,
      title: _displayName(recording.name),
      artist: 'Mumin Pro',
    );

    _activePath = recording.path;
  }

  /// Restore and play the previously selected recording.
  ///
  /// Returns false if the user has not selected a recording.
  Future<bool> playSelectedRecording() async {
    _ensureNotDisposed();

    final recording =
        await _recordingLibrary.getSelectedRecording();

    if (recording == null) {
      return false;
    }

    await playRecording(recording);

    return true;
  }

  /// Resume the currently loaded recording.
  Future<void> resume() async {
    _ensureNotDisposed();
    await _audioHandler.play();
  }

  /// Pause playback without clearing the selected recording.
  Future<void> pause() async {
    _ensureNotDisposed();
    await _audioHandler.pause();
  }

  /// Stop playback while preserving the selected recording.
  Future<void> stop() async {
    _ensureNotDisposed();
    await _audioHandler.stop();
    _activePath = null;
  }

  /// Seek within the currently playing recording.
  Future<void> seek(Duration position) async {
    _ensureNotDisposed();
    await _audioHandler.seek(position);
  }

  /// Delete a recording safely.
  ///
  /// If the deleted recording is currently playing, playback stops first.
  Future<void> deleteRecording(String path) async {
    _ensureNotDisposed();

    if (_activePath == path) {
      await _audioHandler.stop();
      _activePath = null;
    }

    await _recordingLibrary.deleteRecording(path);
  }

  /// Remove the selected recording preference.
  ///
  /// The recording file itself is retained in the library.
  Future<void> clearSelection() async {
    _ensureNotDisposed();

    if (_activePath != null) {
      await _audioHandler.stop();
      _activePath = null;
    }

    await _recordingLibrary.clearSelection();
  }

  String _displayName(String fileName) {
    final extensionIndex = fileName.lastIndexOf('.');

    final withoutExtension = extensionIndex > 0
        ? fileName.substring(0, extensionIndex)
        : fileName;

    final timestampSeparator =
        withoutExtension.indexOf('_');

    if (timestampSeparator > 0) {
      final prefix = withoutExtension.substring(
        0,
        timestampSeparator,
      );

      if (int.tryParse(prefix) != null) {
        return withoutExtension.substring(
          timestampSeparator + 1,
        );
      }
    }

    return withoutExtension;
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'MuminAdhanRecordingPlaybackService has been disposed.',
      );
    }
  }

  /// This service does not own the shared audio handler.
  /// The application root is responsible for disposing it.
  void dispose() {
    _isDisposed = true;
  }
}
