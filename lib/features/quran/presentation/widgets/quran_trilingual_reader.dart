import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/quran_trilingual_data_source.dart';

enum _TrilingualTheme { day, night, warmPaper }

class QuranTrilingualReader extends StatefulWidget {
  const QuranTrilingualReader({
    super.key,
    required this.initialSurah,
    required this.initialAyah,
    required this.surahNames,
    required this.onClose,
    required this.onVerseBookmark,
  });

  final int initialSurah;
  final int initialAyah;
  final List<String> surahNames;
  final VoidCallback onClose;
  final Future<void> Function(QuranTrilingualAyah verse, String surahName)
      onVerseBookmark;

  @override
  State<QuranTrilingualReader> createState() => _QuranTrilingualReaderState();
}

class _QuranTrilingualReaderState extends State<QuranTrilingualReader> {
  static const String _themeKey = 'mumin_pro_quran_reader_theme_v1';
  static const String _lastSurahKey = 'quran_last_read_surah';
  static const String _lastAyahKey = 'quran_last_read_ayah';

  final QuranTrilingualDataSource _source = QuranTrilingualDataSource();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = <int, GlobalKey>{};

  _TrilingualTheme _theme = _TrilingualTheme.day;
  QuranTrilingualSurah? _surah;
  int _surahNumber = 1;
  int _currentAyah = 1;
  bool _loading = true;
  bool _downloading = false;
  int _downloadedSurahs = 0;
  String? _error;

  Color get _background => switch (_theme) {
        _TrilingualTheme.day => const Color(0xFF061D18),
        _TrilingualTheme.night => const Color(0xFF071326),
        _TrilingualTheme.warmPaper => const Color(0xFFE9D9B8),
      };

  Color get _primaryText => switch (_theme) {
        _TrilingualTheme.day => const Color(0xFFF4EBD7),
        _TrilingualTheme.night => const Color(0xFFF0F3F7),
        _TrilingualTheme.warmPaper => const Color(0xFF33281D),
      };

  Color get _secondaryText => switch (_theme) {
        _TrilingualTheme.day => const Color(0xFFC7D8C8),
        _TrilingualTheme.night => const Color(0xFFB8C8DC),
        _TrilingualTheme.warmPaper => const Color(0xFF6D5638),
      };

  Color get _accent => switch (_theme) {
        _TrilingualTheme.day => const Color(0xFFD9BA75),
        _TrilingualTheme.night => const Color(0xFFC6D4E8),
        _TrilingualTheme.warmPaper => const Color(0xFF806039),
      };

  @override
  void initState() {
    super.initState();
    _surahNumber = widget.initialSurah.clamp(1, 114);
    _currentAyah = widget.initialAyah < 1 ? 1 : widget.initialAyah;
    _restoreReaderState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    unawaited(_source.dispose());
    super.dispose();
  }

  Future<void> _restoreReaderState() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedTheme = preferences.getString(_themeKey);
      final savedSurah = preferences.getInt(_lastSurahKey);
      final savedAyah = preferences.getInt(_lastAyahKey);
      if (savedTheme != null) {
        _theme = _TrilingualTheme.values.firstWhere(
          (item) => item.name == savedTheme,
          orElse: () => _TrilingualTheme.day,
        );
      }
      if (savedSurah != null && savedSurah >= 1 && savedSurah <= 114) {
        _surahNumber = savedSurah;
      }
      if (savedAyah != null && savedAyah > 0) {
        _currentAyah = savedAyah;
      }
    } catch (_) {
      // Keep the supplied initial reading position.
    }
    await _loadSurah(_surahNumber, targetAyah: _currentAyah);
  }

  Future<void> _loadSurah(int number, {int targetAyah = 1}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _surah = null;
      _surahNumber = number;
      _currentAyah = targetAyah;
      _verseKeys.clear();
    });

    try {
      final surah = await _source.getSurah(number);
      if (!mounted) return;
      if (targetAyah > surah.verses.length) {
        throw const FormatException('Saved verse is outside this surah.');
      }
      setState(() {
        _surah = surah;
        _loading = false;
        _currentAyah = targetAyah;
      });
      await _savePosition(number, targetAyah);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revealAyah(targetAyah);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _savePosition(int surah, int ayah) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(_lastSurahKey, surah);
      await preferences.setInt(_lastAyahKey, ayah);
    } catch (_) {
      // Reading remains available for this session.
    }
  }

  void _revealAyah(int ayah) {
    final context = _verseKeys[ayah]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.08,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _selectTheme(_TrilingualTheme theme) async {
    setState(() => _theme = theme);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, theme.name);
  }

  Future<void> _downloadAll() async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _downloadedSurahs = 0;
    });
    try {
      await _source.downloadCompleteQuran(
        onProgress: (completed, total) {
          if (mounted) setState(() => _downloadedSurahs = completed);
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتمل تنزيل القرآن وترجمتيه للعمل دون اتصال')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إكمال التنزيل: $error')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _surahName(int number) {
    if (number < 1 || number > widget.surahNames.length) {
      return 'Surah $number';
    }
    return widget.surahNames[number - 1];
  }

  Future<void> _bookmark(QuranTrilingualAyah verse) async {
    await widget.onVerseBookmark(verse, _surahName(_surahNumber));
  }

  Widget _buildThemePicker() {
    const labels = <_TrilingualTheme, String>{
      _TrilingualTheme.day: 'الزمرد الملكي',
      _TrilingualTheme.night: 'ليالي سماوية',
      _TrilingualTheme.warmPaper: 'العاج الملكي',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: labels.entries.map((entry) {
          final selected = entry.key == _theme;
          return Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: InkWell(
                onTap: () => _selectTheme(entry.key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
                  decoration: BoxDecoration(
                    color: selected ? _accent.withValues(alpha: 0.18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? _accent : _accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVerse(QuranTrilingualAyah verse) {
    final number = verse.ayahNumber.toString();
    return InkWell(
      onTap: () {
        _currentAyah = verse.ayahNumber;
        unawaited(_savePosition(_surahNumber, verse.ayahNumber));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
      key: _verseKeys.putIfAbsent(verse.ayahNumber, GlobalKey.new),
      margin: const EdgeInsets.fromLTRB(12, 7, 12, 7),
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 15),
      decoration: BoxDecoration(
        color: _primaryText.withValues(alpha: _theme == _TrilingualTheme.warmPaper ? 0.22 : 0.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.18),
                  border: Border.all(color: _accent.withValues(alpha: 0.8)),
                ),
                child: Text(
                  number,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'حفظ الآية',
                visualDensity: VisualDensity.compact,
                onPressed: () => _bookmark(verse),
                icon: Icon(Icons.bookmark_add_outlined, color: _accent, size: 21),
              ),
              IconButton(
                tooltip: 'نسخ الآية',
                visualDensity: VisualDensity.compact,
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: '${verse.arabic}\n\n${verse.french}\n\n${verse.english}'),
                ),
                icon: Icon(Icons.copy_rounded, color: _secondaryText, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              verse.arabic,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryText,
                fontSize: 28,
                height: 1.9,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: const ['Noto Naskh Arabic', 'serif'],
              ),
            ),
          ),
          const SizedBox(height: 15),
          Container(height: 1, color: _accent.withValues(alpha: 0.25)),
          const SizedBox(height: 11),
          _translationBlock('FRANÇAIS', verse.french),
          const SizedBox(height: 12),
          _translationBlock('ENGLISH', verse.english),
        ],
      ),
      ),
    );
  }

  Widget _translationBlock(String label, String text) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _accent,
              fontSize: 9,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.start,
            style: TextStyle(
              color: _secondaryText,
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: _accent, size: 42),
              const SizedBox(height: 12),
              Text(
                'تعذر تحميل السورة. تحقق من الاتصال أو أعد المحاولة.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _primaryText),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _loadSurah(_surahNumber, targetAyah: _currentAyah),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final surah = _surah!;
    return ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        itemCount: surah.verses.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 15),
              child: Column(
                children: [
                  Text(
                    _surahName(_surahNumber),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${surah.verses.length} آية  •  AR / FR / EN',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: _secondaryText, fontSize: 11),
                  ),
                ],
              ),
            );
          }
          return _buildVerse(surah.verses[index - 1]);
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(Icons.arrow_back_rounded, color: _primaryText),
                  ),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _surahNumber,
                        isExpanded: true,
                        dropdownColor: _background,
                        iconEnabledColor: _accent,
                        style: TextStyle(color: _primaryText, fontSize: 15, fontWeight: FontWeight.w800),
                        items: List.generate(114, (index) {
                          final number = index + 1;
                          return DropdownMenuItem<int>(
                            value: number,
                            child: Text('${number.toString()}  •  ${_surahName(number)}'),
                          );
                        }),
                        onChanged: _loading || _downloading
                            ? null
                            : (value) {
                                if (value != null) _loadSurah(value);
                              },
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'تنزيل القرآن كاملاً',
                    onPressed: _downloading ? null : _downloadAll,
                    icon: Icon(Icons.download_for_offline_outlined, color: _accent),
                  ),
                ],
              ),
            ),
            if (_downloading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _downloadedSurahs / 114,
                      color: _accent,
                      backgroundColor: _accent.withValues(alpha: 0.18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تنزيل السور: $_downloadedSurahs / 114',
                      style: TextStyle(color: _secondaryText, fontSize: 10),
                    ),
                  ],
                ),
              ),
            _buildThemePicker(),
            Expanded(child: _buildReaderBody()),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 9),
              child: Text(
                'النص العربي: QuranEnc / رواية حفص • '
                'English: Saheeh International v${QuranTrilingualDataSource.englishVersion} • '
                'Français: Rachid Maach v${QuranTrilingualDataSource.frenchVersion}',
                textAlign: TextAlign.center,
                style: TextStyle(color: _secondaryText.withValues(alpha: 0.75), fontSize: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
