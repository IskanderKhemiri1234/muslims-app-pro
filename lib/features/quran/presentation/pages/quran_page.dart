
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/services/quran_api_service.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final QuranApiService _api = QuranApiService();

  QuranSurah? _surah;
  bool _loading = true;
  String? _error;

  int _selectedSurah = 1;
  double _fontSize = 27;
  String _fontStyle = 'serif';

  static const List<String> _surahNames = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء',
    'المائدة', 'الأنعام', 'الأعراف', 'الأنفال',
    'التوبة', 'يونس', 'هود', 'يوسف',
    'الرعد', 'إبراهيم', 'الحجر', 'النحل',
    'الإسراء', 'الكهف', 'مريم', 'طه',
    'الأنبياء', 'الحج', 'المؤمنون', 'النور',
    'الفرقان', 'الشعراء', 'النمل', 'القصص',
    'العنكبوت', 'الروم', 'لقمان', 'السجدة',
    'الأحزاب', 'سبأ', 'فاطر', 'يس',
    'الصافات', 'ص', 'الزمر', 'غافر',
    'فصلت', 'الشورى', 'الزخرف', 'الدخان',
    'الجاثية', 'الأحقاف', 'محمد', 'الفتح',
    'الحجرات', 'ق', 'الذاريات', 'الطور',
    'النجم', 'القمر', 'الرحمن', 'الواقعة',
    'الحديد', 'المجادلة', 'الحشر', 'الممتحنة',
    'الصف', 'الجمعة', 'المنافقون', 'التغابن',
    'الطلاق', 'التحريم', 'الملك', 'القلم',
    'الحاقة', 'المعارج', 'نوح', 'الجن',
    'المزمل', 'المدثر', 'القيامة', 'الإنسان',
    'المرسلات', 'النبأ', 'النازعات', 'عبس',
    'التكوير', 'الانفطار', 'المطففين', 'الانشقاق',
    'البروج', 'الطارق', 'الأعلى', 'الغاشية',
    'الفجر', 'البلد', 'الشمس', 'الليل',
    'الضحى', 'الشرح', 'التين', 'العلق',
    'القدر', 'البينة', 'الزلزلة', 'العاديات',
    'القارعة', 'التكاثر', 'العصر', 'الهمزة',
    'الفيل', 'قريش', 'الماعون', 'الكوثر',
    'الكافرون', 'النصر', 'المسد', 'الإخلاص',
    'الفلق', 'الناس',
  ];

  @override
  void initState() {
    super.initState();
    _loadSurah(1);
  }

  Future<void> _loadSurah(int number) async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedSurah = number;
    });

    try {
      final result = await _api.getSurah(number);

      if (!mounted) return;

      setState(() {
        _surah = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF7F3E9),
      appBar: AppBar(
        title: const Text(
          'القرآن الكريم',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'إعدادات القراءة',
            onPressed: _showReadingSettings,
            icon: const Icon(Icons.text_fields_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSurahSelector(isDark),
          _buildReadingInfo(isDark),
          Expanded(child: _buildQuranContent(isDark)),
        ],
      ),
    );
  }

  Widget _buildSurahSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedSurah,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: isDark
              ? AppColors.darkSurface
              : Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.gold,
          ),
          items: List.generate(114, (index) {
            final number = index + 1;

            return DropdownMenuItem<int>(
              value: number,
              child: Text(
                'سورة ${_surahNames[index]}',
                textDirection: TextDirection.rtl,
              ),
            );
          }),
          onChanged: (value) {
            if (value != null && value != _selectedSurah) {
              _loadSurah(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildReadingInfo(bool isDark) {
    final surah = _surah;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF075B43),
            Color(0xFF0B8060),
          ],
        ),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.16),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: AppColors.goldLight,
            size: 32,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah?.name ?? 'القرآن الكريم',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  surah == null
                      ? 'جاري تحميل السورة'
                      : '${surah.numberOfAyahs} آية'
                          '  •  ${surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.goldLight,
          ),
        ],
      ),
    );
  }

  Widget _buildQuranContent(bool isDark) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 45,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              const Text(
                'تعذر تحميل السورة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _loadSurah(_selectedSurah),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final surah = _surah;

    if (surah == null) {
      return const Center(child: Text('لا توجد بيانات.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 40),
      children: [
        if (surah.number != 1 && surah.number != 9)
          _buildBismillah(isDark),
        const SizedBox(height: 15),
        ...surah.ayahs.map(
          (ayah) => _buildAyah(ayah, isDark),
        ),
      ],
    );
  }

  Widget _buildBismillah(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: _fontSize + 2,
          height: 2.0,
          fontFamily: _fontStyle == 'serif' ? 'serif' : null,
          color: isDark
              ? const Color(0xFFE9D9B5)
              : const Color(0xFF183E31),
        ),
      ),
    );
  }

  Widget _buildAyah(QuranAyah ayah, bool isDark) {
    return InkWell(
      onTap: () => _showTafsir(ayah),
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 5,
        ),
        child: Column(
          children: [
            Text(
              ayah.text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _fontSize,
                height: 2.05,
                fontFamily: _fontStyle == 'serif' ? 'serif' : null,
                color: isDark
                    ? const Color(0xFFF1E8D5)
                    : const Color(0xFF172E25),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'الآية ${ayah.numberInSurah}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'التفسير',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Divider(
              color: AppColors.gold.withValues(alpha: 0.13),
              height: 1,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTafsir(QuranAyah ayah) async {
    final surah = _surah;

    if (surah == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) {
        final isDark =
            Theme.of(sheetContext).brightness == Brightness.dark;

        return _TafsirSheet(
          api: _api,
          surahNumber: surah.number,
          surahName: surah.name,
          ayah: ayah,
          isDark: isDark,
        );
      },
    );
  }

  void _showReadingSettings() {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : const Color(0xFFFFFCF5),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'إعدادات القراءة',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('حجم خط الآيات'),
                      Text('${_fontSize.round()}'),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 20,
                    max: 42,
                    divisions: 22,
                    activeColor: AppColors.gold,
                    onChanged: (value) {
                      setSheetState(() => _fontSize = value);
                      setState(() => _fontSize = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('نمط الخط'),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'serif',
                        label: Text('نسخي'),
                      ),
                      ButtonSegment(
                        value: 'default',
                        label: Text('افتراضي'),
                      ),
                    ],
                    selected: {_fontStyle},
                    onSelectionChanged: (selection) {
                      setSheetState(
                        () => _fontStyle = selection.first,
                      );
                      setState(
                        () => _fontStyle = selection.first,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _TafsirSheet extends StatefulWidget {
  const _TafsirSheet({
    required this.api,
    required this.surahNumber,
    required this.surahName,
    required this.ayah,
    required this.isDark,
  });

  final QuranApiService api;
  final int surahNumber;
  final String surahName;
  final QuranAyah ayah;
  final bool isDark;

  @override
  State<_TafsirSheet> createState() => _TafsirSheetState();
}

class _TafsirSheetState extends State<_TafsirSheet> {
  late Future<String> _tafsirFuture;

  @override
  void initState() {
    super.initState();
    _tafsirFuture = widget.api.getTafsir(
      surahNumber: widget.surahNumber,
      ayahNumber: widget.ayah.numberInSurah,
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.isDark
        ? const Color(0xFF10231D).withValues(alpha: 0.94)
        : const Color(0xFFFFFCF5).withValues(alpha: 0.94);

    return Padding(
      padding: EdgeInsets.only(
        top: 35,
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
          bottom: Radius.circular(25),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.78,
            ),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
            decoration: BoxDecoration(
              color: background,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.30),
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
                bottom: Radius.circular(25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 19),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'التفسير الميسر',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'سورة ${widget.surahName} • الآية ${widget.ayah.numberInSurah}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.ayah.text,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1.9,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: FutureBuilder<String>(
                    future: _tafsirFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                color: Colors.orange,
                                size: 34,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'تعذر تحميل التفسير.',
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _tafsirFuture =
                                        widget.api.getTafsir(
                                      surahNumber: widget.surahNumber,
                                      ayahNumber:
                                          widget.ayah.numberInSurah,
                                    );
                                  });
                                },
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        child: SelectableText(
                          snapshot.data ?? 'لا يوجد تفسير متاح.',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.95,
                            color: widget.isDark
                                ? const Color(0xFFECE5D5)
                                : const Color(0xFF25372E),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'المصدر: التفسير الميسر – QuranEnc',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
