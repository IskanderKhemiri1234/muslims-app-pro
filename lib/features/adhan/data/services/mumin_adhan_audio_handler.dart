
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Central background audio engine for Mumin Pro Adhan.
///
/// Owns one AudioPlayer shared by bundled and imported recordings.
class MuminAdhanAudioHandler extends BaseAudioHandler
    with SeekHandler {
  MuminAdhanAudioHandler() {
    _playbackSubscription = _player.playbackEventStream.listen(
      _broadcastPlaybackState,
      onError: (Object error, StackTrace stackTrace) {
        _broadcastError(error);
      },
    );

    _playerStateSubscription = _player.playerStateStream.listen(
      (_) {
        _broadcastPlaybackState(_player.playbackEvent);
      },
      onError: (Object error, StackTrace stackTrace) {
        _broadcastError(error);
      },
    );
  }

  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlaybackEvent>? _playbackSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  bool _hasSource = false;
  bool _isDisposed = false;

  bool get isPlaying => _player.playing;

  bool get hasSource => _hasSource;

  bool get isPaused =>
      _hasSource &&
      !_player.playing &&
      _player.processingState == ProcessingState.ready;

  Duration get position => _player.position;

  Duration? get duration => _player.duration;

  Stream<PlayerState> get playerStateStream =>
      _player.playerStateStream;

  Stream<Duration> get positionStream =>
      _player.positionStream;

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
    _ensureNotDisposed();

    _hasSource = false;

    await _player.stop();
    await _player.setAudioSource(source);

    _hasSource = true;

    mediaItem.add(item);
    queue.add(<MediaItem>[item]);

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

    _hasSource = false;

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

  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;

    await _playbackSubscription?.cancel();
    await _playerStateSubscription?.cancel();

    _playbackSubscription = null;
    _playerStateSubscription = null;

    await _player.dispose();
  }
}
