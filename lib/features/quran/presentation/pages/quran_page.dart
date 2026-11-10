
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/quran_bookmark_local_data_source.dart';
import '../../data/datasources/quran_reading_progress_local_data_source.dart';
import '../../data/repositories/quran_bookmark_repository_impl.dart';
import '../../data/repositories/quran_reading_progress_repository_impl.dart';
import '../../domain/models/quran_bookmark.dart';
import '../../domain/models/quran_reading_progress.dart';
import '../../domain/repositories/quran_bookmark_repository.dart';
import '../../domain/repositories/quran_reading_progress_repository.dart';
import '../localization/quran_page_localization.dart';
import '../../data/datasources/quran_trilingual_data_source.dart';
import '../widgets/quran_trilingual_reader.dart';

class _SurahInfo {
  final String name;
  final int page;

  const _SurahInfo(this.name, this.page);
}

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage>
    with WidgetsBindingObserver {
  static const int _totalPages = 604;

  static const String _verseBookmarksKey =
      'mumin_pro_quran_verse_bookmarks_v1';

  static const Color _green = Color(0xFF075B46);
  static const Color _deepGreen = Color(0xFF063E31);
  static const Color _gold = Color(0xFFD8B66A);

  static const List<_SurahInfo> _surahs = [
    _SurahInfo('الفاتحة', 1),
    _SurahInfo('البقرة', 2),
    _SurahInfo('آل عمران', 50),
    _SurahInfo('النساء', 77),
    _SurahInfo('المائدة', 106),
    _SurahInfo('الأنعام', 128),
    _SurahInfo('الأعراف', 151),
    _SurahInfo('الأنفال', 177),
    _SurahInfo('التوبة', 187),
    _SurahInfo('يونس', 208),
    _SurahInfo('هود', 221),
    _SurahInfo('يوسف', 235),
    _SurahInfo('الرعد', 249),
    _SurahInfo('إبراهيم', 255),
    _SurahInfo('الحجر', 262),
    _SurahInfo('النحل', 267),
    _SurahInfo('الإسراء', 282),
    _SurahInfo('الكهف', 293),
    _SurahInfo('مريم', 305),
    _SurahInfo('طه', 312),
    _SurahInfo('الأنبياء', 322),
    _SurahInfo('الحج', 332),
    _SurahInfo('المؤمنون', 342),
    _SurahInfo('النور', 350),
    _SurahInfo('الفرقان', 359),
    _SurahInfo('الشعراء', 367),
    _SurahInfo('النمل', 377),
    _SurahInfo('القصص', 385),
    _SurahInfo('العنكبوت', 396),
    _SurahInfo('الروم', 404),
    _SurahInfo('لقمان', 411),
    _SurahInfo('السجدة', 415),
    _SurahInfo('الأحزاب', 418),
    _SurahInfo('سبأ', 428),
    _SurahInfo('فاطر', 434),
    _SurahInfo('يس', 440),
    _SurahInfo('الصافات', 446),
    _SurahInfo('ص', 453),
    _SurahInfo('الزمر', 458),
    _SurahInfo('غافر', 467),
    _SurahInfo('فصلت', 477),
    _SurahInfo('الشورى', 483),
    _SurahInfo('الزخرف', 489),
    _SurahInfo('الدخان', 496),
    _SurahInfo('الجاثية', 499),
    _SurahInfo('الأحقاف', 502),
    _SurahInfo('محمد', 507),
    _SurahInfo('الفتح', 511),
    _SurahInfo('الحجرات', 515),
    _SurahInfo('ق', 518),
    _SurahInfo('الذاريات', 520),
    _SurahInfo('الطور', 523),
    _SurahInfo('النجم', 526),
    _SurahInfo('القمر', 528),
    _SurahInfo('الرحمن', 531),
    _SurahInfo('الواقعة', 534),
    _SurahInfo('الحديد', 537),
    _SurahInfo('المجادلة', 542),
    _SurahInfo('الحشر', 545),
    _SurahInfo('الممتحنة', 549),
    _SurahInfo('الصف', 551),
    _SurahInfo('الجمعة', 553),
    _SurahInfo('المنافقون', 554),
    _SurahInfo('التغابن', 556),
    _SurahInfo('الطلاق', 558),
    _SurahInfo('التحريم', 560),
    _SurahInfo('الملك', 562),
    _SurahInfo('القلم', 564),
    _SurahInfo('الحاقة', 566),
    _SurahInfo('المعارج', 568),
    _SurahInfo('نوح', 570),
    _SurahInfo('الجن', 572),
    _SurahInfo('المزمل', 574),
    _SurahInfo('المدثر', 575),
    _SurahInfo('القيامة', 577),
    _SurahInfo('الإنسان', 578),
    _SurahInfo('المرسلات', 580),
    _SurahInfo('النبأ', 582),
    _SurahInfo('النازعات', 583),
    _SurahInfo('عبس', 585),
    _SurahInfo('التكوير', 586),
    _SurahInfo('الانفطار', 587),
    _SurahInfo('المطففين', 587),
    _SurahInfo('الانشقاق', 589),
    _SurahInfo('البروج', 590),
    _SurahInfo('الطارق', 591),
    _SurahInfo('الأعلى', 591),
    _SurahInfo('الغاشية', 592),
    _SurahInfo('الفجر', 593),
    _SurahInfo('البلد', 594),
    _SurahInfo('الشمس', 595),
    _SurahInfo('الليل', 595),
    _SurahInfo('الضحى', 596),
    _SurahInfo('الشرح', 596),
    _SurahInfo('التين', 597),
    _SurahInfo('العلق', 597),
    _SurahInfo('القدر', 598),
    _SurahInfo('البينة', 598),
    _SurahInfo('الزلزلة', 599),
    _SurahInfo('العاديات', 599),
    _SurahInfo('القارعة', 600),
    _SurahInfo('التكاثر', 600),
    _SurahInfo('العصر', 601),
    _SurahInfo('الهمزة', 601),
    _SurahInfo('الفيل', 601),
    _SurahInfo('قريش', 602),
    _SurahInfo('الماعون', 602),
    _SurahInfo('الكوثر', 602),
    _SurahInfo('الكافرون', 603),
    _SurahInfo('النصر', 603),
    _SurahInfo('المسد', 603),
    _SurahInfo('الإخلاص', 604),
    _SurahInfo('الفلق', 604),
    _SurahInfo('الناس', 604),
  ];

  static const List<int> _juzPages = [
    1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
    201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
    402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
  ];

  late final QuranBookmarkRepository _bookmarkRepository;
  late final QuranReadingProgressRepository _progressRepository;

  int _currentPage = 1;
  int _completedKhatmas = 0;

  Set<int> _completedPages = <int>{};
  Set<int> _bookmarks = <int>{};

  List<Map<String, dynamic>> _verseBookmarks = [];

  bool _isLoading = true;
  bool _isSaving = false;

  Timer? _saveDebounce;

  Future<void> _writeQueue = Future<void>.value();

  String? _loadedDailyDateKey;

  bool get _currentPageCompleted =>
      _completedPages.contains(_currentPage);

  String get _todayDateKey =>
      QuranReadingProgress.dateKeyFor(DateTime.now());

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _bookmarkRepository = QuranBookmarkRepositoryImpl(
      localDataSource: QuranBookmarkLocalDataSource(),
    );

    _progressRepository = QuranReadingProgressRepositoryImpl(
      localDataSource: QuranReadingProgressLocalDataSource(),
    );

    _restoreData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _flushCurrentPage();
    }

    if (state == AppLifecycleState.resumed) {
      _refreshTodayPages();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _saveDebounce?.cancel();
    _saveDebounce = null;

    if (!_isLoading) {
      unawaited(_savePage(_currentPage));
    }

    super.dispose();
  }

  bool _isValidPage(int page) =>
      page >= 1 && page <= _totalPages;

  Set<int> _validPages(Iterable<int> pages) {
    return pages.where(_isValidPage).toSet();
  }

  Future<void> _queueWrite(
    Future<void> Function() operation,
  ) {
    final nextWrite = _writeQueue
        .catchError((Object _) {})
        .then<void>((_) async {
      await operation();
    });

    _writeQueue = nextWrite;
    return nextWrite;
  }

  Future<void> _restoreData() async {
    try {
      final results = await Future.wait<Object>([
        _progressRepository.getProgress(),
        _bookmarkRepository.getBookmarks(),
      ]);

      final progress = results[0] as QuranReadingProgress;
      final bookmarks = results[1] as List<QuranBookmark>;

      final preferences = await SharedPreferences.getInstance();
      final storedVerses =
          preferences.getStringList(_verseBookmarksKey) ?? [];

      final validVerses = <Map<String, dynamic>>[];

      for (final entry in storedVerses) {
        try {
          final decoded = jsonDecode(entry);

          if (decoded is Map<String, dynamic>) {
            final sura = decoded['sura'];
            final aya = decoded['aya'];
            final page = decoded['page'];
            final text = decoded['text'];

            if (sura is int &&
                aya is int &&
                sura >= 1 &&
                sura <= 114 &&
                aya >= 1 &&
                page is int &&
                _isValidPage(page) &&
                text is String) {
              validVerses.add(decoded);
            }
          }
        } catch (_) {
          continue;
        }
      }

      if (!mounted) return;

      setState(() {
        _currentPage =
            progress.lastReadPage.clamp(1, _totalPages).toInt();

        _completedPages = _validPages(progress.completedPages);

        _completedKhatmas = progress.completedKhatmas < 0
            ? 0
            : progress.completedKhatmas;

        _loadedDailyDateKey = progress.dailyDateKey;

        _bookmarks = bookmarks
            .map((bookmark) => bookmark.pageNumber)
            .where(_isValidPage)
            .toSet();

        _verseBookmarks = validVerses;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
          QuranPageLocalization.text(
            context,
            'quran_saved_reading_data_error',
          ),
        );
    }
  }

  Future<void> _refreshTodayPages() async {
    if (_isLoading || !mounted) return;

    final dateKey = _todayDateKey;

    if (_loadedDailyDateKey == dateKey) return;

    try {
      await _queueWrite(() async {
        final progress = await _progressRepository.getProgress(
          date: DateTime.now(),
        );

        if (!mounted) return;

        setState(() {
          _loadedDailyDateKey = progress.dailyDateKey;
        });
      });
    } catch (_) {
      _showMessage(
          QuranPageLocalization.text(
            context,
            'quran_daily_reading_update_error',
          ),
        );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    final localizedMessage = QuranPageLocalization.feedback(
      context,
      message,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(localizedMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _deepGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  Future<void> _savePage(int page) async {
    final safePage = page.clamp(1, _totalPages).toInt();

    try {
      await _queueWrite(() async {
        final current = await _progressRepository.getProgress(
          date: DateTime.now(),
        );

        final updated = current.copyWith(
          lastReadPage: safePage,
        );

        await _progressRepository.saveProgress(updated);
      });
    } catch (_) {
      _showMessage(
          QuranPageLocalization.text(
            context,
            'quran_reading_position_save_error',
          ),
        );
    }
  }

  void _flushCurrentPage() {
    _saveDebounce?.cancel();
    _saveDebounce = null;

    if (!_isLoading) {
      unawaited(_savePage(_currentPage));
    }
  }

  void _selectPage(
    int page, {
    bool saveImmediately = false,
  }) {
    if (!_isValidPage(page) || _isLoading) return;

    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
    }

    _saveDebounce?.cancel();
    _saveDebounce = null;

    if (saveImmediately) {
      unawaited(_savePage(page));
      return;
    }

    _saveDebounce = Timer(
      const Duration(milliseconds: 450),
      () {
        _saveDebounce = null;

        if (mounted && !_isLoading) {
          unawaited(_savePage(_currentPage));
        }
      },
    );
  }

  Future<void> _markCurrentPageRead() async {
    if (_currentPageCompleted || _isSaving || _isLoading) return;

    final pageToMark = _currentPage;

    setState(() {
      _isSaving = true;
    });

    var khatmaFinished = false;
    var resultingKhatmas = _completedKhatmas;

    try {
      await _queueWrite(() async {
        final latest = await _progressRepository.getProgress(
          date: DateTime.now(),
        );

        final completed = _validPages(latest.completedPages);
        final today = _validPages(latest.dailyPages);

        if (completed.contains(pageToMark)) {
          if (!mounted) return;

          setState(() {
            _completedPages = completed;
            _completedKhatmas = latest.completedKhatmas;
            _loadedDailyDateKey = latest.dailyDateKey;
          });

          return;
        }

        completed.add(pageToMark);
        today.add(pageToMark);

        khatmaFinished = completed.length >= _totalPages;

        resultingKhatmas = latest.completedKhatmas < 0
            ? 0
            : latest.completedKhatmas;

        if (khatmaFinished) {
          resultingKhatmas++;
          completed.clear();
        }

        final updated = latest.copyWith(
          lastReadPage: pageToMark,
          completedPages: completed,
          completedKhatmas: resultingKhatmas,
          dailyPages: today,
          dailyDateKey: latest.dailyDateKey,
        );

        await _progressRepository.saveProgress(updated);

        if (!mounted) return;

        setState(() {
          _completedPages = completed;
          _completedKhatmas = resultingKhatmas;
          _loadedDailyDateKey = updated.dailyDateKey;
        });
      });

      if (!mounted) return;

      if (khatmaFinished) {
        await _showKhatmaDialog(resultingKhatmas);
      } else {
        _showMessage(
          QuranPageLocalization.text(
            context,
            'quran_page_marked_read',
            parameters: <String, Object?>{
              'page': pageToMark,
            },
          ),
        );
      }
    } catch (_) {
      _showMessage(
          QuranPageLocalization.text(
            context,
            'quran_page_mark_read_error',
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _undoCurrentPageRead() async {
    if (!_currentPageCompleted || _isSaving || _isLoading) return;

    final pageToUndo = _currentPage;

    setState(() {
      _isSaving = true;
    });

    try {
      await _queueWrite(() async {
        final latest = await _progressRepository.getProgress(
          date: DateTime.now(),
        );

        final completed = _validPages(latest.completedPages)
          ..remove(pageToUndo);

        final today = _validPages(latest.dailyPages)
          ..remove(pageToUndo);

        final updated = latest.copyWith(
          lastReadPage: _currentPage,
          completedPages: completed,
          dailyPages: today,
          dailyDateKey: latest.dailyDateKey,
        );

        await _progressRepository.saveProgress(updated);

        if (!mounted) return;

        setState(() {
          _completedPages = completed;
          _loadedDailyDateKey = updated.dailyDateKey;
        });
      });

      if (mounted) {
        _showMessage(
          QuranPageLocalization.text(
            context,
            'quran_page_read_mark_removed',
          ),
        );
      }
    } catch (_) {
      _showMessage(
          QuranPageLocalization.text(
            context,
            'quran_reading_record_update_error',
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showKhatmaDialog(int count) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDark =
            Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF1B2821)
              : const Color(0xFFFFFCF3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.emoji_events_rounded,
            size: 48,
            color: _gold,
          ),
          title: Text(
            QuranPageLocalization.text(
              dialogContext,
              'quran_khatma_congratulations',
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            QuranPageLocalization.text(
              dialogContext,
              'quran_khatma_completion_message',
              parameters: <String, Object?>{
                'count': count,
              },
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _green,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                QuranPageLocalization.text(
                  dialogContext,
                  'quran_praise_allah',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTrilingualVerseBookmark(
    QuranTrilingualAyah verse,
    String surahName,
  ) async {
    if (verse.surahNumber < 1 ||
        verse.surahNumber > 114 ||
        verse.ayahNumber < 1 ||
        verse.arabic.isEmpty) {
      _showMessage(
        QuranPageLocalization.text(context, 'quran_invalid_ayah_data'),
      );
      return;
    }

    final entry = <String, dynamic>{
      'sura': verse.surahNumber,
      'aya': verse.ayahNumber,
      'page': _currentPage,
      'text': verse.arabic,
      'suraName': surahName,
      'layout': 'trilingual',
    };

    try {
      await _queueWrite(() async {
        final preferences = await SharedPreferences.getInstance();
        final entries =
            preferences.getStringList(_verseBookmarksKey) ?? [];
        final alreadySaved = _verseBookmarks.any(
          (item) =>
              item['sura'] == verse.surahNumber &&
              item['aya'] == verse.ayahNumber,
        );

        if (alreadySaved) {
          if (mounted) {
            _showMessage(
              QuranPageLocalization.text(context, 'quran_ayah_already_saved'),
            );
          }
          return;
        }

        entries.add(jsonEncode(entry));
        final saved = await preferences.setStringList(
          _verseBookmarksKey,
          entries,
        );
        if (!saved) {
          throw StateError('Verse bookmark could not be saved');
        }
        if (!mounted) return;
        setState(() => _verseBookmarks.add(entry));
        _showMessage(
          QuranPageLocalization.text(context, 'quran_ayah_saved'),
        );
      });
    } catch (_) {
      _showMessage(
        QuranPageLocalization.text(context, 'quran_ayah_save_error'),
      );
    }
  }

  Future<void> _removeVerseBookmark(
    Map<String, dynamic> verse,
  ) async {
    try {
      await _queueWrite(() async {
        final preferences = await SharedPreferences.getInstance();

        final entries =
            preferences.getStringList(_verseBookmarksKey) ?? [];

        entries.removeWhere((entry) {
          try {
            final decoded = jsonDecode(entry);

            return decoded is Map &&
                decoded['sura'] == verse['sura'] &&
                decoded['aya'] == verse['aya'];
          } catch (_) {
            return false;
          }
        });

        await preferences.setStringList(
          _verseBookmarksKey,
          entries,
        );

        if (!mounted) return;

        setState(() {
          _verseBookmarks.removeWhere(
            (item) =>
                item['sura'] == verse['sura'] &&
                item['aya'] == verse['aya'],
          );
        });
      });

      if (mounted) {
        _showMessage(
          QuranPageLocalization.text(
            context,
            'quran_ayah_bookmark_removed',
          ),
        );
      }
    } catch (_) {
      _showMessage(
          QuranPageLocalization.text(
            context,
            'quran_ayah_bookmark_remove_error',
          ),
        );
    }
  }

  
  Future<void> _openVerseBookmarks() async {
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verses = List<Map<String, dynamic>>.from(_verseBookmarks);

    final selectedPage = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BottomSheetShell(
          title: QuranPageLocalization.text(
            context,
            'quran_saved_verses_title',
          ),
          isDark: isDark,
          child: verses.isEmpty
              ? _EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: QuranPageLocalization.text(
                    context,
                    'quran_saved_verses_empty_title',
                  ),
                  subtitle: QuranPageLocalization.text(
                    context,
                    'quran_saved_verses_empty_hint',
                  ),
                )
              : ListView.separated(
                  itemCount: verses.length,
                  separatorBuilder: (_, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final verse = verses[index];

                    final suraName =
                        verse['suraName'] as String? ?? '';
                    final aya = verse['aya'] as int;
                    final page = verse['page'] as int;
                    final verseText =
                        verse['text'] as String? ?? '';

                    return ListTile(
                      leading: const Icon(
                        Icons.bookmark_rounded,
                        color: _gold,
                      ),
                      title: Text(
                        '$suraName - '
                        '${QuranPageLocalization.text(context, 'quran_ayah_number')} '
                        '$aya',
                        textDirection: TextDirection.rtl,
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if (verseText.isNotEmpty)
                            Text(
                              verseText,
                              textDirection: TextDirection.rtl,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            '${QuranPageLocalization.text(context, 'quran_page_number')} $page',
                          ),
                        ],
                      ),
                      onTap: () =>
                          Navigator.pop(sheetContext, page),
                      trailing: IconButton(
                        tooltip: QuranPageLocalization.text(
                          context,
                          'quran_delete',
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                        onPressed: () async {
                          await _removeVerseBookmark(verse);

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }

                          if (mounted) {
                            await _openVerseBookmarks();
                          }
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );

    if (selectedPage != null && mounted) {
      _selectPage(
        selectedPage,
        saveImmediately: true,
      );
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isLoading || _isSaving) return;

    final page = _currentPage;

    try {
      await _queueWrite(() async {
        final existing = await _bookmarkRepository.getBookmarks();

        final exists = existing.any(
          (bookmark) => bookmark.pageNumber == page,
        );

        if (exists) {
          await _bookmarkRepository.removeBookmark(page);
        } else {
          await _bookmarkRepository.addBookmark(
            QuranBookmark.fromPage(page),
          );
        }

        final latest = await _bookmarkRepository.getBookmarks();

        if (!mounted) return;

        setState(() {
          _bookmarks = latest
              .map((bookmark) => bookmark.pageNumber)
              .where(_isValidPage)
              .toSet();
        });

        _showMessage(
          _bookmarks.contains(page)
              ? QuranPageLocalization.text(
                  context,
                  'quran_page_bookmark_saved',
                )
              : QuranPageLocalization.text(
                  context,
                  'quran_page_bookmark_removed',
                ),
        );
      });
    } catch (_) {
      _showMessage(
          QuranPageLocalization.text(
            context,
            'quran_page_bookmark_save_error',
          ),
        );
    }
  }

  Future<void> _removeBookmark(int page) async {
    if (_isLoading || !_isValidPage(page)) return;

    try {
      await _queueWrite(() async {
        await _bookmarkRepository.removeBookmark(page);

        final latest = await _bookmarkRepository.getBookmarks();

        if (!mounted) return;

        setState(() {
          _bookmarks = latest
              .map((bookmark) => bookmark.pageNumber)
              .where(_isValidPage)
              .toSet();
        });
      });
    } catch (_) {
      _showMessage(
          QuranPageLocalization.text(
            context,
            'quran_page_bookmark_remove_error',
          ),
        );
    }
  }

  Future<void> _openBookmarks() async {
    if (_isLoading || !mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = _bookmarks.toList()..sort();

    final selectedPage = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BottomSheetShell(
          title: QuranPageLocalization.text(
            context,
            'quran_bookmarks_title',
          ),
          isDark: isDark,
          child: pages.isEmpty
              ? _EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: QuranPageLocalization.text(
                    context,
                    'quran_bookmarks_empty_title',
                  ),
                  subtitle: QuranPageLocalization.text(
                    context,
                    'quran_bookmarks_empty_hint',
                  ),
                )
              : ListView.separated(
                  itemCount: pages.length,
                  separatorBuilder: (_, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    final isCurrentPage = page == _currentPage;

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0x1FD8B66A),
                        child: Icon(
                          Icons.bookmark_rounded,
                          color: _gold,
                        ),
                      ),
                      title: Text(
                        '${QuranPageLocalization.text(context, 'quran_page_number')} $page',
                      ),
                      subtitle: Text(
                        QuranPageLocalization.text(
                          context,
                          isCurrentPage
                              ? 'quran_current_page'
                              : 'quran_open_page',
                        ),
                      ),
                      onTap: () => Navigator.pop(sheetContext, page),
                      trailing: IconButton(
                        tooltip: QuranPageLocalization.text(
                          context,
                          'quran_delete_bookmark',
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                        onPressed: () async {
                          await _removeBookmark(page);

                          if (!sheetContext.mounted) return;

                          Navigator.pop(sheetContext);

                          if (mounted) {
                            await _openBookmarks();
                          }
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );

    if (selectedPage != null && mounted) {
      _selectPage(selectedPage, saveImmediately: true);
    }
  }
  
  
Future<int?> _goToPage() async {
    if (_isLoading || !mounted) return null;

    final controller = TextEditingController(
      text: _currentPage.toString(),
    );

    int? selectedPage;

    try {
      selectedPage = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              QuranPageLocalization.text(
                context,
                'quran_go_to_page_title',
              ),
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: QuranPageLocalization.text(
                  context,
                  'quran_enter_page_number',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  QuranPageLocalization.text(
                    context,
                    'quran_close',
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                ),
                onPressed: () {
                  final page = int.tryParse(
                    controller.text.trim(),
                  );

                  if (page == null || !_isValidPage(page)) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          QuranPageLocalization.text(
                            context,
                            'quran_invalid_page',
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext, page);
                },
                child: Text(
                  QuranPageLocalization.text(
                    context,
                    'quran_go_to_page',
                  ),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }

    
   return selectedPage;
  }
  
  Future<void> _openIndex() async {
    if (_isLoading || !mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedPage = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DefaultTabController(
          length: 2,
          child: _BottomSheetShell(
            title: QuranPageLocalization.text(
              context,
              'quran_index_title',
            ),
            isDark: isDark,
            child: Column(
              children: [
                TabBar(
                  labelColor: isDark ? _gold : _green,
                  unselectedLabelColor:
                      isDark ? Colors.white60 : Colors.black54,
                  indicatorColor: _gold,
                  tabs: [
                    Tab(
                      text: QuranPageLocalization.text(
                        context,
                        'quran_surahs_tab',
                      ),
                    ),
                    Tab(
                      text: QuranPageLocalization.text(
                        context,
                        'quran_juz_tab',
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView.separated(
                        itemCount: _surahs.length,
                        separatorBuilder: (_, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final surah = _surahs[index];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0x1FD8B66A),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: _gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              QuranPageLocalization.surahName(
                                context,
                                index + 1,
                              ),
                              textDirection:
                                  QuranPageLocalization.textDirectionOf(
                                context,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Text(
                              QuranPageLocalization.text(
                                context,
                                'quran_juz_page',
                                parameters: {
                                  'page': surah.page,
                                },
                              ),
                            ),
                            onTap: () => Navigator.pop(
                              sheetContext,
                              surah.page,
                            ),
                          );
                        },
                      ),
                      ListView.separated(
                        itemCount: _juzPages.length,
                        separatorBuilder: (_, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final juzNumber = index + 1;
                          final page = _juzPages[index];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0x1FD8B66A),
                              child: Text(
                                '$juzNumber',
                                style: const TextStyle(
                                  color: _gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              QuranPageLocalization.text(
                                context,
                                'quran_juz_number',
                                parameters: {
                                  'number': juzNumber,
                                },
                              ),
                            ),
                            trailing: Text(
                              QuranPageLocalization.text(
                                context,
                                'quran_juz_page',
                                parameters: {
                                  'page': page,
                                },
                              ),
                            ),
                            onTap: () => Navigator.pop(
                              sheetContext,
                              page,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedPage != null && mounted) {
      _selectPage(selectedPage, saveImmediately: true);
    }
  }

  Future<void> _openFullReader() async {
    if (_isLoading || !mounted) return;

    var initialSurah = 1;
    for (var index = 0; index < _surahs.length; index++) {
      if (_surahs[index].page <= _currentPage) {
        initialSurah = index + 1;
      } else {
        break;
      }
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => QuranTrilingualReader(
          initialSurah: initialSurah,
          initialAyah: 1,
          surahNames: QuranPageLocalization.surahNames(context),
          onClose: () => Navigator.of(_).pop(),
          onVerseBookmark: _saveTrilingualVerseBookmark,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _openSurahFromNavigation(int page) {
  if (_isLoading || !_isValidPage(page)) return;

  _selectPage(
    page,
    saveImmediately: true,
  );

  _openFullReader();
}
  
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isArabic = QuranPageLocalization.isArabic(context);
  final background = isDark
      ? const Color(0xFF101B16)
      : const Color(0xFFF5F4ED);
  final foreground = isDark
      ? const Color(0xFFE8DFC9)
      : _deepGreen;
  final direction = QuranPageLocalization.textDirectionOf(context);

  return Directionality(
    textDirection: direction,
    child: Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          QuranPageLocalization.text(context, 'quran_surahs_tab'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            tooltip: QuranPageLocalization.text(
              context,
              'quran_saved_verses',
            ),
            onPressed: _isLoading ? null : _openVerseBookmarks,
            icon: const Icon(Icons.bookmark_outline_rounded),
          ),
          IconButton(
            tooltip: QuranPageLocalization.text(
              context,
              'quran_bookmarks',
            ),
            onPressed: _isLoading ? null : _openBookmarks,
            icon: const Icon(Icons.bookmarks_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _gold),
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
              itemCount: _surahs.length,
              separatorBuilder: (_, index) => Divider(
                height: 1,
                indent: 72,
                color: _gold.withValues(alpha: 0.20),
              ),
              itemBuilder: (itemContext, index) {
                final surah = _surahs[index];
                final localizedName =
                    QuranPageLocalization.surahName(
                  context,
                  index + 1,
                );

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: () => _openSurahFromNavigation(
                      surah.page,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 43,
                            height: 43,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _gold.withValues(
                                alpha: isDark ? 0.13 : 0.17,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _gold.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic
                                      ? surah.name
                                      : localizedName,
                                  textDirection: isArabic
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: foreground,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (!isArabic) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    surah.name,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      color: foreground.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: _gold.withValues(alpha: 0.9),
                                size: 19,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                QuranPageLocalization.text(
                                  context,
                                  'quran_juz_page',
                                  parameters: {
                                    'page': surah.page,
                                  },
                                ),
                                style: TextStyle(
                                  color: foreground.withValues(
                                    alpha: 0.62,
                                  ),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    ),
  );
}
}

enum _QuranReaderTheme {
  day,
  night,
  warmPaper,
}

class _BottomSheetShell extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget child;

  const _BottomSheetShell({
    required this.title,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.76,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B2821)
            : const Color(0xFFFFFCF3),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(27),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFFD8B66A),
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
