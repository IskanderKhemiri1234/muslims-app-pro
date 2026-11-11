import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/mumin_language_controller.dart';
import '../../data/services/mumin_adhan_audio_handler.dart';

/// Full-screen prayer-time experience launched by an Android Adhan alert.
///
/// The short takbeer and full Adhan are serialized through the one shared
/// audio handler, so two recordings can never overlap.
class MuminAdhanExperiencePage extends StatefulWidget {
  const MuminAdhanExperiencePage({
    required this.prayer,
    this.previewMode = false,
    this.audioHandlerOverride,
    super.key,
  });

  final Prayer prayer;
  final bool previewMode;
  final MuminAdhanAudioHandler? audioHandlerOverride;

  @override
  State<MuminAdhanExperiencePage> createState() =>
      _MuminAdhanExperiencePageState();
}

class _MuminAdhanExperiencePageState
    extends State<MuminAdhanExperiencePage> {
  static const String _shortAdhanAsset =
      'assets/audio/notifications/adhan_takbeer_twice.mp3';
  static const String _fullAdhanAsset =
      'assets/audio/adhan/adhan_full.mp3';

  static const Color _emerald = Color(0xFF061C17);
  static const Color _gold = Color(0xFFD8B66A);
  static const Color _ivory = Color(0xFFF4F0E6);

  late MuminAdhanAudioHandler _audioHandler;
  late MuminLanguageController _languages;

  bool _audioHandlerReady = false;
  bool _shortAudioEnabled = true;
  bool _fullAudioEnabled = false;
  String _audioMode = 'short';
  String? _selectedBackgroundPath;
  bool _shortAdhanStarted = false;
  bool _shortAdhanScheduled = false;
  bool _fullAdhanStarted = false;
  bool _isClosing = false;
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioHandler = widget.audioHandlerOverride ?? context.read<MuminAdhanAudioHandler>();
    _languages = context.read<MuminLanguageController>();
    _audioHandlerReady = true;

    if (!_shortAdhanScheduled) {
      _shortAdhanScheduled = true;
      unawaited(_loadMediaPreferencesAndStart());
    }
  }

  Future<void> _loadMediaPreferencesAndStart() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedMode = preferences.getString('mumin_adhan_audio_mode_v1');
      final legacyShort =
          preferences.getBool('mumin_adhan_short_audio_enabled_v1') ?? true;
      final legacyFull =
          preferences.getBool('mumin_adhan_full_audio_enabled_v1') ?? false;
      _audioMode = savedMode == 'full' ||
              (savedMode == null && legacyFull && !legacyShort)
          ? 'full'
          : 'short';
      _shortAudioEnabled = _audioMode == 'short';
      _fullAudioEnabled = _audioMode == 'full';
      _selectedBackgroundPath =
          preferences.getString('mumin_adhan_selected_mosque_image_v1');

      if (savedMode == null) {
        await preferences.setString('mumin_adhan_audio_mode_v1', _audioMode);
        await preferences.setBool(
          'mumin_adhan_short_audio_enabled_v1',
          _shortAudioEnabled,
        );
        await preferences.setBool(
          'mumin_adhan_full_audio_enabled_v1',
          _fullAudioEnabled,
        );
      }

      if (mounted) setState(() {});
      // The preview is deliberately silent. Each recording has its own
      // dedicated test action in Adhan settings.
      if (!widget.previewMode && _shortAudioEnabled && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_startShortAdhan());
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: Adhan media preferences could not be loaded: $error');
      debugPrintStack(stackTrace: stackTrace);
      // Keep the safe single-recording default; never start both recordings.
      _audioMode = 'short';
      _shortAudioEnabled = true;
      _fullAudioEnabled = false;
      if (mounted) setState(() {});
      if (!widget.previewMode && mounted) {
        unawaited(_startShortAdhan());
      }
    }
  }

  String get _languageCode => _languages.languageCode;

  String _text(String ar, String en, String fr) {
    switch (_languageCode) {
      case 'en':
        return en;
      case 'fr':
        return fr;
      default:
        return ar;
    }
  }

  String get _prayerName {
    switch (widget.prayer) {
      case Prayer.fajr:
        return _text('الفجر', 'Fajr', 'Fajr');
      case Prayer.dhuhr:
        return _text('الظهر', 'Dhuhr', 'Dhuhr');
      case Prayer.asr:
        return _text('العصر', 'Asr', 'Asr');
      case Prayer.maghrib:
        return _text('المغرب', 'Maghrib', 'Maghrib');
      case Prayer.isha:
        return _text('العشاء', 'Isha', 'Isha');
      default:
        return widget.prayer.name;
    }
  }

  Future<void> _startShortAdhan() async {
    if (!mounted || !_audioHandlerReady || _shortAdhanStarted || !_shortAudioEnabled || _audioMode != 'short') return;
    _shortAdhanStarted = true;

    try {
      await _audioHandler.playAsset(
        _shortAdhanAsset,
        title: _text(
          'الله أكبر مرتين',
          'Takbeer twice',
          'Takbir deux fois',
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: short Adhan playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _continueWithFullAdhan() async {
    if (_fullAdhanStarted || _isClosing || !_audioHandlerReady || !_fullAudioEnabled || _audioMode != 'full') return;

    setState(() {
      _fullAdhanStarted = true;
      _dragDistance = 110;
    });

    try {
      // Stop first, then load and play the complete recording from position 0.
      await _audioHandler.stop();
      if (!mounted || _isClosing) return;

      await _audioHandler.playAsset(
        _fullAdhanAsset,
        title: _text(
          'الأذان الكامل',
          'Complete Adhan',
          'Adhan complet',
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: full Adhan playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;

      setState(() {
        _fullAdhanStarted = false;
        _dragDistance = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'تعذر تشغيل الأذان الكامل. تحقق من ملف التسجيل.',
              'The complete Adhan could not be played. Check the audio file.',
              'Impossible de lire l’Adhan complet. Vérifiez le fichier audio.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _closeExperience() async {
    if (_isClosing) return;
    _isClosing = true;

    if (_audioHandlerReady) {
      try {
        await _audioHandler.stop();
      } catch (error, stackTrace) {
        debugPrint('Mumin Pro: Adhan stop on close failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onDropPanStart(DragStartDetails details) {
    if (_fullAdhanStarted || _isClosing) return;
    setState(() => _dragDistance = 0);
  }

  void _onDropPanUpdate(DragUpdateDetails details) {
    if (_fullAdhanStarted || _isClosing) return;

    final nextDistance =
        (_dragDistance + details.delta.distance).clamp(0.0, 110.0).toDouble();

    setState(() => _dragDistance = nextDistance);

    if (nextDistance >= 110) {
      unawaited(_continueWithFullAdhan());
    }
  }

  void _onDropPanEnd(DragEndDetails details) {
    if (_fullAdhanStarted || _isClosing) return;

    setState(() => _dragDistance = 0);
  }

  @override
  void dispose() {
    if (_audioHandlerReady && !_isClosing) {
      unawaited(_audioHandler.stop());
    }
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cacheWidth =
        (size.width * MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(720, 1440)
            .toInt();

    return Scaffold(
      backgroundColor: _emerald,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackgroundImage(cacheWidth),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xA6000806),
                  Color(0x26000806),
                  Color(0xA900100C),
                  Color(0xF2061C17),
                ],
                stops: [0, 0.32, 0.68, 1],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 14,
                  child: _buildCloseButton(),
                ),
                Positioned(
                  top: size.height * 0.19,
                  left: 24,
                  right: 24,
                  child: _buildPrayerHeading(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 28,
                  child: _buildWaterDropControl(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage(int cacheWidth) {
    final path = _selectedBackgroundPath;
    if (path == null || path.isEmpty) {
      return Image.asset(
        'assets/images/mosques/mumin_mosque.jpg',
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const ColoredBox(color: _emerald),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const ColoredBox(color: _emerald),
      );
    }
    final file = File(path);
    if (!file.existsSync()) {
      return Image.asset(
        'assets/images/mosques/mumin_mosque.jpg',
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        filterQuality: FilterQuality.medium,
      );
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => const ColoredBox(color: _emerald),
    );
  }

  Widget _buildCloseButton() {
    return Semantics(
      button: true,
      label: _text('إغلاق واجهة الأذان', 'Close Adhan screen', 'Fermer l’écran Adhan'),
      child: Material(
        color: Colors.black.withValues(alpha: 0.22),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _closeExperience,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.42),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.94),
              size: 25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerHeading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.previewMode
              ? _text('مُعَايَنَةُ وَاجِهَةِ الأَذَان', 'ADHAN SCREEN PREVIEW', 'APERÇU DE L’ÉCRAN ADHAN')
              : _text('حَانَ وَقْتُ الصَّلَاة', 'IT IS TIME TO PRAY', 'C’EST L’HEURE DE LA PRIÈRE'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _gold,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _prayerName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ivory,
            fontSize: 39,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 18),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          _text('الله أكبر • الله أكبر', 'Allahu Akbar • Allahu Akbar', 'Allahou Akbar • Allahou Akbar'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ivory.withValues(alpha: 0.92),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaterDropControl() {
    final progress = (_dragDistance / 110).clamp(0.0, 1.0).toDouble();
    final canContinue = _fullAudioEnabled && _audioMode == 'full';

    final instruction = _fullAdhanStarted
        ? _text(
            'الأذان الكامل قيد التشغيل',
            'Complete Adhan is playing',
            'L’Adhan complet est en cours',
          )
        : !canContinue
            ? _text(
                'اختر الأذان الكامل من إعدادات الصوت لاستخدام هذه الدائرة',
                'Select Full Adhan in audio settings to use this control',
                'Choisissez Adhan complet dans les réglages audio',
              )
            : _text(
                'اسحب دائرة البصمة لمواصلة الأذان الكامل',
                'Swipe the fingerprint circle to continue the full Adhan',
                'Faites glisser le cercle empreinte pour continuer l’Adhan',
              );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: canContinue ? _onDropPanStart : null,
          onPanUpdate: canContinue ? _onDropPanUpdate : null,
          onPanEnd: canContinue ? _onDropPanEnd : null,
          child: Semantics(
            button: canContinue,
            label: instruction,
            child: SizedBox(
              width: 164,
              height: 164,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(164, 164),
                    painter: _FingerprintRingPainter(progress: progress),
                  ),
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 48,
                    color: Colors.white.withValues(
                      alpha: canContinue ? 0.94 : 0.42,
                    ),
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 12),
                    ],
                  ),
                  if (_fullAdhanStarted)
                    const Positioned(
                      bottom: 31,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 17,
                        color: Color(0xFFD8B66A),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: _fullAdhanStarted ? 0.72 : 1,
          duration: const Duration(milliseconds: 180),
          child: Text(
            instruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ivory.withValues(alpha: 0.92),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.15,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FingerprintRingPainter extends CustomPainter {
  const _FingerprintRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Soft concentric water-glass ripples, similar to a phone fingerprint
    // unlock target. All effects are vector-drawn and inexpensive to render.
    for (var ring = 3; ring >= 0; ring--) {
      final radius = 37 + ring * 10 + progress * 8;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring == 0 ? 1.8 : 0.85
        ..color = Colors.white.withValues(
          alpha: (0.34 - ring * 0.055) + progress * 0.12,
        );
      canvas.drawCircle(center, radius, ringPaint);
    }

    final diskRect = Rect.fromCircle(center: center, radius: 37);
    final diskPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.38, -0.48),
        radius: 1.1,
        colors: [
          Color(0x66FFFFFF),
          Color(0x2AB8F0E2),
          Color(0x1677CDBB),
          Color(0x0877CDBB),
        ],
        stops: [0, 0.36, 0.76, 1],
      ).createShader(diskRect);
    canvas.drawCircle(center, 37, diskPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xF2FFFFFF),
          Color(0x77B9F4E7),
          Color(0xC8D8B66A),
        ],
      ).createShader(diskRect);
    canvas.drawCircle(center, 37, borderPaint);

    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.1
      ..color = Colors.white.withValues(alpha: 0.78);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 31),
      -math.pi * 0.88,
      math.pi * 0.55,
      false,
      highlight,
    );

    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.4
        ..color = const Color(0xFFE8CE91);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 49),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FingerprintRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
