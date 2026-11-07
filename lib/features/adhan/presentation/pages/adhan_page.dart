
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/mumin_language_controller.dart';
import '../../data/services/mumin_adhan_artwork_service.dart';
import '../../data/services/mumin_adhan_recording_library.dart';
import '../../data/services/mumin_adhan_recording_playback_service.dart';
import 'mumin_adhan_now_page.dart';
import '../../data/models/mumin_media_asset_registry.dart';

class AdhanPage extends StatefulWidget {
  const AdhanPage({super.key});

  @override
  State<AdhanPage> createState() => _AdhanPageState();
}

class _AdhanPageState extends State<AdhanPage> {
  final MuminAdhanArtworkService _artworkService =
      MuminAdhanArtworkService();

  late final MuminAdhanRecordingPlaybackService _playbackService;

  List<MuminAdhanRecording> _recordings = [];
  MuminAdhanRecording? _selectedRecording;
  File? _artwork;

  bool _loading = true;
  bool _busy = false;
  String? _error;

  String get _languageCode =>
      context.watch<MuminLanguageController>().languageCode;

  bool get _isArabic => _languageCode == 'ar';
  bool get _isFrench => _languageCode == 'fr';

  String _t(String ar, String en, String fr) {
    if (_isArabic) return ar;
    if (_isFrench) return fr;
    return en;
  }

  Color get _gold => const Color(0xFFD8B66A);
  Color get _emerald => const Color(0xFF075B46);
  Color get _midnight => const Color(0xFF071C17);

  @override
  void initState() {
    super.initState();

    _playbackService =
        context.read<MuminAdhanRecordingPlaybackService>();

    _loadPage();
  }

  Future<void> _loadPage() async {
    try {
      final results = await Future.wait<Object?>([
        _playbackService.getRecordings(),
        _playbackService.getSelectedRecording(),
        _artworkService.getSavedArtwork(),
      ]);

      if (!mounted) return;

      setState(() {
        _recordings =
            results[0] as List<MuminAdhanRecording>;
        _selectedRecording =
            results[1] as MuminAdhanRecording?;
        _artwork = results[2] as File?;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: Adhan page loading failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _t(
          'تعذر تحميل مكتبة الأذان.',
          'Could not load the Adhan library.',
          'Impossible de charger la bibliothèque de l’adhan.',
        );
      });
    }
  }

  Future<void> _importRecording() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final recording =
          await _playbackService.importAndPlay();

      if (recording != null && mounted) {
        await _loadPage();

        _showMessage(
          _t(
            'تم استيراد التسجيل وتشغيله.',
            'Recording imported and playing.',
            'Enregistrement importé et en lecture.',
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: Adhan import failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _error = _t(
            'تعذر استيراد الملف. تحقق من صيغته وحجمه.',
            'Could not import this file. Check its format and size.',
            'Import impossible. Vérifiez le format et la taille.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _playRecording(
    MuminAdhanRecording recording,
  ) async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _playbackService.playRecording(recording);

      if (!mounted) return;

      setState(() {
        _selectedRecording = recording;
      });
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: Adhan playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _error = _t(
            'تعذر تشغيل التسجيل.',
            'Could not play this recording.',
            'Impossible de lire cet enregistrement.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_busy) return;

    try {
      if (_playbackService.isPlaying) {
        await _playbackService.pause();
      } else {
        final selected = _selectedRecording;

        if (selected == null) {
          await _importRecording();
          return;
        }

        await _playbackService.resume();
      }

      if (mounted) setState(() {});
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: Adhan playback control failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _error = _t(
            'تعذر التحكم في تشغيل الأذان.',
            'Could not control Adhan playback.',
            'Impossible de contrôler la lecture de l’adhan.',
          );
        });
      }
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _playbackService.stop();

      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Mumin Pro: Adhan stop failed: $error');
    }
  }

  Future<void> _chooseArtwork() async {
    try {
      final image =
          await _artworkService.pickAndSaveArtwork();

      if (!mounted || image == null) return;

      setState(() {
        _artwork = image;
      });

      _showMessage(
        _t(
          'تم تحديث صورة الأذان.',
          'Adhan artwork updated.',
          'Image de l’adhan mise à jour.',
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: artwork selection failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _error = _t(
            'تعذر اختيار الصورة.',
            'Could not select the image.',
            'Impossible de sélectionner l’image.',
          );
        });
      }
    }
  }

  Future<void> _deleteRecording(
    MuminAdhanRecording recording,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _t(
              'حذف التسجيل؟',
              'Delete recording?',
              'Supprimer l’enregistrement ?',
            ),
          ),
          content: Text(
            _t(
              'سيتم حذف هذه النسخة من مكتبة التطبيق.',
              'This copy will be removed from the app library.',
              'Cette copie sera supprimée de la bibliothèque.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: Text(
                _t('إلغاء', 'Cancel', 'Annuler'),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: Text(
                _t('حذف', 'Delete', 'Supprimer'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _playbackService.deleteRecording(recording.path);
      await _loadPage();

      if (mounted) {
        _showMessage(
          _t(
            'تم حذف التسجيل.',
            'Recording deleted.',
            'Enregistrement supprimé.',
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: recording deletion failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _error = _t(
            'تعذر حذف التسجيل.',
            'Could not delete the recording.',
            'Impossible de supprimer l’enregistrement.',
          );
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
appBar: AppBar(
  title: Text(
    _t('الأذان', 'Adhan', 'Adhan'),
    style: const TextStyle(fontWeight: FontWeight.w800),
  ),
  centerTitle: true,
  backgroundColor: Colors.transparent,
  elevation: 0,
  actions: [
    IconButton(
      tooltip: _t(
        'فتح واجهة الأذان',
        'Open Adhan screen',
        'Ouvrir l’écran Adhan',
      ),
      icon: const Icon(
        Icons.open_in_full_rounded,
        color: Color(0xFFD8B66A),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const MuminAdhanNowPage(),
          ),
        );
      },
    ),
  ],
),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadPage,
              color: _gold,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                children: [
                  _buildArtworkCard(isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    _t(
                      'مكتبة تسجيلات الأذان',
                      'Adhan recording library',
                      'Bibliothèque des adhan',
                    ),
                    _t(
                      'اختر الصوت الذي تفضله',
                      'Choose your preferred recitation',
                      'Choisissez votre récitation préférée',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildImportButton(),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    _buildError(),
                    const SizedBox(height: 12),
                  ],
                  if (_recordings.isEmpty)
                    _buildEmptyLibrary()
                  else
                    ..._recordings.map(_buildRecordingTile),
                  const SizedBox(height: 24),
                  _buildPlaybackNote(),
                ],
              ),
            ),
    );
  }

  
Widget _buildArtworkCard(bool isDark) {
  return Container(
    height: 320,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: _gold.withValues(alpha: 0.45),
      ),
      boxShadow: [
        BoxShadow(
          color: _emerald.withValues(alpha: 0.16),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (_artwork != null && _artwork!.existsSync())
          Image.file(
            _artwork!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              MuminMediaAssetRegistry.adhanHeroPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _artworkFallback(),
            ),
          )
        else
          Image.asset(
            MuminMediaAssetRegistry.adhanHeroPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _artworkFallback(),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.04),
                Colors.black.withValues(alpha: 0.22),
                _midnight.withValues(alpha: 0.94),
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
        ),
        PositionedDirectional(
          top: 16,
          end: 16,
          child: _artworkButton(),
        ),
        PositionedDirectional(
          start: 22,
          end: 22,
          bottom: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.nights_stay_rounded,
                color: _gold,
                size: 25,
              ),
              const SizedBox(height: 10),
              Text(
                _t(
                  'نداء الصلاة',
                  'The call to prayer',
                  'L’appel à la prière',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _t(
                  'سكينة في كل موعد',
                  'A moment of peace at every prayer',
                  'Un moment de paix à chaque prière',
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              _buildPlaybackControls(),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _artworkFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C654C),
            Color(0xFF063E31),
            Color(0xFF071C17),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.mosque_rounded,
          size: 115,
          color: _gold.withValues(alpha: 0.78),
        ),
      ),
    );
  }

  Widget _artworkButton() {
    return Material(
      color: _midnight.withValues(alpha: 0.76),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: _chooseArtwork,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined,
                  color: _gold, size: 18),
              const SizedBox(width: 7),
              Text(
                _t('تغيير الصورة', 'Change image', 'Changer l’image'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    final playing = _playbackService.isPlaying;

    return Row(
      children: [
        Material(
          color: _gold,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: _busy ? null : _togglePlayback,
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 58,
              height: 52,
              child: _busy
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF071C17),
                      ),
                    )
                  : Icon(
                      playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: _midnight,
                      size: 31,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: _t('إيقاف', 'Stop', 'Arrêter'),
          onPressed: _busy ? null : _stopPlayback,
          icon: const Icon(
            Icons.stop_circle_outlined,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _selectedRecording?.name ??
                _t(
                  'لم يتم اختيار تسجيل بعد',
                  'No recording selected',
                  'Aucun enregistrement sélectionné',
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildImportButton() {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: _busy ? null : _importRecording,
        style: FilledButton.styleFrom(
          backgroundColor: _emerald,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: BorderSide(
              color: _gold.withValues(alpha: 0.65),
            ),
          ),
        ),
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: Text(
          _t(
            'استيراد تسجيل من الهاتف',
            'Import recording from phone',
            'Importer un enregistrement',
          ),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildRecordingTile(MuminAdhanRecording recording) {
    final selected = _selectedRecording?.path == recording.path;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(
              alpha: 0.86,
            ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? _gold.withValues(alpha: 0.85)
              : Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: selected ? 1.4 : 0.7,
        ),
      ),
      child: ListTile(
        onTap: _busy ? null : () => _playRecording(recording),
        leading: CircleAvatar(
          backgroundColor: _emerald.withValues(alpha: 0.12),
          child: Icon(
            selected
                ? Icons.graphic_eq_rounded
                : Icons.music_note_rounded,
            color: _gold,
          ),
        ),
        title: Text(
          recording.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${recording.extension.toUpperCase()} · ${recording.sizeLabel}',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          tooltip: _t('حذف', 'Delete', 'Supprimer'),
          onPressed: _busy
              ? null
              : () => _deleteRecording(recording),
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLibrary() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(
              alpha: 0.72,
            ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _gold.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 42,
            color: _gold,
          ),
          const SizedBox(height: 12),
          Text(
            _t(
              'مكتبة الأذان فارغة',
              'Your Adhan library is empty',
              'Votre bibliothèque est vide',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _t(
              'استورد تسجيلاً موثوقاً لتبدأ الاستماع.',
              'Import a trusted recording to start listening.',
              'Importez un enregistrement fiable pour commencer.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
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
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        _error!,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPlaybackNote() {
    return Text(
      _t(
        'تُحفظ التسجيلات والصور على جهازك، ولا تُرفع إلى خوادم خارجية.',
        'Recordings and artwork stay on your device and are not uploaded.',
        'Les enregistrements et images restent sur votre appareil.',
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 11,
      ),
    );
  }
}
