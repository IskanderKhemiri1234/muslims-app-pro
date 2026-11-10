import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/quran_trilingual_data_source.dart';
import '../localization/quran_page_localization.dart';

enum _TrilingualTheme { day, night, warmPaper }

class QuranTrilingualReader extends StatefulWidget {
  const QuranTrilingualReader({
    super.key,
    required this.initialSurah,
    required this.initialAyah,
    required this.surahNames,
    required this.onClose,
    required this.onVerseBookmark,
    required this.surahStartPages,
    required this.onPageChanged,
    required this.onTogglePageBookmark,
    required this.onMarkPageRead,
    required this.onUndoPageRead,
    required this.onOpenIndex,
    required this.onGoToPage,
  });

  final int initialSurah;
  final int initialAyah;
  final List<String> surahNames;
  final VoidCallback onClose;
  final Future<void> Function(QuranTrilingualAyah verse, String surahName)
      onVerseBookmark;
  final List<int> surahStartPages;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function() onTogglePageBookmark;
  final Future<void> Function() onMarkPageRead;
  final Future<void> Function() onUndoPageRead;
  final Future<int?> Function() onOpenIndex;
  final Future<int?> Function() onGoToPage;

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
  String? _error;
  String _languageCode = 'ar';

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

  Future<void> _loadSurah(
    int number, {
    int targetAyah = 1,
    bool updateParentPage = false,
  }) async {
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
      final safeAyah = targetAyah.clamp(1, surah.verses.length);
      setState(() {
        _surah = surah;
        _loading = false;
        _currentAyah = safeAyah;
      });
      await _savePosition(number, safeAyah);
      if (updateParentPage && number <= widget.surahStartPages.length) {
        widget.onPageChanged(widget.surahStartPages[number - 1]);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revealAyah(safeAyah);
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
    final verseContext = _verseKeys[ayah]?.currentContext;
    if (verseContext == null) {
      if (!_scrollController.hasClients) return;
      final estimatedOffset = (ayah - 1) * 390.0;
      final target = estimatedOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(target);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _verseKeys[ayah]?.currentContext != null) {
          _revealAyah(ayah);
        }
      });
      return;
    }
    Scrollable.ensureVisible(
      verseContext,
      alignment: 0.08,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _recordVisibleAyah() {
    if (!_scrollController.hasClients || _verseKeys.isEmpty) return;
    var nearestAyah = _currentAyah;
    var nearestDistance = double.infinity;
    for (final entry in _verseKeys.entries) {
      final renderObject = entry.value.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) continue;
      final top = renderObject.localToGlobal(Offset.zero).dy;
      final distance = (top - 150).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestAyah = entry.key;
      }
    }
    if (nearestAyah != _currentAyah) {
      _currentAyah = nearestAyah;
      unawaited(_savePosition(_surahNumber, nearestAyah));
    }
  }

  Future<void> _selectTheme(_TrilingualTheme theme) async {
    setState(() => _theme = theme);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, theme.name);
  }

  String _text(String key, {Map<String, Object?> parameters = const {}}) =>
      QuranPageLocalization.textForLanguage(
        _languageCode,
        key,
        parameters: parameters,
      );

  String _surahName(int number) {
    if (number < 1 || number > widget.surahNames.length) {
      return 'Surah $number';
    }
    return widget.surahNames[number - 1];
  }

  Future<void> _bookmark(QuranTrilingualAyah verse) async {
    await widget.onVerseBookmark(verse, _surahName(_surahNumber));
  }

  int _surahForPage(int page) {
    var selected = 1;
    for (var index = 0; index < widget.surahStartPages.length; index++) {
      if (widget.surahStartPages[index] <= page) {
        selected = index + 1;
      } else {
        break;
      }
    }
    return selected;
  }

  Future<void> _handleReaderAction(String action) async {
    switch (action) {
      case 'bookmark':
        await widget.onTogglePageBookmark();
        return;
      case 'mark_read':
        await widget.onMarkPageRead();
        return;
      case 'undo_read':
        await widget.onUndoPageRead();
        return;
      case 'index':
        final page = await widget.onOpenIndex();
        if (page != null && mounted) {
          await _loadSurah(_surahForPage(page));
        }
        return;
      case 'go_to_page':
        final page = await widget.onGoToPage();
        if (page != null && mounted) {
          await _loadSurah(_surahForPage(page));
        }
        return;
    }
  }

  Widget _buildThemePicker() {
    const labels = <_TrilingualTheme, String>{
      _TrilingualTheme.day: 'quran_theme_day',
      _TrilingualTheme.night: 'quran_theme_night',
      _TrilingualTheme.warmPaper: 'quran_theme_warm_paper',
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
                    _text(entry.value),
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
                tooltip: _text('quran_reader_bookmark_verse'),
                visualDensity: VisualDensity.compact,
                onPressed: () => _bookmark(verse),
                icon: Icon(Icons.bookmark_add_outlined, color: _accent, size: 21),
              ),
              IconButton(
                tooltip: _text('quran_reader_copy_verse'),
                visualDensity: VisualDensity.compact,
                onPressed: () => Clipboard.setData(
                  ClipboardData(
                    text: '${verse.arabic}\n\n${verse.french}\n${verse.frenchFootnotes}\n\n${verse.english}\n${verse.englishFootnotes}',
                  ),
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
                fontFamily: 'MuminHafs',
                fontFamilyFallback: const ['Noto Naskh Arabic', 'serif'],
              ),
            ),
          ),
          const SizedBox(height: 15),
          Container(height: 1, color: _accent.withValues(alpha: 0.25)),
          const SizedBox(height: 11),
          _translationBlock(_text('quran_reader_french_label'), verse.french),
          if (verse.frenchFootnotes.isNotEmpty) ...[
            const SizedBox(height: 6),
            _translationBlock(
              _text('quran_reader_french_notes'),
              verse.frenchFootnotes,
            ),
          ],
          const SizedBox(height: 12),
          _translationBlock(_text('quran_reader_english_label'), verse.english),
          if (verse.englishFootnotes.isNotEmpty) ...[
            const SizedBox(height: 6),
            _translationBlock(
              _text('quran_reader_english_notes'),
              verse.englishFootnotes,
            ),
          ],
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
                _text('quran_reader_load_failed'),
                textAlign: TextAlign.center,
                style: TextStyle(color: _primaryText),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _loadSurah(_surahNumber, targetAyah: _currentAyah),
                child: Text(_text('quran_reader_retry')),
              ),
            ],
          ),
        ),
      );
    }

    final surah = _surah!;
    return NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        _recordVisibleAyah();
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        itemCount: surah.verses.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final verseCount = _text(
              'quran_reader_verse_count',
              parameters: {'count': surah.verses.length},
            );
            final languageLabels = _text('quran_reader_languages');
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
                    '$verseCount  •  $languageLabels',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: _secondaryText, fontSize: 11),
                  ),
                ],
              ),
            );
          }
          return _buildVerse(surah.verses[index - 1]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _languageCode = QuranPageLocalization.languageCodeOf(context);
    final arabicSource = _text('quran_reader_arabic_source');
    final englishSource = _text('quran_reader_english_source');
    final frenchSource = _text('quran_reader_french_source');
    final translationDisclaimer = _text('quran_translation_disclaimer');
    return Scaffold(
      backgroundColor: _background,
      body: CustomPaint(
        painter: _TrilingualBackgroundPainter(theme: _theme),
        child: SafeArea(
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
                        onChanged: _loading
                            ? null
                            : (value) {
                                if (value != null) {
                                  _loadSurah(value, updateParentPage: true);
                                }
                              },
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: _accent),
                    onSelected: (value) => unawaited(_handleReaderAction(value)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'bookmark',
                        child: Text(_text('quran_save_page_bookmark')),
                      ),
                      PopupMenuItem(
                        value: 'mark_read',
                        child: Text(_text('quran_mark_read')),
                      ),
                      PopupMenuItem(
                        value: 'undo_read',
                        child: Text(_text('quran_undo')),
                      ),
                      PopupMenuItem(
                        value: 'index',
                        child: Text(_text('quran_index_title')),
                      ),
                      PopupMenuItem(
                        value: 'go_to_page',
                        child: Text(_text('quran_go_to_short')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildThemePicker(),
            Expanded(child: _buildReaderBody()),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$arabicSource • '
                    '$englishSource v${QuranTrilingualDataSource.englishVersion} • '
                    '$frenchSource v${QuranTrilingualDataSource.frenchVersion}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _secondaryText.withValues(alpha: 0.75),
                      fontSize: 8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    translationDisclaimer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _secondaryText.withValues(alpha: 0.68),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}


class _TrilingualBackgroundPainter extends CustomPainter {
  const _TrilingualBackgroundPainter({required this.theme});

  final _TrilingualTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = switch (theme) {
      _TrilingualTheme.day => (
          base: const Color(0xFF061D18),
          middle: const Color(0xFF0B382D),
          deep: const Color(0xFF031510),
          accent: const Color(0xFFD9BA75),
          glow: const Color(0xFF8DB5A3),
        ),
      _TrilingualTheme.night => (
          base: const Color(0xFF050D1B),
          middle: const Color(0xFF142641),
          deep: const Color(0xFF07111F),
          accent: const Color(0xFFC6D4E8),
          glow: const Color(0xFF7795B5),
        ),
      _TrilingualTheme.warmPaper => (
          base: const Color(0xFFF1E5C9),
          middle: const Color(0xFFE3D0A7),
          deep: const Color(0xFFC9AE7B),
          accent: const Color(0xFF806039),
          glow: const Color(0xFFB18B55),
        ),
    };

    final bounds = Offset.zero & size;
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [palette.base, palette.middle, palette.deep],
        stops: const [0, 0.56, 1],
      ).createShader(bounds);
    canvas.drawRect(bounds, basePaint);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.glow.withValues(alpha: 0.16),
          palette.glow.withValues(alpha: 0.035),
          Colors.transparent,
        ],
        stops: const [0, 0.5, 1],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.35),
          radius: size.longestSide * 0.78,
        ),
      );
    canvas.drawRect(bounds, glowPaint);

    final borderPaint = Paint()
      ..color = palette.accent.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    final innerPaint = Paint()
      ..color = palette.glow.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
        const Radius.circular(20),
      ),
      borderPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(13, 13, size.width - 26, size.height - 26),
        const Radius.circular(16),
      ),
      innerPaint,
    );

    final motifPaint = Paint()
      ..color = palette.accent.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    void drawStar(Offset center, double radius) {
      final path = Path();
      for (var point = 0; point < 16; point++) {
        final angle = -math.pi / 2 + point * math.pi / 8;
        final currentRadius = point.isEven ? radius : radius * 0.48;
        final position = Offset(
          center.dx + math.cos(angle) * currentRadius,
          center.dy + math.sin(angle) * currentRadius,
        );
        if (point == 0) {
          path.moveTo(position.dx, position.dy);
        } else {
          path.lineTo(position.dx, position.dy);
        }
      }
      path.close();
      canvas.drawPath(path, motifPaint);
    }

    for (var y = 80.0; y < size.height - 70; y += 138) {
      drawStar(Offset(25, y), 10);
      drawStar(Offset(size.width - 25, y), 10);
    }
  }

  @override
  bool shouldRepaint(covariant _TrilingualBackgroundPainter oldDelegate) =>
      oldDelegate.theme != theme;
}
