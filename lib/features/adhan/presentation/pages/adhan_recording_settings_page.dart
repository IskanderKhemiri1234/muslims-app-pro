
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/mumin_adhan_recording_library.dart';
import '../../data/services/mumin_adhan_recording_playback_service.dart';
import '../../data/services/mumin_adhan_prayer_recording_preferences.dart';

class AdhanRecordingSettingsPage extends StatefulWidget {
  const AdhanRecordingSettingsPage({super.key});

  @override
  State<AdhanRecordingSettingsPage> createState() =>
      _AdhanRecordingSettingsPageState();
}

class _AdhanRecordingSettingsPageState
    extends State<AdhanRecordingSettingsPage> {
  late final MuminAdhanPrayerRecordingPreferences _preferences;
  late final MuminAdhanRecordingPlaybackService _playback;

  List<MuminAdhanRecording> _recordings = [];
  final Map<Prayer, String?> _selectedPaths = {};

  bool _loading = true;
  bool _busy = false;
  String? _error;

  String get _languageCode =>
      Localizations.localeOf(context).languageCode;

  bool get _isArabic => _languageCode == 'ar';
  bool get _isFrench => _languageCode == 'fr';

  String _t(String ar, String en, String fr) {
    if (_isArabic) return ar;
    if (_isFrench) return fr;
    return en;
  }

  @override
  void initState() {
    super.initState();

    _preferences =
        context.read<MuminAdhanPrayerRecordingPreferences>();
    _playback =
        context.read<MuminAdhanRecordingPlaybackService>();

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final recordings = await _playback.getRecordings();
      final selections = await _preferences.getAll();

      if (!mounted) return;

      setState(() {
        _recordings = recordings;

        for (final prayer
            in MuminAdhanPrayerRecordingPreferences.supportedPrayers) {
          _selectedPaths[prayer] = selections[prayer]?.path;
        }

        _loading = false;
        _error = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Adhan recording settings load failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _t(
          'تعذر تحميل إعدادات التسجيلات.',
          'Could not load recording settings.',
          'Impossible de charger les paramètres des enregistrements.',
        );
      });
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
        return _t('العشاء', 'Isha', 'Icha');
      default:
        return prayer.name;
    }
  }

  Future<void> _selectRecording(
    Prayer prayer,
    String? path,
  ) async {
    if (_busy) return;

    if (path == null) {
      await _clearPrayer(prayer);
      return;
    }

    final recording = _recordings.cast<MuminAdhanRecording?>().firstWhere(
          (item) => item?.path == path,
          orElse: () => null,
        );

    if (recording == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _preferences.selectForPrayer(prayer, recording);

      if (!mounted) return;

      setState(() {
        _selectedPaths[prayer] = recording.path;
      });

      _showMessage(
        _t(
          'تم حفظ صوت ${_prayerName(prayer)}.',
          '${_prayerName(prayer)} recording saved.',
          'Son de ${_prayerName(prayer)} enregistré.',
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Adhan prayer recording selection failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _error = _t(
            'تعذر حفظ اختيار الصوت.',
            'Could not save this recording selection.',
            'Impossible d’enregistrer ce choix audio.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _clearPrayer(Prayer prayer) async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _preferences.clearPrayer(prayer);

      if (!mounted) return;

      setState(() {
        _selectedPaths[prayer] = null;
      });

      _showMessage(
        _t(
          'سيُستخدم الصوت العام لهذه الصلاة.',
          'The general recording will be used for this prayer.',
          'L’enregistrement général sera utilisé pour cette prière.',
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Adhan prayer recording reset failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _error = _t(
            'تعذر إعادة ضبط اختيار الصلاة.',
            'Could not reset this prayer selection.',
            'Impossible de réinitialiser ce choix.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _previewRecording(String path) async {
    if (_busy) return;

    final recording = _recordings.cast<MuminAdhanRecording?>().firstWhere(
          (item) => item?.path == path,
          orElse: () => null,
        );

    if (recording == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _playback.playRecording(recording);
    } catch (error, stackTrace) {
      debugPrint('Adhan recording preview failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _error = _t(
            'تعذر تشغيل معاينة هذا التسجيل.',
            'Could not preview this recording.',
            'Impossible de préécouter cet enregistrement.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _stopPreview() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await _playback.stop();
    } catch (error, stackTrace) {
      debugPrint('Adhan preview stop failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _buildPrayerCard(Prayer prayer) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedPath = _selectedPaths[prayer];

    final selectedRecording = _recordings.cast<MuminAdhanRecording?>().firstWhere(
          (item) => item?.path == selectedPath,
          orElse: () => null,
        );

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF075B46).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.mosque_rounded,
                    color: Color(0xFFD8B66A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _prayerName(prayer),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (selectedRecording != null)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF0B8A62),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
            initialValue: selectedPath,
            isExpanded: true,
              decoration: InputDecoration(
                labelText: _t(
                  'التسجيل المخصص',
                  'Assigned recording',
                  'Enregistrement attribué',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              hint: Text(
                _t(
                  'استخدم الصوت العام',
                  'Use general recording',
                  'Utiliser le son général',
                ),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    _t(
                      'الصوت العام',
                      'General recording',
                      'Son général',
                    ),
                  ),
                ),
                ..._recordings.map(
                  (recording) => DropdownMenuItem<String>(
                    value: recording.path,
                    child: Text(
                      '${recording.name.replaceFirst(RegExp(r'^\\d+_'), '')} · ${recording.sizeLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: _busy
                  ? null
                  : (path) => _selectRecording(prayer, path),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy || selectedPath == null
                        ? null
                        : () => _previewRecording(selectedPath),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      _t('معاينة الصوت', 'Preview', 'Écouter'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: _t(
                    'إيقاف المعاينة',
                    'Stop preview',
                    'Arrêter la lecture',
                  ),
                  onPressed: _busy ? null : _stopPreview,
                  icon: const Icon(Icons.stop_circle_outlined),
                ),
                IconButton(
                  tooltip: _t(
                    'إعادة للصوت العام',
                    'Use general sound',
                    'Utiliser le son général',
                  ),
                  onPressed: _busy || selectedPath == null
                      ? null
                      : () => _clearPrayer(prayer),
                  icon: const Icon(Icons.restart_alt_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t(
            'أصوات الأذان لكل صلاة',
            'Prayer Adhan sounds',
            'Sons de l’adhan par prière',
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF075B46),
                          Color(0xFF071C17),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFD8B66A)
                            .withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.graphic_eq_rounded,
                          color: Color(0xFFD8B66A),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _t(
                              'خصص صوتاً مستقلاً لكل صلاة من تسجيلاتك المحفوظة على الجهاز.',
                              'Assign a different local recording to each daily prayer.',
                              'Attribuez un enregistrement local différent à chaque prière.',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_recordings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _t(
                          'لا توجد تسجيلات بعد. أضف صوت الأذان من صفحة الأذان أولاً.',
                          'No recordings yet. Import an Adhan recording from the Adhan page first.',
                          'Aucun enregistrement. Importez d’abord un son depuis la page de l’adhan.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    for (final prayer
                        in MuminAdhanPrayerRecordingPreferences.supportedPrayers)
                      _buildPrayerCard(prayer),
                  const SizedBox(height: 8),
                  Text(
                    _t(
                      'اختيارات هذه الصفحة تحفظ محلياً على جهازك. المعاينة تشغّل التسجيل فوراً، أما التشغيل التلقائي عند وقت الصلاة فله إعداد مستقل.',
                      'Selections are stored locally. Preview plays immediately; automatic playback at prayer time is a separate feature.',
                      'Les choix sont enregistrés localement. La préécoute démarre immédiatement ; la lecture automatique à l’heure de prière est une fonction distincte.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
    );
  }
}
