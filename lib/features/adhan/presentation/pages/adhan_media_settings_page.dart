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
  static const _shortEnabledKey = 'mumin_adhan_short_audio_enabled_v1';
  static const _fullEnabledKey = 'mumin_adhan_full_audio_enabled_v1';
  static const _selectedImageKey = 'mumin_adhan_selected_mosque_image_v1';
  static const _galleryImagesKey = 'mumin_adhan_mosque_gallery_v1';

  static const _mosqueAssets = <String>[
    'assets/images/mosques/mumin_mosque.jpg',
    'assets/images/adhan/mumin_adhan_hero.jpg',
  ];

  bool _loading = true;
  bool _shortEnabled = true;
  bool _fullEnabled = true;
  bool _pickingImage = false;
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
    if (!mounted) return;
    setState(() {
      _shortEnabled = prefs.getBool(_shortEnabledKey) ?? true;
      _fullEnabled = prefs.getBool(_fullEnabledKey) ?? true;
      _selectedImagePath = prefs.getString(_selectedImageKey);
      _galleryImages = <String>{
        ..._mosqueAssets,
        ...?prefs.getStringList(_galleryImagesKey),
      }.toList(growable: true);
      _loading = false;
    });
  }

  Future<void> _setAudioEnabled({
    required bool shortAudio,
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = shortAudio ? _shortEnabledKey : _fullEnabledKey;
    final saved = await prefs.setBool(key, enabled);
    if (!saved) {
      throw StateError('Could not save the Adhan audio preference.');
    }
    if (!mounted) return;
    setState(() {
      if (shortAudio) {
        _shortEnabled = enabled;
      } else {
        _fullEnabled = enabled;
      }
    });
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
        '${directory.path}/mumin_adhan_mosque_${DateTime.now().microsecondsSinceEpoch}$extension',
      );
      await File(picked.path).copy(destination.path);

      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(_selectedImageKey, destination.path);
      final gallery = <String>{..._galleryImages, destination.path}.toList();
      final gallerySaved = await prefs.setStringList(_galleryImagesKey, gallery);
      if (!saved || !gallerySaved) throw StateError('Could not save the selected mosque image.');
      if (!mounted) return;
      setState(() {
        _selectedImagePath = destination.path;
        _galleryImages = gallery;
      });
      _message(_t('تم حفظ صورة المسجد واختيارها.', 'Mosque image saved and selected.', 'Image de mosquée enregistrée et sélectionnée.'));
    } catch (error) {
      _message('${_t('تعذر اختيار الصورة', 'Could not select the image', 'Impossible de sélectionner l’image')}: $error');
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _selectAsset(String asset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedImageKey, asset);
    if (!mounted) return;
    setState(() => _selectedImagePath = asset);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('إعدادات الأذان والواجهة', 'Adhan & screen settings', 'Réglages Adhan et écran')),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle(_t('الصوتان بشكل مستقل', 'Independent audio controls', 'Commandes audio indépendantes')),
                SwitchListTile(
                  value: _shortEnabled,
                  onChanged: (value) => _setAudioEnabled(shortAudio: true, enabled: value),
                  secondary: const Icon(Icons.volume_down_rounded, color: Color(0xFFD8B66A)),
                  title: Text(_t('التكبير القصير', 'Short takbeer', 'Takbir court')),
                  subtitle: Text(_t('يبدأ تلقائياً عند فتح تنبيه الصلاة. مفعّل افتراضياً ويبقى اختيارك محفوظاً.', 'Starts automatically when a prayer alert opens. Enabled by default; your choice is remembered.', 'Démarre automatiquement à l’ouverture de l’alerte. Activé par défaut ; votre choix est mémorisé.')),
                  activeThumbColor: const Color(0xFFD8B66A),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _fullEnabled,
                  onChanged: (value) => _setAudioEnabled(shortAudio: false, enabled: value),
                  secondary: const Icon(Icons.graphic_eq_rounded, color: Color(0xFFD8B66A)),
                  title: Text(_t('الأذان الكامل', 'Full Adhan', 'Adhan complet')),
                  subtitle: Text(_t('يسمح بتشغيل التسجيل الكامل عند سحب القطرة. مستقل عن التكبير القصير.', 'Allows the complete recording to play when you swipe the drop. Independent of short takbeer.', 'Autorise la lecture complète lorsque vous faites glisser la goutte. Indépendant du takbir court.')),
                  activeThumbColor: const Color(0xFFD8B66A),
                ),
                const SizedBox(height: 24),
                _sectionTitle(_t('صورة واجهة الأذان', 'Adhan screen image', 'Image de l’écran Adhan')),
                Text(
                  _t('اختر صورة مسجد من الصور المرفقة أو أضف صورة من هاتفك. تُحفظ الصورة المختارة على هذا الجهاز.', 'Choose a bundled mosque image or add one from your phone. The selected image is saved on this device.', 'Choisissez une image incluse ou ajoutez-en une depuis votre téléphone. Elle sera conservée sur cet appareil.'),
                  style: theme.textTheme.bodySmall,
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
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _selectAsset(path),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? const Color(0xFFD8B66A) : theme.dividerColor,
                            width: selected ? 3 : 1,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _imagePreview(path),
                            if (selected)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Color(0xFFD8B66A),
                                  child: Icon(Icons.check, size: 17, color: Color(0xFF071C17)),
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
                  label: Text(_t('إضافة صورة من الهاتف', 'Add an image from phone', 'Ajouter une image du téléphone')),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD8B66A).withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_t('اختبر واجهة الأذان الآن', 'Preview the Adhan screen now', 'Prévisualiser l’écran Adhan maintenant'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(_t('افتح نفس الواجهة دون انتظار موعد الصلاة. لن يُرسل هذا الاختبار إشعار صلاة مجدولاً.', 'Open the same screen without waiting for prayer time. This test does not send a scheduled prayer notification.', 'Ouvrez le même écran sans attendre l’heure de prière. Ce test n’envoie aucune notification programmée.')),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _preview,
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        label: Text(_t('معاينة الواجهة', 'Preview screen', 'Prévisualiser')),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF075B46),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      );
}
