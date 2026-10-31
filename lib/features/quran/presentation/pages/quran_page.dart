
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_madina_flutter/quran_madina_flutter.dart';

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

class _QuranPageState extends State<QuranPage> {
  static const int _totalPages = 604;
  static const String _savedPageKey = 'quran_last_read_page';
  static const String _completedPagesKey = 'quran_completed_pages';
  static const String _completedKhatmasKey = 'quran_completed_khatmas';
  static const String _dailyGoal = '5';
  static const String _bookmarksKey = 'quran_bookmarks';
  
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
    1, 22, 42, 62, 82,
    102, 121, 142, 162, 182,
    201, 222, 242, 262, 282,
    302, 322, 342, 362, 382,
    402, 422, 442, 462, 482,
    502, 522, 542, 562, 582,
  ];

  int _currentPage = 1;
  Set<int> _completedPages = {};
Set<int> _todayPages = {};
int _completedKhatmas = 0;

static const int _dailyTarget = 5;

String get _todayStorageKey {
  final now = DateTime.now();
  final date =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  return 'quran_daily_pages_$date';
}
  bool _isLoading = true;

  
  @override
  void initState() {
    super.initState();
    _restoreLastPage();
  }

  Future<void> _restoreLastPage() async {
    final preferences = await SharedPreferences.getInstance();
    final savedPage = preferences.getInt(_savedPageKey) ?? 1;

    if (!mounted) return;

    setState(() {
      _currentPage = savedPage.clamp(1, _totalPages);
      _isLoading = false;
    });
  }

  Future<void> _savePage(int page) async {
    Future<void> _addBookmark() async {
  final preferences = await SharedPreferences.getInstance();
  final bookmarks = preferences.getStringList(_bookmarksKey) ?? [];

  final page = _currentPage.toString();

  if (bookmarks.contains(page)) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الصفحة محفوظة بالفعل')),
    );
    return;
  }

  bookmarks.add(page);
  bookmarks.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

  await preferences.setStringList(_bookmarksKey, bookmarks);

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تم حفظ العلامة المرجعية')),
  );
}

Future<void> _openBookmarks() async {
  final preferences = await SharedPreferences.getInstance();
  final bookmarks = preferences.getStringList(_bookmarksKey) ?? [];

  if (!mounted) return;

  final selectedPage = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final isDark =
          Theme.of(sheetContext).brightness == Brightness.dark;

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1B2821)
                  : const Color(0xFFFFFCF3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'علاماتي المرجعية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: bookmarks.isEmpty
                      ? const Center(
                          child: Text('لم تحفظ أي صفحة بعد'),
                        )
                      : ListView.builder(
                          itemCount: bookmarks.length,
                          itemBuilder: (context, index) {
                            final page = int.parse(bookmarks[index]);

                            return ListTile(
                              leading: const Icon(
                                Icons.bookmark,
                                color: Color(0xFFD6B66D),
                              ),
                              title: Text('صفحة $page'),
                              subtitle: Text(
                                page == _currentPage
                                    ? 'أنت تقرأ هذه الصفحة الآن'
                                    : 'الانتقال إلى الصفحة',
                              ),
                              onTap: () {
                                Navigator.pop(sheetContext, page);
                              },
                              trailing: IconButton(
                                tooltip: 'حذف العلامة',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  bookmarks.removeAt(index);

                                  await preferences.setStringList(
                                    _bookmarksKey,
                                    bookmarks,
                                  );

                                  setModalState(() {});
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  if (selectedPage != null && mounted) {
    _selectPage(selectedPage);
  }
}
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_savedPageKey, page);
  }

  void _changePage(int value) {
    final newPage = (_currentPage + value).clamp(1, _totalPages);

    if (newPage == _currentPage) return;

    setState(() {
      _currentPage = newPage;
    });

    _savePage(newPage);
  }

  void _selectPage(int page) {
    setState(() {
      _currentPage = page;
    });

    _savePage(page);
  }

  Future<void> _goToPage() async {
    final controller = TextEditingController(
      text: _currentPage.toString(),
    );

    final selectedPage = await showDialog<int>(
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
            IconButton(
  tooltip: 'حفظ الصفحة الحالية',
  onPressed: _addBookmark,
  icon: const Icon(Icons.bookmark_add_outlined),
),
IconButton(
  tooltip: 'علاماتي المرجعية',
  onPressed: _openBookmarks,
  icon: const Icon(Icons.bookmarks_outlined),
),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final page = int.tryParse(controller.text.trim());

                if (page == null || page < 1 || page > _totalPages) {
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

    controller.dispose();

    if (selectedPage != null && mounted) {
      _selectPage(selectedPage);
    }
  }

  Future<void> _openIndex() async {
    final selectedPage = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final color = isDark
            ? const Color(0xFF1B2821)
            : const Color(0xFFFFFCF3);

        return DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(sheetContext).size.height * 0.78,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'فهرس المصحف',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'السور'),
                    Tab(text: 'الأجزاء'),
                  ],
                ),
                Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 6,
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'تقدم موضع القراءة',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${((_currentPage / _totalPages) * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: _currentPage / _totalPages,
          minHeight: 7,
          backgroundColor: accentColor.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
        ),
      ),
    ],
  ),
),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView.builder(
                        itemCount: _surahs.length,
                        itemBuilder: (context, index) {
                          final surah = _surahs[index];

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              surah.name,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Text('صفحة ${surah.page}'),
                            onTap: () {
                              Navigator.pop(sheetContext, surah.page);
                            },
                          );
                        },
                      ),
                      ListView.builder(
                        itemCount: _juzPages.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text('الجزء ${index + 1}'),
                            trailing: Text(
                              'صفحة ${_juzPages[index]}',
                            ),
                            onTap: () {
                              Navigator.pop(
                                sheetContext,
                                _juzPages[index],
                              );
                            },
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
      _selectPage(selectedPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF111A16)
        : const Color(0xFFF1E9D5);

    final pageColor = isDark
        ? const Color(0xFF202A23)
        : const Color(0xFFFFFCF3);

    final textColor = isDark
        ? const Color(0xFFE8DFC9)
        : const Color(0xFF26382C);

    final accentColor = isDark
        ? const Color(0xFFD6B66D)
        : const Color(0xFF16734B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'المصحف الشريف',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'فهرس السور والأجزاء',
            onPressed: _openIndex,
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            tooltip: 'الانتقال إلى صفحة',
            onPressed: _goToPage,
            icon: const Icon(Icons.find_in_page_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'مصحف المدينة المنورة',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'صفحة $_currentPage من $_totalPages',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: pageColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: QuranMadinaFlutter(
                            key: ValueKey(_currentPage),
                            page: _currentPage,
                            bundled: true,
                            headless: true,
                            fontSize: 22,
                            textColor: isDark ? '#E8DFC9' : '#26382C',
                            backgroundColor:
                                isDark ? '#202A23' : '#FFFCF3',
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      children: [
                        Slider(
                          value: _currentPage.toDouble(),
                          min: 1,
                          max: _totalPages.toDouble(),
                          divisions: _totalPages - 1,
                          activeColor: accentColor,
                          inactiveColor:
                              accentColor.withValues(alpha: 0.2),
                          onChanged: (value) {
                            _selectPage(value.round());
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _currentPage > 1
                                    ? () => _changePage(-1)
                                    : null,
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('السابقة'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _currentPage < _totalPages
                                    ? () => _changePage(1)
                                    : null,
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('التالية'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
