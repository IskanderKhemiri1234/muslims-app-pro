
import 'package:adhan/adhan.dart';

import '../models/mumin_media_asset_registry.dart';
import 'mumin_adhan_audio_handler.dart';

/// Plays Adhan recordings bundled inside the application.
///
/// This service does not download files and does not own the shared
/// background audio handler.
class MuminAdhanAssetPlaybackService {
  MuminAdhanAssetPlaybackService({
    required MuminAdhanAudioHandler audioHandler,
  }) : _audioHandler = audioHandler;

  final MuminAdhanAudioHandler _audioHandler;

  bool _disposed = false;

  static const Map<Prayer, String> _defaultPrayerAssets = {
    Prayer.fajr: 'doha_fajr',
    Prayer.dhuhr: 'doha_dhuhr',
    Prayer.asr: 'doha_asr',
    Prayer.maghrib: 'doha_maghrib',
    Prayer.isha: 'doha_isha',
  };

  bool get isPlaying => _audioHandler.isPlaying;

  Duration get position => _audioHandler.position;

  Duration? get duration => _audioHandler.duration;

  Stream<Duration> get positionStream =>
      _audioHandler.positionStream;

  Stream get playerStateStream =>
      _audioHandler.playerStateStream;

  List<MuminAdhanAsset> get availableRecordings =>
      MuminMediaAssetRegistry.adhanRecordings;

  MuminAdhanAsset? getAsset(String id) =>
      MuminMediaAssetRegistry.adhanById(id);

  /// Plays a bundled recording by its registry identifier.
  Future<void> playById(
    String id, {
    required String languageCode,
  }) async {
    _ensureActive();

    final asset = getAsset(id);

    if (asset == null) {
      throw ArgumentError.value(
        id,
        'id',
        'Unknown bundled Adhan recording.',
      );
    }

    await _audioHandler.playAsset(
      asset.assetPath,
      title: asset.titleFor(languageCode),
      artist: 'Mumin Pro',
    );
  }

  /// Plays the bundled default recording for a daily prayer.
  Future<void> playForPrayer(
    Prayer prayer, {
    required String languageCode,
  }) async {
    _ensureActive();

    final assetId = _defaultPrayerAssets[prayer];

    if (assetId == null) {
      throw ArgumentError.value(
        prayer,
        'prayer',
        'Only the five daily prayers have bundled Adhan recordings.',
      );
    }

    await playById(
      assetId,
      languageCode: languageCode,
    );
  }

  Future<void> pause() async {
    _ensureActive();
    await _audioHandler.pause();
  }

  Future<void> resume() async {
    _ensureActive();
    await _audioHandler.play();
  }

  Future<void> stop() async {
    _ensureActive();
    await _audioHandler.stop();
  }

  Future<void> seek(Duration position) async {
    _ensureActive();
    await _audioHandler.seek(position);
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError(
        'MuminAdhanAssetPlaybackService has been disposed.',
      );
    }
  }

  /// The shared audio handler is owned by the application root.
  void dispose() {
    _disposed = true;
  }
}
