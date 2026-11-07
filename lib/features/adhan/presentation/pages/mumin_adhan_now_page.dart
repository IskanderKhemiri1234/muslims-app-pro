
import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/mumin_language_controller.dart';
import '../../data/models/mumin_media_asset_registry.dart';
import '../../data/services/mumin_adhan_asset_playback_service.dart';

class MuminAdhanNowPage extends StatefulWidget {
  const MuminAdhanNowPage({super.key});

  @override
  State<MuminAdhanNowPage> createState() => _MuminAdhanNowPageState();
}

class _MuminAdhanNowPageState extends State<MuminAdhanNowPage> {
  static const Color _emerald = Color(0xFF071C17);
  static const Color _deepEmerald = Color(0xFF063E31);
  static const Color _gold = Color(0xFFD8B66A);
  static const Color _ivory = Color(0xFFF4F0E6);

  static const List<Prayer> _prayers = [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  late MuminAdhanAssetPlaybackService _playback;
  late MuminLanguageController _languages;

  Prayer _selectedPrayer = Prayer.fajr;
  String? _selectedArtworkId;
  bool _busy = false;
  String? _error;

  StreamSubscription? _stateSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _playback = context.read<MuminAdhanAssetPlaybackService>();
    _languages = context.read<MuminLanguageController>();
  }

  String get _languageCode => _languages.languageCode;

  String _t(String ar, String en, String fr) {
    switch (_languageCode) {
      case 'en':
        return en;
      case 'fr':
        return fr;
      default:
        return ar;
    }
  }

  String _prayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return _t('الفجر', 'Fajr', 'Fajr');
      case Prayer.dhuhr:
        return _t('الظهر', 'Dhuhr', 'Dhuhr');
      case Prayer.asr:
        return _t('العصر', 'Asr', 'Asr');
      case Prayer.maghrib:
        return _t('المغرب', 'Maghrib', 'Maghrib');
      case Prayer.isha:
        return _t('العشاء', 'Isha', 'Isha');
      default:
        return prayer.name;
    }
  }

  MuminAdhanAsset get _selectedRecording {
    final id = 'doha_${_selectedPrayer.name}';

    return MuminMediaAssetRegistry.adhanById(id) ??
        MuminMediaAssetRegistry.adhanRecordings.first;
  }

  MuminMosqueArtwork? get _selectedArtwork {
    final artworks = MuminMediaAssetRegistry.mosqueArtwork;

    if (artworks.isEmpty) return null;

    for (final artwork in artworks) {
      if (artwork.id == _selectedArtworkId) {
        return artwork;
      }
    }

    return artworks.first;
  }

  Future<void> _play() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _playback.playById(
        _selectedRecording.id,
        languageCode: _languageCode,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _t(
          'تعذر تشغيل التسجيل. تحقق من إضافة ملف الصوت إلى أصول التطبيق.',
          'Could not play this recording. Check that the audio asset has been added.',
          'Lecture impossible. Vérifiez que le fichier audio est ajouté aux ressources.',
        );
      });

      debugPrint('Mumin Pro Adhan playback error: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_playback.isPlaying) {
        await _playback.pause();
      } else {
        await _playback.playById(
          _selectedRecording.id,
          languageCode: _languageCode,
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _t(
          'تعذر التحكم في التشغيل. تحقق من ملفات الصوت.',
          'Playback control failed. Check the audio assets.',
          'Le contrôle audio a échoué. Vérifiez les fichiers audio.',
        );
      });

      debugPrint('Mumin Pro Adhan control error: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _stop() async {
    try {
      await _playback.stop();

      if (mounted) {
        setState(() => _error = null);
      }
    } catch (error) {
      debugPrint('Mumin Pro Adhan stop error: $error');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    final seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final artwork = _selectedArtwork;
    final recording = _selectedRecording;

    return Scaffold(
      backgroundColor: _emerald,
      appBar: AppBar(
        backgroundColor: _emerald,
        foregroundColor: _ivory,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _t('الأذان الآن', 'Adhan Now', 'Adhan maintenant'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _buildArtwork(artwork),
            const SizedBox(height: 23),
            Text(
              _t(
                'لحظة سكينة',
                'A Moment of Serenity',
                'Un instant de sérénité',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _gold,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              _prayerName(_selectedPrayer),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ivory,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              recording.titleFor(_languageCode),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ivory.withValues(alpha: 0.68),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 25),
            _buildPrayerSelector(),
            const SizedBox(height: 17),
            _buildArtworkSelector(),
            const SizedBox(height: 23),
            _buildPlayer(),
            if (_error != null) ...[
              const SizedBox(height: 14),
              _buildError(),
            ],
            const SizedBox(height: 20),
            _buildTrustNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork(MuminMosqueArtwork? artwork) {
    return AspectRatio(
      aspectRatio: 1.18,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (artwork != null)
              Image.asset(
                artwork.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildArtworkFallback(),
              )
            else
              _buildArtworkFallback(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.12),
                    _emerald.withValues(alpha: 0.94),
                  ],
                  stops: const [0.0, 0.48, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: _glassIcon(Icons.mosque_rounded),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: _gold,
                    size: 19,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artwork?.titleFor(_languageCode) ??
                        _t(
                          'مساجد العالم الإسلامي',
                          'Mosques of the Muslim World',
                          'Mosquées du monde musulman',
                        ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ivory,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t(
                      'جمال معماري يرافق لحظة الأذان',
                      'Architecture accompanying the call to prayer',
                      'Une architecture au rythme de l’appel à la prière',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ivory.withValues(alpha: 0.76),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF17624D),
            Color(0xFF09271F),
            Color(0xFF03110D),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.mosque_rounded,
          color: _gold,
          size: 92,
        ),
      ),
    );
  }

  Widget _glassIcon(IconData icon) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _gold.withValues(alpha: 0.35),
        ),
      ),
      child: Icon(
        icon,
        color: _gold,
        size: 23,
      ),
    );
  }

  Widget _buildPrayerSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _deepEmerald,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: _gold.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: _gold,
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _t('اختر الصلاة', 'Choose prayer', 'Choisir la prière'),
              style: const TextStyle(
                color: _ivory,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<Prayer>(
              value: _selectedPrayer,
              dropdownColor: _deepEmerald,
              iconEnabledColor: _gold,
              style: const TextStyle(
                color: _ivory,
                fontWeight: FontWeight.w800,
              ),
              items: _prayers.map((prayer) {
                return DropdownMenuItem<Prayer>(
                  value: prayer,
                  child: Text(_prayerName(prayer)),
                );
              }).toList(),
              onChanged: (prayer) {
                if (prayer == null) return;

                setState(() {
                  _selectedPrayer = prayer;
                  _error = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkSelector() {
    final artworks = MuminMediaAssetRegistry.mosqueArtwork;

    if (artworks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(
            'اختر مشهد المسجد',
            'Choose mosque artwork',
            'Choisir une image de mosquée',
          ),
          style: const TextStyle(
            color: _ivory,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: artworks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 11),
            itemBuilder: (context, index) {
              final item = artworks[index];
              final selected = _selectedArtwork?.id == item.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedArtworkId = item.id;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 116,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: selected ? _gold : Colors.white24,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        item.assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildArtworkFallback(),
                      ),
                      if (selected)
                        Container(
                          color: _emerald.withValues(alpha: 0.28),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: _gold,
                            size: 27,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayer() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFF0B3026),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: _gold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          StreamBuilder<Duration>(
            stream: _playback.positionStream,
            initialData: _playback.position,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _playback.duration ?? Duration.zero;

              final maximum = duration.inMilliseconds > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1.0;

              final current = position.inMilliseconds
                  .toDouble()
                  .clamp(0.0, maximum);

              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _gold,
                      inactiveTrackColor: _ivory.withValues(alpha: 0.18),
                      thumbColor: _gold,
                      overlayColor: _gold.withValues(alpha: 0.14),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: current,
                      min: 0,
                      max: maximum,
                      onChanged: duration.inMilliseconds <= 0
                          ? null
                          : (value) {
                              _playback.seek(
                                Duration(
                                  milliseconds: value.round(),
                                ),
                              );
                            },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: _ivory,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: _ivory,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: _t('إيقاف', 'Stop', 'Arrêter'),
                onPressed: _stop,
                icon: const Icon(
                  Icons.stop_circle_outlined,
                  color: _ivory,
                  size: 31,
                ),
              ),
              const SizedBox(width: 22),
              StreamBuilder(
                stream: _playback.playerStateStream,
                builder: (context, snapshot) {
                  final playing = _playback.isPlaying;

                  return GestureDetector(
                    onTap: _busy ? null : _togglePlayback,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE8CC87),
                            Color(0xFFC59A48),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(alpha: 0.25),
                            blurRadius: 22,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _busy
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: _emerald,
                                ),
                              )
                            : Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: _emerald,
                                size: 39,
                              ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 22),
              IconButton(
                tooltip: _t('إعادة التشغيل', 'Play again', 'Relancer'),
                onPressed: _busy ? null : _play,
                icon: const Icon(
                  Icons.replay_rounded,
                  color: _ivory,
                  size: 29,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            _t(
              'تسجيل أذان الدوحة',
              'Doha Adhan recording',
              'Enregistrement de l’adhan de Doha',
            ),
            style: TextStyle(
              color: _ivory.withValues(alpha: 0.72),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustNote() {
    return Text(
      _t(
        'الصوت والصور يعملان دون إنترنت بعد تضمين ملفاتهما في التطبيق. لا يتم تشغيل الأذان تلقائياً من هذه الشاشة.',
        'Audio and images work offline once bundled in the app. This screen does not trigger automatic prayer-time playback.',
        'Le son et les images fonctionnent hors ligne une fois intégrés à l’application. Cet écran ne déclenche pas automatiquement l’adhan.',
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _ivory.withValues(alpha: 0.57),
        fontSize: 11,
        height: 1.6,
      ),
    );
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }
}
