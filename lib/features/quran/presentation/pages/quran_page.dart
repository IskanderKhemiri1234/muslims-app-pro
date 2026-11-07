
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quran_madina_flutter/quran_madina_flutter.dart';
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
  static const int _dailyTarget = 5;

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
  Set<int> _todayPages = <int>{};
  Set<int> _bookmarks = <int>{};

  List<Map<String, dynamic>> _verseBookmarks = [];

  bool _isLoading = true;
  bool _isSaving = false;

  Timer? _saveDebounce;

  Future<void> _writeQueue = Future<void>.value();

  String? _loadedDailyDateKey;

  double get _khatmaProgress =>
      (_completedPages.length / _totalPages)
          .clamp(0.0, 1.0)
          .toDouble();

  double get _dailyProgress =>
      (_todayPages.length / _dailyTarget)
          .clamp(0.0, 1.0)
          .toDouble();

  bool get _currentPageCompleted =>
      _completedPages.contains(_currentPage);

  bool get _currentPageBookmarked =>
      _bookmarks.contains(_currentPage);

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
        _todayPages = _validPages(progress.dailyPages);

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

      _showMessage('تعذر تحميل بيانات القراءة المحفوظة');
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
          _todayPages = _validPages(progress.dailyPages);
          _loadedDailyDateKey = progress.dailyDateKey;
        });
      });
    } catch (_) {
      _showMessage('تعذر تحديث الورد اليومي');
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
      _showMessage('تعذر حفظ موضع القراءة');
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

  void _changePage(int amount) {
    final page =
        (_currentPage + amount).clamp(1, _totalPages).toInt();

    _selectPage(page, saveImmediately: true);
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
            _todayPages = today;
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
          _todayPages = today;
          _completedKhatmas = resultingKhatmas;
          _loadedDailyDateKey = updated.dailyDateKey;
        });
      });

      if (!mounted) return;

      if (khatmaFinished) {
        await _showKhatmaDialog(resultingKhatmas);
      } else {
        _showMessage('تم تسجيل قراءة الصفحة $pageToMark');
      }
    } catch (_) {
      _showMessage('تعذر حفظ تقدم القراءة. حاول مرة أخرى.');
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
          _todayPages = today;
          _loadedDailyDateKey = updated.dailyDateKey;
        });
      });

      if (mounted) {
        _showMessage('تم إلغاء تسجيل قراءة الصفحة');
      }
    } catch (_) {
      _showMessage('تعذر تحديث سجل القراءة');
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
          title: const Text(
            'مبارك! أتممت ختمة القرآن',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'الحمد لله، أتممت قراءة صفحات المصحف الـ604. '
            'هذه ختمتك رقم $count.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _green,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('الحمد لله'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveVerseBookmark(
    QuranAyaSelection selection,
  ) async {
    if (selection.sura < 1 ||
        selection.sura > 114 ||
        selection.aya < 1) {
      _showMessage('بيانات الآية غير صالحة');
      return;
    }

    final page = selection.page ?? _currentPage;

    final entry = <String, dynamic>{
      'sura': selection.sura,
      'aya': selection.aya,
      'page': page,
      'text': selection.text,
      'suraName': selection.suraName,
      'layout': selection.layout,
    };

    try {
      await _queueWrite(() async {
        final preferences = await SharedPreferences.getInstance();

        final entries =
            preferences.getStringList(_verseBookmarksKey) ?? [];

        final alreadySaved = _verseBookmarks.any(
          (item) =>
              item['sura'] == selection.sura &&
              item['aya'] == selection.aya,
        );

        if (alreadySaved) {
          if (mounted) {
            _showMessage('هذه الآية محفوظة بالفعل');
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

        setState(() {
          _verseBookmarks.add(entry);
        });

        _showMessage(
          'تم حفظ الآية ${selection.aya} من سورة ${selection.suraName}',
        );
      });
    } catch (_) {
      _showMessage('تعذر حفظ الآية');
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
        _showMessage('تم حذف علامة الآية');
      }
    } catch (_) {
      _showMessage('تعذر حذف علامة الآية');
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
              ? 'تم حفظ الصفحة في العلامات المرجعية'
              : 'تم حذف العلامة المرجعية',
        );
      });
    } catch (_) {
      _showMessage('تعذر حفظ العلامة المرجعية');
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
      _showMessage('تعذر حذف العلامة المرجعية');
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

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _QuranFullScreenReader(
          initialPage: _currentPage,
          completedPages: _completedPages,
          bookmarkedPages: _bookmarks,
          onPageChanged: (page) {
            _selectPage(page, saveImmediately: true);
          },
          onTogglePageBookmark: _toggleBookmark,
          onMarkPageRead: _markCurrentPageRead,
          onUndoPageRead: _undoCurrentPageRead,
          onVerseAction: _saveVerseBookmark,
          onOpenIndex: _openIndex,
          onOpenPageBookmarks: _openBookmarks,
          onOpenVerseBookmarks: _openVerseBookmarks,
          onGoToPage: _goToPage,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  
  Widget _buildHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_green, _deepGreen],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _gold,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      QuranPageLocalization.text(
                        context,
                        'quran_title',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      QuranPageLocalization.text(
                        context,
                        'quran_madinah_mushaf',
                      ),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '604 ${QuranPageLocalization.text(context, 'quran_pages')}',
                style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                QuranPageLocalization.text(
                  context,
                  'quran_khatma_progress',
                ),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                '${(_khatmaProgress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _khatmaProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_gold),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.auto_stories_rounded,
                color: _gold,
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                '${_completedPages.length} '
                '${QuranPageLocalization.text(context, 'quran_pages_read')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '$_completedKhatmas '
                '${QuranPageLocalization.text(context, 'quran_completed_khatmas')}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCard(bool isDark) {
    final cardColor =
        isDark ? const Color(0xFF1B2A23) : Colors.white;

    final textColor = isDark
        ? const Color(0xFFE8DFC9)
        : const Color(0xFF26382C);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: _gold.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.today_rounded,
              color: _gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
Text(
  QuranPageLocalization.text(
    context,
    'quran_daily_reading',
  ),
  style: TextStyle(
    color: textColor,
    fontWeight: FontWeight.bold,
    fontSize: 13,
  ),
),

                const SizedBox(height: 4),
                
Text(
  '${_todayPages.length} '
  '${QuranPageLocalization.text(context, 'quran_of')} '
  '$_dailyTarget '
  '${QuranPageLocalization.text(context, 'quran_pages')}',
  style: TextStyle(
    color: textColor.withValues(alpha: 0.65),
    fontSize: 11,
  ),
),
              ],
            ),
          ),
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _dailyProgress,
                  strokeWidth: 4,
                  backgroundColor: _gold.withValues(alpha: 0.16),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_gold),
                ),
                Center(
                  child: Text(
                    '${(_dailyProgress * 100).round()}%',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildReaderPreview(bool isDark) {
    final pageColor = isDark
        ? const Color(0xFF202A23)
        : const Color(0xFFFFFCF3);

    final textColor = isDark
        ? const Color(0xFFE8DFC9)
        : const Color(0xFF26382C);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: _gold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: _green.withValues(
                alpha: isDark ? 0.35 : 0.07,
              ),
              border: Border(
                bottom: BorderSide(
                  color: _gold.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: _gold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${QuranPageLocalization.text(context, 'quran_page')} $_currentPage',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.open_in_full_rounded,
                  color: _gold,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  QuranPageLocalization.text(
                    context,
                    'quran_open_reader',
                  ),
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 165,
            child: InkWell(
              onTap: _openFullReader,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: 300,
                          maxHeight: 600,
                          child: SizedBox(
                            width: double.infinity,
                            child: QuranMadinaFlutter(
                              key: ValueKey('preview_$_currentPage'),
                              page: _currentPage,
                              bundled: true,
                              headless: true,
                              fontSize: 19,
                              textColor:
                                  isDark ? '#E8DFC9' : '#26382C',
                              backgroundColor:
                                  isDark ? '#202A23' : '#FFFCF3',
                              ayaActions: [
                                QuranAyaAction(
                                  id: 'save_ayah',
                                  title:
                                      QuranPageLocalization.text(
                                    context,
                                    'quran_save_verse',
                                  ),
                                ),
                              ],
                              onAyaAction: _saveVerseBookmark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 45,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            pageColor.withValues(alpha: 0),
                            pageColor,
                          ],
                        ),
                      ),
                      child: Text(
                        QuranPageLocalization.text(
                          context,
                          'quran_open_reader',
                        ),
                        style: const TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }  

  
  Widget _buildReaderControls(bool isDark) {
    final textColor = isDark ? Colors.white : _deepGreen;
    final isRtl = QuranPageLocalization.isArabic(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 13, 16, 18),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2A23) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _gold.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _currentPageCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: _currentPageCompleted ? _green : _gold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  QuranPageLocalization.text(
                    context,
                    _currentPageCompleted
                        ? 'quran_page_read'
                        : 'quran_mark_page_read',
                  ),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: _isSaving
                    ? null
                    : _currentPageCompleted
                        ? _undoCurrentPageRead
                        : _markCurrentPageRead,
                child: Text(
                  QuranPageLocalization.text(
                    context,
                    _currentPageCompleted
                        ? 'quran_undo'
                        : 'quran_mark_read',
                  ),
                  style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _green,
              inactiveTrackColor: _green.withValues(alpha: 0.15),
              thumbColor: _gold,
              overlayColor: _gold.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: _currentPage.toDouble(),
              min: 1,
              max: _totalPages.toDouble(),
              divisions: _totalPages - 1,
              onChanged: (value) => _selectPage(value.round()),
              onChangeEnd: (value) {
                _selectPage(
                  value.round(),
                  saveImmediately: true,
                );
              },
            ),
          ),
          Row(
            children: [
              const Text(
                '1',
                style: TextStyle(
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                QuranPageLocalization.text(
                  context,
                  'quran_page_position',
                  parameters: {
                    'page': _currentPage,
                    'total': _totalPages,
                  },
                ),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              const Text(
                '604',
                style: TextStyle(
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentPage > 1
                      ? () => _changePage(-1)
                      : null,
                  icon: Icon(
                    isRtl
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                  ),
                  label: Text(
                    QuranPageLocalization.text(
                      context,
                      'quran_previous',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side: BorderSide(
                      color: _green.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _currentPage < _totalPages
                      ? () => _changePage(1)
                      : null,
                  icon: Icon(
                    isRtl
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    QuranPageLocalization.text(
                      context,
                      'quran_next',
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _SmallAction(
                  icon: _currentPageBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_add_outlined,
                  label: QuranPageLocalization.text(
                    context,
                    _currentPageBookmarked
                        ? 'quran_remove_bookmark'
                        : 'quran_bookmark',
                  ),
                  onTap: _toggleBookmark,
                ),
              ),
              Expanded(
                child: _SmallAction(
                  icon: Icons.menu_book_rounded,
                  label: QuranPageLocalization.text(
                    context,
                    'quran_index',
                  ),
                  onTap: _openIndex,
                ),
              ),
              Expanded(
                child: _SmallAction(
                  icon: Icons.bookmarks_outlined,
                  label: QuranPageLocalization.text(
                    context,
                    'quran_saved_verses',
                  ),
                  onTap: _openVerseBookmarks,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final background = isDark
        ? const Color(0xFF101B16)
        : const Color(0xFFF3F5F0);

    final foreground = isDark
        ? const Color(0xFFE8DFC9)
        : _deepGreen;

    return Scaffold(
      backgroundColor: background,
      
appBar: AppBar(
  backgroundColor: background,
  foregroundColor: foreground,
  elevation: 0,
  centerTitle: true,
  title: Text(
    QuranPageLocalization.text(context, 'quran_title'),
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
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
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          _buildHeader(isDark),
                          _buildDailyCard(isDark),
                          _buildReaderPreview(isDark),
                          _buildReaderControls(isDark),
                        ],
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

class _QuranFullScreenReader extends StatefulWidget {
  final int initialPage;
  final Set<int> completedPages;
  final Set<int> bookmarkedPages;

  final ValueChanged<int> onPageChanged;
  final Future<void> Function() onTogglePageBookmark;
  final Future<void> Function() onMarkPageRead;
  final Future<void> Function() onUndoPageRead;
  final Future<void> Function(QuranAyaSelection) onVerseAction;

  final Future<void> Function() onOpenIndex;
  final Future<void> Function() onOpenPageBookmarks;
  final Future<void> Function() onOpenVerseBookmarks;
  final Future<int?> Function() onGoToPage;

  const _QuranFullScreenReader({
    required this.initialPage,
    required this.completedPages,
    required this.bookmarkedPages,
    required this.onPageChanged,
    required this.onTogglePageBookmark,
    required this.onMarkPageRead,
    required this.onUndoPageRead,
    required this.onVerseAction,
    required this.onOpenIndex,
    required this.onOpenPageBookmarks,
    required this.onOpenVerseBookmarks,
    required this.onGoToPage,
  });

  @override
  State<_QuranFullScreenReader> createState() =>
      _QuranFullScreenReaderState();
}

class _QuranFullScreenReaderState
    extends State<_QuranFullScreenReader> {
  static const int _totalPages = 604;

  static const String _themeStorageKey =
      'mumin_pro_quran_reader_theme_v1';

  static const Color _gold = Color(0xFFD8B66A);
  static const Color _emerald = Color(0xFF075B46);

  late int _currentPage;

  _QuranReaderTheme _readerTheme = _QuranReaderTheme.day;

  Offset? _pointerDownPosition;
  double? _sliderPreviewPage;

  bool _showControls = true;
  bool _isThemeLoaded = false;

  @override
  void initState() {
    super.initState();

    _currentPage = widget.initialPage.clamp(1, _totalPages);

    _loadReaderTheme();
  }

  Future<void> _loadReaderTheme() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final savedTheme = preferences.getString(_themeStorageKey);

      final theme = _QuranReaderTheme.values.firstWhere(
        (item) => item.name == savedTheme,
        orElse: () => _QuranReaderTheme.day,
      );

      if (!mounted) return;

      setState(() {
        _readerTheme = theme;
        _isThemeLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _readerTheme = _QuranReaderTheme.day;
        _isThemeLoaded = true;
      });
    }
  }

  Future<void> _selectReaderTheme(
    _QuranReaderTheme theme,
  ) async {
    if (_readerTheme == theme) return;

    setState(() {
      _readerTheme = theme;
    });

    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setString(
        _themeStorageKey,
        theme.name,
      );
    } catch (_) {
      // The selected theme remains active for this reading session.
    }
  }

  bool get _isCompleted =>
      widget.completedPages.contains(_currentPage);

  bool get _isBookmarked =>
      widget.bookmarkedPages.contains(_currentPage);

  Color get _background {
    switch (_readerTheme) {
      case _QuranReaderTheme.day:
        return const Color(0xFFF0EBDD);
      case _QuranReaderTheme.night:
        return const Color(0xFF071C17);
      case _QuranReaderTheme.warmPaper:
        return const Color(0xFFE5D2AE);
    }
  }

  Color get _pageBackground {
    switch (_readerTheme) {
      case _QuranReaderTheme.day:
        return const Color(0xFFFFFCF3);
      case _QuranReaderTheme.night:
        return const Color(0xFF10271F);
      case _QuranReaderTheme.warmPaper:
        return const Color(0xFFF1E3C7);
    }
  }

  Color get _textColor {
    switch (_readerTheme) {
      case _QuranReaderTheme.day:
        return const Color(0xFF174333);
      case _QuranReaderTheme.night:
        return const Color(0xFFE8DFC9);
      case _QuranReaderTheme.warmPaper:
        return const Color(0xFF553A26);
    }
  }

  Color get _secondaryTextColor =>
      _textColor.withValues(alpha: 0.72);

  void _setPage(int page) {
    if (!mounted || page < 1 || page > _totalPages) return;
    if (page == _currentPage) return;

    setState(() {
      _currentPage = page;
      _sliderPreviewPage = null;
    });

    widget.onPageChanged(page);
  }

  Future<void> _previousPage() async {
    if (_currentPage > 1) {
      _setPage(_currentPage - 1);
    }
  }

  Future<void> _nextPage() async {
    if (_currentPage < _totalPages) {
      _setPage(_currentPage + 1);
    }
  }

  Future<void> _openGoToPage() async {
    final target = await widget.onGoToPage();

    if (!mounted || target == null) return;

    _setPage(target);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.position;
  }

  void _handlePointerUp(PointerUpEvent event) {
    final start = _pointerDownPosition;
    _pointerDownPosition = null;

    if (start == null) return;

    final delta = event.position - start;

    if (delta.dx.abs() < 72) return;
    if (delta.dx.abs() < delta.dy.abs() * 1.25) return;

    if (delta.dx < 0) {
      _nextPage();
    } else {
      _previousPage();
    }
  }

  Widget _buildMushafPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final fontSize = (width / 19).clamp(17.0, 25.0);

        return SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: _pageBackground,
            child: QuranMadinaFlutter(
              key: const ValueKey<String>(
                'mumin_pro_single_mushaf_webview',
              ),
              page: _currentPage,
              height: height,
              bundled: true,
              headless: true,
              fontSize: fontSize,
              textColor: '#${_textColor.value.toRadixString(16).substring(2).toUpperCase()}',
              backgroundColor: '#${_pageBackground.value.toRadixString(16).substring(2).toUpperCase()}',
              ayaActions: [
                QuranAyaAction(
                  id: 'save_ayah',
                  title: QuranPageLocalization.text(
                    context,
                    'quran_save_ayah_action',
                  ),
                ),
              ],
              onAyaAction: widget.onVerseAction,
            ),
          ),
        );
      },
    );
  }
    
  Widget _buildThemeSelector() {
    final options = <_QuranReaderTheme, String>{
      _QuranReaderTheme.day: 'quran_theme_day',
      _QuranReaderTheme.night: 'quran_theme_night',
      _QuranReaderTheme.warmPaper: 'quran_theme_warm_paper',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 9),
      child: Row(
        children: options.entries.map((entry) {
          final selected = _readerTheme == entry.key;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: selected
                    ? _gold.withValues(alpha: 0.20)
                    : _pageBackground.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _selectReaderTheme(entry.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? _gold
                            : _textColor.withValues(alpha: 0.12),
                        width: selected ? 1.4 : 0.8,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.key == _QuranReaderTheme.day
                              ? Icons.light_mode_rounded
                              : entry.key == _QuranReaderTheme.night
                                  ? Icons.dark_mode_rounded
                                  : Icons.menu_book_rounded,
                          color: selected ? _gold : _textColor,
                          size: 18,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          QuranPageLocalization.text(
                            context,
                            entry.value,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildTopBar() {
    return Container(
      color: _background,
      padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
      child: Row(
        children: [
          IconButton(
            tooltip: QuranPageLocalization.text(
              context,
              'quran_back',
            ),
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: _textColor,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  QuranPageLocalization.text(
                    context,
                    'quran_reader_title',
                  ),
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  QuranPageLocalization.pagePosition(
                    context,
                    page: _currentPage,
                    total: _totalPages,
                  ),
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: QuranPageLocalization.text(
              context,
              _showControls
                  ? 'quran_hide_controls'
                  : 'quran_show_controls',
            ),
            onPressed: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            icon: Icon(
              _showControls
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      color: _background,
      padding: const EdgeInsets.fromLTRB(9, 5, 9, 5),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showControls) ...[
              _buildThemeSelector(),
              Row(
                children: [
                  Icon(
                    _isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _isCompleted ? _emerald : _gold,
                    size: 20,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      QuranPageLocalization.text(
                        context,
                        _isCompleted
                            ? 'quran_page_read_completed'
                            : 'quran_page_read_question',
                      ),
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isCompleted
                        ? widget.onUndoPageRead
                        : widget.onMarkPageRead,
                    child: Text(
                      QuranPageLocalization.text(
                        context,
                        _isCompleted
                            ? 'quran_undo'
                            : 'quran_mark_read',
                      ),
                      style: const TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: QuranPageLocalization.text(
                      context,
                      'quran_previous_short',
                    ),
                    onPressed:
                        _currentPage > 1 ? _previousPage : null,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _gold,
                      size: 29,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _emerald,
                        inactiveTrackColor:
                            _textColor.withValues(alpha: 0.18),
                        thumbColor: _gold,
                        overlayColor:
                            _gold.withValues(alpha: 0.15),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        min: 1,
                        max: _totalPages.toDouble(),
                        divisions: _totalPages - 1,
                        value: (_sliderPreviewPage ??
                                _currentPage.toDouble())
                            .clamp(1.0, _totalPages.toDouble()),
                        onChanged: (value) {
                          setState(() {
                            _sliderPreviewPage = value;
                          });
                        },
                        onChangeEnd: (value) {
                          _setPage(value.round());
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: QuranPageLocalization.text(
                      context,
                      'quran_next_short',
                    ),
                    onPressed: _currentPage < _totalPages
                        ? _nextPage
                        : null,
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: _gold,
                      size: 29,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Text(
                      '$_currentPage / $_totalPages',
                      style: TextStyle(
                        color: _textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    _ReaderActionButton(
                      icon: _isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_add_outlined,
                      label: QuranPageLocalization.text(
                        context,
                        'quran_save_page_bookmark',
                      ),
                      onTap: widget.onTogglePageBookmark,
                    ),
                    _ReaderActionButton(
                      icon: Icons.toc_rounded,
                      label: QuranPageLocalization.text(
                        context,
                        'quran_index_title',
                      ),
                      onTap: widget.onOpenIndex,
                    ),
                    _ReaderActionButton(
                      icon: Icons.bookmarks_outlined,
                      label: QuranPageLocalization.text(
                        context,
                        'quran_bookmarks_short',
                      ),
                      onTap: widget.onOpenPageBookmarks,
                    ),
                    _ReaderActionButton(
                      icon: Icons.format_list_numbered_rounded,
                      label: QuranPageLocalization.text(
                        context,
                        'quran_verses_short',
                      ),
                      onTap: widget.onOpenVerseBookmarks,
                    ),
                    _ReaderActionButton(
                      icon: Icons.search_rounded,
                      label: QuranPageLocalization.text(
                        context,
                        'quran_go_to_short',
                      ),
                      onTap: _openGoToPage,
                    ),
                  ],
                ),
              ),
            ] else
              Row(
                children: [
                  Text(
                    QuranPageLocalization.pagePosition(
                      context,
                      page: _currentPage,
                      total: _totalPages,
                    ),
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showControls = true;
                      });
                    },
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: _gold,
                    ),
                    label: Text(
                      QuranPageLocalization.text(
                        context,
                        'quran_show_controls',
                      ),
                      style: const TextStyle(color: _gold),
                    ),
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
    if (!_isThemeLoaded) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(
          child: CircularProgressIndicator(
            color: _gold,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            if (_showControls) _buildTopBar(),
            Expanded(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _handlePointerDown,
                onPointerUp: _handlePointerUp,
                onPointerCancel: (_) {
                  _pointerDownPosition = null;
                },
                child: _buildMushafPage(),
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }
}

class _ReaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Future<void> Function() onTap;

  const _ReaderActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 7,
            horizontal: 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: const Color(0xFFD8B66A),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFFD8B66A),
              size: 21,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
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
