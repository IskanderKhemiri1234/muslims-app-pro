import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/mumin_adhan_audio_handler.dart';
import 'mumin_adhan_experience_page.dart';

class AdhanBackgroundLibraryPage extends StatefulWidget {
  const AdhanBackgroundLibraryPage({super.key});

  @override
  State<AdhanBackgroundLibraryPage> createState() =>
      _AdhanBackgroundLibraryPageState();
}

class _AdhanBackgroundLibraryPageState
    extends State<AdhanBackgroundLibraryPage> {
  static const _selectedKey = 'mumin_adhan_selected_mosque_image_v1';
  static const _galleryKey = 'mumin_adhan_mosque_gallery_v1';

  static const _bundled = <_MosqueCover>[
    _MosqueCover('assets/images/mosques/mumin_mosque.jpg', 'مسجد مؤمن', 'Mumin Mosque', 'Mosquée Mumin'),
    _MosqueCover('assets/images/adhan/mumin_adhan_hero.jpg', 'الخلفية الأصلية', 'Original background', 'Fond original'),
    _MosqueCover('assets/images/mosques/01_masjid_al_haram.jpg', 'المسجد الحرام', 'Al-Masjid al-Haram', 'Mosquée al-Haram'),
    _MosqueCover('assets/images/mosques/02_masjid_nabawi.jpg', 'المسجد النبوي', 'Prophet’s Mosque', 'Mosquée du Prophète'),
    _MosqueCover('assets/images/mosques/03_sheikh_zayed.jpg', 'جامع الشيخ زايد', 'Sheikh Zayed Grand Mosque', 'Grande mosquée Cheikh Zayed'),
    _MosqueCover('assets/images/mosques/05_blue_mosque.jpg', 'الجامع الأزرق', 'Blue Mosque', 'Mosquée bleue'),
    _MosqueCover('assets/images/mosques/06_hagia_sophia.jpg', 'آيا صوفيا', 'Hagia Sophia', 'Sainte-Sophie'),
    _MosqueCover('assets/images/mosques/07_sultan_qaboos.jpg', 'جامع السلطان قابوس', 'Sultan Qaboos Grand Mosque', 'Grande mosquée du Sultan Qaboos'),
    _MosqueCover('assets/images/mosques/08_putra_mosque.jpg', 'مسجد بوترا', 'Putra Mosque', 'Mosquée Putra'),
    _MosqueCover('assets/images/mosques/09_faisal_mosque.jpg', 'مسجد الملك فيصل', 'Faisal Mosque', 'Mosquée Faisal'),
    _MosqueCover('assets/images/mosques/14_dome_of_the_rock.jpg', 'قبة الصخرة', 'Dome of the Rock', 'Dôme du Rocher'),
    _MosqueCover('assets/images/mosques/15_badshahi_mosque.jpg', 'مسجد بادشاهي', 'Badshahi Mosque', 'Mosquée Badshahi'),
  ];

  List<String> _images = _bundled.map((e) => e.path).toList();
  String? _selected;
  bool _loading = true;
  bool _picking = false;

  String _t(String ar, String en, String fr) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'en' ? en : code == 'fr' ? fr : ar;
  }

  String _coverName(String path) {
    for (final cover in _bundled) {
      if (cover.path == path) {
        return _t(cover.ar, cover.en, cover.fr);
      }
    }
    return _t('صورة من الهاتف', 'From your device', 'Depuis votre appareil');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;

    final stored = preferences.getStringList(_galleryKey) ?? const <String>[];
    final images = <String>{
      ..._bundled.map((e) => e.path),
      ...stored,
    }.toList();

    setState(() {
      _images = images;
      _selected = preferences.getString(_selectedKey);
      _loading = false;
    });
  }

  Future<void> _select(String path) async {
    final saved = await (await SharedPreferences.getInstance())
        .setString(_selectedKey, path);
    if (!saved) {
      _message(_t(
        'تعذر حفظ الخلفية.',
        'Could not save the background.',
        'Impossible d’enregistrer le fond.',
      ));
      return;
    }
    if (mounted) setState(() => _selected = path);
  }

  Future<void> _pick() async {
    if (_picking) return;
    setState(() => _picking = true);

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 3200,
      );
      if (picked == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final extension = picked.path.contains('.')
          ? picked.path.substring(picked.path.lastIndexOf('.'))
          : '.jpg';
      final destination = File(
        '${directory.path}/mumin_adhan_background_'
        '${DateTime.now().microsecondsSinceEpoch}$extension',
      );
      await File(picked.path).copy(destination.path);

      final updated = <String>{..._images, destination.path}.toList();
      final preferences = await SharedPreferences.getInstance();
      final gallerySaved =
          await preferences.setStringList(_galleryKey, updated);
      final selectionSaved =
          await preferences.setString(_selectedKey, destination.path);

      if (!gallerySaved || !selectionSaved) {
        throw StateError('Could not persist selected background.');
      }

      if (mounted) {
        setState(() {
          _images = updated;
          _selected = destination.path;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: could not import Adhan background: $error');
      debugPrintStack(stackTrace: stackTrace);
      _message(_t(
        'تعذرت إضافة الصورة.',
        'Could not add the image.',
        'Impossible d’ajouter l’image.',
      ));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _preview(String imagePath) async {
    final audio = context.read<MuminAdhanAudioHandler>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MuminAdhanExperiencePage(
          prayer: Prayer.fajr,
          previewMode: true,
          backgroundImageOverride: imagePath,
          audioHandlerOverride: audio,
        ),
      ),
    );
  }

  Widget _image(String path) {
    final physicalWidth = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(480, 1440)
        .toInt();

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        cacheWidth: physicalWidth,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _missing(),
      );
    }

    final file = File(path);
    if (!file.existsSync()) return _missing();

    return Image.file(
      file,
      fit: BoxFit.cover,
      cacheWidth: physicalWidth,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _missing(),
    );
  }

  Widget _missing() => const ColoredBox(
        color: Color(0xFF071C17),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
          ),
        ),
      );

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(
          'مكتبة خلفيات الأذان',
          'Adhan background library',
          'Bibliothèque des arrière-plans',
        )),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 128),
              children: [
                Text(
                  _t(
                    'اختر المشهد الذي يرافق الأذان. ستظهر الخلفية المختارة على كامل الشاشة عند كل أذان.',
                    'Choose the scene that accompanies the Adhan. Your selected background fills the screen for every prayer alert.',
                    'Choisissez le décor qui accompagne l’Adhan. Votre fond choisi remplira l’écran à chaque appel.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _images.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final path = _images[index];
                    final selected = path == _selected ||
                        (_selected == null &&
                            path == _bundled.first.path);

                    return Semantics(
                      button: true,
                      selected: selected,
                      label: _coverName(path),
                      child: InkWell(
                        onTap: () => _select(path),
                        borderRadius: BorderRadius.circular(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _image(path),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x08000000),
                                      Color(0x10000000),
                                      Color(0xD9000806),
                                    ],
                                    stops: [0, 0.48, 1],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Semantics(
                                  button: true,
                                  label: _t(
                                    'معاينة الخلفية بملء الشاشة',
                                    'Preview background full screen',
                                    'Aperçu du fond en plein écran',
                                  ),
                                  child: Material(
                                    color: const Color(0xFFF0D28A),
                                    shape: const CircleBorder(),
                                    elevation: 8,
                                    shadowColor: Colors.black87,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => _preview(path),
                                      child: const SizedBox(
                                        width: 46,
                                        height: 46,
                                        child: Icon(
                                          Icons.visibility_rounded,
                                          color: Color(0xFF071C17),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (selected)
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    width: 31,
                                    height: 31,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD8B66A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFF071C17),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: 10,
                                right: 10,
                                bottom: 12,
                                child: Text(
                                  _coverName(path),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (selected)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFD8B66A),
                                          width: 2,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _picking ? null : _pick,
                  icon: _picking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_t(
                    'إضافة صورة من الهاتف',
                    'Add image from phone',
                    'Ajouter une image',
                  )),
                ),
              ],
            ),
    );
  }
}

class _MosqueCover {
  const _MosqueCover(this.path, this.ar, this.en, this.fr);

  final String path;
  final String ar;
  final String en;
  final String fr;
}
