import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/mumin_adhan_audio_handler.dart';
import 'mumin_adhan_experience_page.dart';

class AdhanMediaSettingsPage extends StatefulWidget {
  const AdhanMediaSettingsPage({super.key});

  @override
  State<AdhanMediaSettingsPage> createState() => _AdhanMediaSettingsPageState();
}

class _AdhanMediaSettingsPageState extends State<AdhanMediaSettingsPage> {
  static const _modeKey = 'mumin_adhan_audio_mode_v1';
  static const _shortEnabledKey = 'mumin_adhan_short_audio_enabled_v1';
  static const _fullEnabledKey = 'mumin_adhan_full_audio_enabled_v1';
  static const _selectedImageKey = 'mumin_adhan_selected_mosque_image_v1';
  static const _galleryImagesKey = 'mumin_adhan_mosque_gallery_v1';

  static const _shortAsset = 'assets/audio/notifications/adhan_takbeer_twice.mp3';
  static const _fullAsset = 'assets/audio/adhan/adhan_full.mp3';

  static const _mosqueAssets = <String>[
    'assets/images/mosques/mumin_mosque.jpg',
    'assets/images/adhan/mumin_adhan_hero.jpg',
  ];

  bool _loading = true;
  bool _pickingImage = false;
  bool _testingAudio = false;
  String _audioMode = 'short';
  String? _selectedImagePath;
  List<String> _galleryImages = List<String>.of(_mosqueAssets);

  String _t(String ar, String en, String fr) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'en') return en;
    if (code == 'fr') return fr;
    return ar;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_modeKey);
    final legacyShort = prefs.getBool(_shortEnabledKey) ?? true;
    final legacyFull = prefs.getBool(_fullEnabledKey) ?? false;
    final mode = savedMode == 'full' || (savedMode == null && legacyFull && !legacyShort)
        ? 'full'
        : 'short';
    if (savedMode == null) {
      await prefs.setString(_modeKey, mode);
      await prefs.setBool(_shortEnabledKey, mode == 'short');
      await prefs.setBool(_fullEnabledKey, mode == 'full');
    }
    if (!mounted) return;
    setState(() {
      _audioMode = mode;
      _selectedImagePath = prefs.getString(_selectedImageKey);
      _galleryImages = <String>{
        ..._mosqueAssets,
        ...?prefs.getStringList(_galleryImagesKey),
      }.toList(growable: true);
      _loading = false;
    });
  }

  Future<void> _setAudioMode(String mode) async {
    if (mode != 'short' && mode != 'full') return;
    await context.read<MuminAdhanAudioHandler>().stop();
    final prefs = await SharedPreferences.getInstance();
    final modeSaved = await prefs.setString(_modeKey, mode);
    final shortSaved = await prefs.setBool(_shortEnabledKey, mode == 'short');
    final fullSaved = await prefs.setBool(_fullEnabledKey, mode == 'full');
    if (!modeSaved || !shortSaved || !fullSaved) {
      throw StateError('Could not save the selected Adhan audio mode.');
    }
    if (!mounted) return;
    setState(() => _audioMode = mode);
    _message(
      mode == 'short'
          ? _t('تم اختيار التكبير القصير وحده.', 'Short takbeer selected on its own.', 'Le takbir court est sélectionné seul.')
          : _t('تم اختيار الأذان الكامل وحده.', 'Full Adhan selected on its own.', 'L’Adhan complet est sélectionné seul.'),
    );
  }

  Future<void> _testAudio(String mode) async {
    if (_testingAudio) return;
    setState(() => _testingAudio = true);
    try {
      final audio = context.read<MuminAdhanAudioHandler>();
      await audio.stop();
      await audio.playAsset(
        mode == 'short' ? _shortAsset : _fullAsset,
        title: mode == 'short'
            ? _t('اختبار التكبير القصير', 'Short takbeer test', 'Test du takbir court')
            : _t('اختبار الأذان الكامل', 'Full Adhan test', 'Test de l’Adhan complet'),
      );
    } catch (_) {
      _message(
        _t('تعذر تشغيل التسجيل. تحقق من ملف الصوت.', 'Could not play the recording. Check the audio asset.', 'Impossible de lire l’enregistrement. Vérifiez le fichier audio.'),
      );
    } finally {
      if (mounted) setState(() => _testingAudio = false);
    }
  }

  Future<void> _pickImage() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 2000,
      );
      if (picked == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final extension = picked.path.contains('.')
          ? picked.path.substring(picked.path.lastIndexOf('.'))
          : '.jpg';
      final destination = File(
        directory.path + '/mumin_adhan_mosque_' +
            DateTime.now().microsecondsSinceEpoch.toString() + extension,
      );
      await File(picked.path).copy(destination.path);

      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(_selectedImageKey, destination.path);
      final gallery = <String>{..._galleryImages, destination.path}.toList();
      final gallerySaved = await prefs.setStringList(_galleryImagesKey, gallery);
      if (!saved || !gallerySaved) {
        throw StateError('Could not save the selected mosque image.');
      }
      if (!mounted) return;
      setState(() {
        _selectedImagePath = destination.path;
        _galleryImages = gallery;
      });
      _message(_t('تم حفظ صورة المسجد واختيارها.', 'Mosque image saved and selected.', 'Image de mosquée enregistrée et sélectionnée.'));
    } catch (error) {
      _message(
        _t('تعذر اختيار الصورة وحفظها.', 'Could not select and save the image.', 'Impossible de sélectionner et enregistrer l’image.'),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _selectImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(_selectedImageKey, path);
    if (!saved) {
      _message(_t('تعذر حفظ اختيار الصورة.', 'Could not save image selection.', 'Impossible d’enregistrer le choix de l’image.'));
      return;
    }
    if (!mounted) return;
    setState(() => _selectedImagePath = path);
  }

  Future<void> _preview() async {
    final audio = context.read<MuminAdhanAudioHandler>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MuminAdhanExperiencePage(
          prayer: Prayer.fajr,
          previewMode: true,
          audioHandlerOverride: audio,
        ),
      ),
    );
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  Widget _imagePreview(String path) {
    final isFile = !path.startsWith('assets/');
    final file = isFile ? File(path) : null;
    if (file != null && !file.existsSync()) {
      return const ColoredBox(
        color: Color(0xFF071C17),
        child: Icon(Icons.broken_image_outlined, color: Colors.white54),
      );
    }
    return Image(
      image: isFile ? FileImage(file!) : AssetImage(path) as ImageProvider,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFF071C17),
        child: Icon(Icons.image_not_supported_outlined, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('تخصيص تجربة الأذان', 'Adhan experience', 'Expérience Adhan')),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                _heroCard(theme),
                const SizedBox(height: 22),
                _sectionTitle(_t('اختيار صوت واحد', 'Choose one recording', 'Choisir un seul enregistrement')),
                Text(
                  _t(
                    'اختر تسجيلاً واحداً فقط ليعمل عند تنبيه الصلاة. لن يبدأ التسجيل الآخر معه.',
                    'Choose exactly one recording for the prayer alert. The other recording will not start with it.',
                    'Choisissez un seul enregistrement pour l’alerte. L’autre ne démarrera pas avec lui.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: 12),
                _audioChoice(
                  mode: 'short',
                  icon: Icons.graphic_eq_rounded,
                  title: _t('التكبير القصير', 'Short takbeer', 'Takbir court'),
                  subtitle: _t('تسجيل «الله أكبر» مرتين فقط.', 'Two takbeer phrases only.', 'Deux takbir uniquement.'),
                ),
                const SizedBox(height: 10),
                _audioChoice(
                  mode: 'full',
                  icon: Icons.mosque_rounded,
                  title: _t('الأذان الكامل', 'Full Adhan', 'Adhan complet'),
                  subtitle: _t('تشغيل تسجيل الأذان كاملاً عبر دائرة البصمة في شاشة التنبيه.', 'Play the complete Adhan using the fingerprint-style control on the alert screen.', 'Lire l’Adhan complet avec le bouton circulaire de l’écran d’alerte.'),
                ),
                const SizedBox(height: 14),
                _sectionTitle(_t('اختبار التسجيلات', 'Test recordings', 'Tester les enregistrements')),
                Text(
                  _t('كل زر يختبر ملفاً واحداً فقط، ويوقف أي صوت سابق قبل بدء الاختبار.', 'Each button tests one file only and stops previous audio before playback.', 'Chaque bouton teste un seul fichier et arrête tout son précédent avant la lecture.'),
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testingAudio ? null : () => _testAudio('short'),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(_t('اختبار القصير', 'Test short', 'Tester court')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testingAudio ? null : () => _testAudio('full'),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(_t('اختبار الكامل', 'Test full', 'Tester complet')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _sectionTitle(_t('خلفية شاشة الأذان', 'Adhan screen background', 'Fond de l’écran Adhan')),
                Text(
                  _t('اختر صورة من المجموعة أو أضف صورة من هاتفك. تبقى الصور التي تضيفها محفوظة على جهازك.', 'Choose a bundled image or add one from your phone. Added images remain stored on your device.', 'Choisissez une image incluse ou ajoutez-en une depuis votre téléphone. Les images ajoutées restent sur votre appareil.'),
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _galleryImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final path = _galleryImages[index];
                    final selected = path == _selectedImagePath ||
                        (_selectedImagePath == null && path == _mosqueAssets.first);
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _selectImage(path),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected ? const Color(0xFFD8B66A) : colors.outlineVariant,
                            width: selected ? 2.4 : 1,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _imagePreview(path),
                            if (selected)
                              const Positioned(
                                top: 9,
                                right: 9,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Color(0xFFD8B66A),
                                  child: Icon(Icons.check_rounded, size: 17, color: Color(0xFF071C17)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickingImage ? null : _pickImage,
                  icon: _pickingImage
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_t('إضافة صورة من الهاتف', 'Add image from phone', 'Ajouter une image du téléphone')),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFD8B66A).withValues(alpha: 0.38)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _t('معاينة الواجهة', 'Preview the screen', 'Prévisualiser l’écran'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _t('افتح التصميم فوراً دون انتظار الصلاة. المعاينة صامتة حتى تختبر كل تسجيل على حدة من الأزرار أعلاه.', 'Open the design immediately without waiting for prayer time. Preview is silent; test each recording separately using the buttons above.', 'Ouvrez le design immédiatement. L’aperçu est silencieux ; testez chaque enregistrement séparément avec les boutons ci-dessus.'),
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _preview,
                        icon: const Icon(Icons.visibility_rounded),
                        label: Text(_t('معاينة شاشة الأذان', 'Preview Adhan screen', 'Aperçu de l’écran Adhan')),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF075B46),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _heroCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B4939), Color(0xFF061C17)],
        ),
        border: Border.all(color: const Color(0x66D8B66A)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0x22D8B66A),
            child: Icon(Icons.tune_rounded, color: Color(0xFFD8B66A), size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('تجربة أذانك كما تحب', 'Your Adhan, your way', 'Votre Adhan, à votre façon'),
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  _t('صوت واحد • صورة تختارها • معاينة فورية', 'One recording • Your image • Instant preview', 'Un son • Votre image • Aperçu immédiat'),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _audioChoice({
    required String mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _audioMode == mode;
    return Material(
      color: selected
          ? const Color(0xFFD8B66A).withValues(alpha: 0.10)
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _setAudioMode(mode),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? const Color(0xFFD8B66A) : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFD8B66A), size: 25),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? const Color(0xFFD8B66A) : Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      );
}
