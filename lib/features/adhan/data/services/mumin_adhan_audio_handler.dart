
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Background audio engine dedicated to Mumin Pro Adhan playback.
///
/// Responsibilities:
/// - Play bundled Adhan audio assets.
/// - Play user-selected local audio files.
/// - Continue playback while the app is in the background.
/// - Synchronize playback state with Android media controls.
/// - Expose a single playback handler to the application UI.
///
/// This class does not download audio or assume that an audio recording
/// is already bundled with the application.
class MuminAdhanAudioHandler extends BaseAudioHandler
    with SeekHandler {
  MuminAdhanAudioHandler() {
    _playbackSubscription = _player.playbackEventStream.listen(
      _broadcastPlaybackState,
      onError: (Object error, StackTrace stackTrace) {
        _broadcastError(error);
      },
    );

    _player.playerStateStream.listen((_) {
      _broadcastPlaybackState(_player.playbackEvent);
    });
  }

  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlaybackEvent>? _playbackSubscription;

  bool _hasSource = false;
  bool _isDisposed = false;

  /// Current audio engine state.
  bool get isPlaying => _player.playing;

  /// Current playback position.
  Duration get position => _player.position;

  /// Total audio duration, when available.
  Duration? get duration => _player.duration;

  /// Playback state stream for the Adhan interface.
  Stream<PlayerState> get playerStateStream =>
      _player.playerStateStream;

  /// Playback position stream for progress indicators.
  Stream<Duration> get positionStream =>
      _player.positionStream;

  /// Load and play an audio file bundled in the application.
  ///
  /// Example:
  /// await handler.playAsset(
  ///   'assets/audio/adhan/fajr.mp3',
  ///   title: 'Fajr Adhan',
  /// );
  Future<void> playAsset(
    String assetPath, {
    required String title,
    String artist = 'Mumin Pro',
  }) async {
    _ensureNotDisposed();
    _validateSource(assetPath);

    final item = _createMediaItem(
      id: 'asset:$assetPath',
      title: title,
      artist: artist,
    );

    await _loadAndPlay(
      AudioSource.asset(assetPath),
      item,
    );
  }

  /// Load and play an audio file stored locally on the device.
  ///
  /// This supports audio selected by the user through the app's
  /// media picker. The caller is responsible for providing a valid
  /// local file path.
  Future<void> playFile(
    String filePath, {
    required String title,
    String artist = 'Mumin Pro',
  }) async {
    _ensureNotDisposed();
    _validateSource(filePath);

    final item = _createMediaItem(
      id: 'file:$filePath',
      title: title,
      artist: artist,
    );

    await _loadAndPlay(
      AudioSource.file(filePath),
      item,
    );
  }

  Future<void> _loadAndPlay(
    AudioSource source,
    MediaItem item,
  ) async {
    await _player.stop();

    mediaItem.add(item);
    queue.add(<MediaItem>[item]);

    _hasSource = false;

    await _player.setAudioSource(source);

    _hasSource = true;

    _broadcastPlaybackState(_player.playbackEvent);

    await _player.play();
  }

  @override
  Future<void> play() async {
    _ensureNotDisposed();

    if (!_hasSource) {
      throw StateError(
        'No Adhan audio source has been loaded.',
      );
    }

    await _player.play();
  }

  @override
  Future<void> pause() async {
    _ensureNotDisposed();
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    if (_isDisposed) return;

    await _player.stop();

    playbackState.add(
      PlaybackState(
        controls: const <MediaControl>[
          MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const <MediaAction>{
          MediaAction.seek,
        },
        androidCompactActionIndices: const <int>[0, 1],
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
      ),
    );

    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    _ensureNotDisposed();

    if (!_hasSource) return;

    await _player.seek(position);
  }

  /// Update the media notification and lock-screen playback state.
  void _broadcastPlaybackState(PlaybackEvent event) {
    if (_isDisposed) return;

    final processingState = switch (_player.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };

    playbackState.add(
      PlaybackState(
        controls: <MediaControl>[
          if (_player.playing)
            MediaControl.pause
          else
            MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const <MediaAction>{
          MediaAction.seek,
        },
        androidCompactActionIndices: const <int>[0, 1],
        processingState: processingState,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  void _broadcastError(Object error) {
    if (_isDisposed) return;

    customEvent.add(
      <String, String>{
        'type': 'audio_error',
        'message': error.toString(),
      },
    );
  }

  MediaItem _createMediaItem({
    required String id,
    required String title,
    required String artist,
  }) {
    return MediaItem(
      id: id,
      title: title,
      artist: artist,
      album: 'Mumin Pro Adhan',
    );
  }

  void _validateSource(String source) {
    if (source.trim().isEmpty) {
      throw ArgumentError.value(
        source,
        'source',
        'Audio source cannot be empty.',
      );
    }
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'MuminAdhanAudioHandler has already been disposed.',
      );
    }
  }

  /// Release audio resources when the application shuts down.
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;

    await _playbackSubscription?.cancel();
    await _player.dispose();
  }
}
