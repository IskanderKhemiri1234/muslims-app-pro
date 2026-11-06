
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
          title: 'الآيات المحفوظة',
          isDark: isDark,
          child: verses.isEmpty
              ? const _EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: 'لا توجد آيات محفوظة',
                  subtitle: 'اضغط على آية داخل المصحف واختر حفظ الآية',
                )
              : ListView.separated(
                  itemCount: verses.length,
                  separatorBuilder: (_, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final verse = verses[index];

                    final suraName =
                        verse['suraName'] as String? ?? 'سورة';

                    
                    final aya = verse['aya'] as int;
                    final page = verse['page'] as int;
                    final text = verse['text'] as String? ?? '';

                    return ListTile(
                      leading: const Icon(
                        Icons.bookmark_rounded,
                        color: _gold,
                      ),
                      title: Text(
                        '$suraName - الآية $aya',
                        textDirection: TextDirection.rtl,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (text.isNotEmpty)
                            Text(
                              text,
                              textDirection: TextDirection.rtl,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text('صفحة $page'),
                        ],
                      ),
                      onTap: () => Navigator.pop(sheetContext, page),
                      trailing: IconButton(
                        tooltip: 'حذف',
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
      _selectPage(selectedPage, saveImmediately: true);
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
          title: 'علاماتي المرجعية',
          isDark: isDark,
          child: pages.isEmpty
              ? const _EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: 'لا توجد علامات مرجعية',
                  subtitle: 'احفظ الصفحات المهمة للعودة إليها لاحقاً',
                )
              : ListView.separated(
                  itemCount: pages.length,
                  separatorBuilder: (_, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final page = pages[index];

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0x1FD8B66A),
                        child: Icon(
                          Icons.bookmark_rounded,
                          color: _gold,
                        ),
                      ),
                      title: Text('صفحة $page'),
                      subtitle: Text(
                        page == _currentPage
                            ? 'الصفحة الحالية'
                            : 'الانتقال إلى الصفحة',
                      ),
                      onTap: () => Navigator.pop(sheetContext, page),
                      trailing: IconButton(
                        tooltip: 'حذف العلامة',
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

  Future<void> _goToPage() async {
    if (_isLoading || !mounted) return;

    final controller = TextEditingController(
      text: _currentPage.toString(),
    );

    int? selectedPage;

    try {
      selectedPage = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('الانتقال إلى صفحة'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'من 1 إلى 604',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                ),
                onPressed: () {
                  final page = int.tryParse(controller.text.trim());

                  if (page == null || !_isValidPage(page)) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('رقم الصفحة غير صحيح'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext, page);
                },
                child: const Text('انتقال'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }

    if (selectedPage != null && mounted) {
      _selectPage(selectedPage, saveImmediately: true);
    }
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
            title: 'فهرس المصحف',
            isDark: isDark,
            child: Column(
              children: [
                TabBar(
                  labelColor: isDark ? _gold : _green,
                  unselectedLabelColor:
                      isDark ? Colors.white60 : Colors.black54,
                  indicatorColor: _gold,
                  tabs: const [
                    Tab(text: 'السور'),
                    Tab(text: 'الأجزاء'),
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
                              backgroundColor: const Color(0x1FD8B66A),
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
      QuranPageLocalization.textDirectionOf(context),
  style: const TextStyle(
    fontWeight: FontWeight.w600,
  ),
),

                            trailing: Text('صفحة ${surah.page}'),
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
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0x1FD8B66A),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: _gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text('الجزء ${index + 1}'),
                            trailing: Text(
                              'صفحة ${_juzPages[index]}',
                            ),
                            onTap: () => Navigator.pop(
                              sheetContext,
                              _juzPages[index],
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
          isDark: Theme.of(context).brightness == Brightness.dark,
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رحلتك مع القرآن',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'مصحف المدينة المنورة',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '604 صفحة',
                style: TextStyle(
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
              const Text(
                'إنجاز الختمة الحالية',
                style: TextStyle(
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
              valueColor: const AlwaysStoppedAnimation<Color>(_gold),
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
                '${_completedPages.length} صفحة مكتملة',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '$_completedKhatmas ختمة مكتملة',
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
                  'وردك اليومي',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_todayPages.length} من $_dailyTarget صفحات',
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
              color: _green.withValues(alpha: isDark ? 0.35 : 0.07),
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
                  'الصفحة $_currentPage',
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
                  'فتح المصحف كاملاً',
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
                              ayaActions: const [
                                QuranAyaAction(
                                  id: 'save_ayah',
                                  title: 'حفظ الآية',
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
                      child: const Text(
                        'اضغط لفتح صفحة القرآن كاملة',
                        style: TextStyle(
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
                  _currentPageCompleted
                      ? 'تم تسجيل قراءة هذه الصفحة'
                      : 'هل أتممت قراءة هذه الصفحة؟',
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
                  _currentPageCompleted ? 'تراجع' : 'تسجيل',
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
              Text(
                '1',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '$_currentPage / $_totalPages',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '604',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
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
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('السابقة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side: BorderSide(
                      color: _green.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _currentPage < _totalPages
                      ? () => _changePage(1)
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('التالية'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
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
                  label: _currentPageBookmarked
                      ? 'إزالة العلامة'
                      : 'حفظ الصفحة',
                  onTap: _toggleBookmark,
                ),
              ),
              Expanded(
                child: _SmallAction(
                  icon: Icons.menu_book_rounded,
                  label: 'الفهرس',
                  onTap: _openIndex,
                ),
              ),
              Expanded(
                child: _SmallAction(
                  icon: Icons.bookmarks_outlined,
                  label: 'الآيات المحفوظة',
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
        title: const Text(
          'القرآن الكريم',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'الآيات المحفوظة',
            onPressed: _isLoading ? null : _openVerseBookmarks,
            icon: const Icon(Icons.bookmark_outline_rounded),
          ),
          IconButton(
            tooltip: 'العلامات المرجعية',
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

class _QuranFullScreenReader extends StatefulWidget {
  final int initialPage;
  final Set<int> completedPages;
  final Set<int> bookmarkedPages;
  final bool isDark;

  final ValueChanged<int> onPageChanged;
  final Future<void> Function() onTogglePageBookmark;
  final Future<void> Function() onMarkPageRead;
  final Future<void> Function() onUndoPageRead;
  final Future<void> Function(QuranAyaSelection) onVerseAction;

  final Future<void> Function() onOpenIndex;
  final Future<void> Function() onOpenPageBookmarks;
  final Future<void> Function() onOpenVerseBookmarks;
  final Future<void> Function() onGoToPage;

  const _QuranFullScreenReader({
    required this.initialPage,
    required this.completedPages,
    required this.bookmarkedPages,
    required this.isDark,
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

  static const Color _green = Color(0xFF075B46);
  static const Color _gold = Color(0xFFD8B66A);

  late final PageController _pageController;

  late int _currentPage;

  bool _showControls = true;

  @override
  void initState() {
    super.initState();

    _currentPage = widget.initialPage.clamp(1, _totalPages);

    _pageController = PageController(
      initialPage: _currentPage - 1,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isCompleted =>
      widget.completedPages.contains(_currentPage);

  bool get _isBookmarked =>
      widget.bookmarkedPages.contains(_currentPage);

  Color get _background => widget.isDark
      ? const Color(0xFF101B16)
      : const Color(0xFFF3F5F0);

  Color get _pageBackground => widget.isDark
      ? const Color(0xFF202A23)
      : const Color(0xFFFFFCF3);

  Color get _textColor => widget.isDark
      ? const Color(0xFFE8DFC9)
      : const Color(0xFF26382C);

  void _onPageChanged(int index) {
    final page = index + 1;

    setState(() {
      _currentPage = page;
    });

    widget.onPageChanged(page);
  }

  Future<void> _previousPage() async {
    if (_currentPage <= 1) return;

    await _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _nextPage() async {
    if (_currentPage >= _totalPages) return;

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openGoToPage() async {
    await widget.onGoToPage();

    if (!mounted) return;

    final target = _currentPage;

    if (_pageController.hasClients &&
        target >= 1 &&
        target <= _totalPages) {
      _pageController.jumpToPage(target - 1);
    }
  }

  Widget _buildMushafPage(int page) {
    final width = MediaQuery.of(context).size.width;
    final fontSize = (width / 19).clamp(17.0, 25.0);

    return Container(
      color: _pageBackground,
      child: SingleChildScrollView(
        key: PageStorageKey<String>('mushaf_page_$page'),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: SizedBox(
              width: double.infinity,
              child: QuranMadinaFlutter(
                key: ValueKey('full_mushaf_$page'),
                page: page,
                bundled: true,
                headless: true,
                fontSize: fontSize,
                textColor: widget.isDark ? '#E8DFC9' : '#26382C',
                backgroundColor:
                    widget.isDark ? '#202A23' : '#FFFCF3',
                ayaActions: const [
                  QuranAyaAction(
                    id: 'save_ayah',
                    title: 'حفظ الآية',
                  ),
                ],
                onAyaAction: widget.onVerseAction,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: _background,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'العودة',
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
                  'مصحف المدينة المنورة',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'الصفحة $_currentPage من $_totalPages',
                  style: TextStyle(
                    color: _textColor.withValues(alpha: 0.65),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'إخفاء أدوات القراءة',
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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
        decoration: BoxDecoration(
          color: _background,
          border: Border(
            top: BorderSide(
              color: _gold.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: _isCompleted ? _green : _gold,
                  size: 21,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _isCompleted
                        ? 'تم تسجيل قراءة الصفحة'
                        : 'هل أتممت قراءة الصفحة؟',
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
                    _isCompleted ? 'تراجع' : 'تسجيل',
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
                  tooltip: 'الصفحة السابقة',
                  onPressed: _currentPage > 1
                      ? _previousPage
                      : null,
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: _gold,
                    size: 30,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _green,
                      inactiveTrackColor:
                          _green.withValues(alpha: 0.2),
                      thumbColor: _gold,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      min: 1,
                      max: _totalPages.toDouble(),
                      divisions: _totalPages - 1,
                      value: _currentPage.toDouble(),
                      onChanged: (value) {
                        final page = value.round();

                        setState(() {
                          _currentPage = page;
                        });

                        _pageController.jumpToPage(page - 1);
                        widget.onPageChanged(page);
                      },
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'الصفحة التالية',
                  onPressed: _currentPage < _totalPages
                      ? _nextPage
                      : null,
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: _gold,
                    size: 30,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '$_currentPage / $_totalPages',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                _ReaderActionButton(
                  icon: _isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_add_outlined,
                  label: 'حفظ',
                  onTap: widget.onTogglePageBookmark,
                ),
                _ReaderActionButton(
                  icon: Icons.toc_rounded,
                  label: 'الفهرس',
                  onTap: widget.onOpenIndex,
                ),
                _ReaderActionButton(
                  icon: Icons.bookmarks_outlined,
                  label: 'العلامات',
                  onTap: widget.onOpenPageBookmarks,
                ),
                _ReaderActionButton(
                  icon: Icons.format_list_numbered_rounded,
                  label: 'الآيات',
                  onTap: widget.onOpenVerseBookmarks,
                ),
                _ReaderActionButton(
                  icon: Icons.search_rounded,
                  label: 'انتقال',
                  onTap: _openGoToPage,
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
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            if (_showControls) _buildTopBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: _onPageChanged,
                physics: const PageScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildMushafPage(index + 1);
                },
              ),
            ),
            if (_showControls) _buildBottomControls(),
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
