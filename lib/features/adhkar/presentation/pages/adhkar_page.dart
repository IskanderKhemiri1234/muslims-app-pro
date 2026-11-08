import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/design_system/mumin_design_tokens.dart';
import '../../../../core/localization/mumin_language_registry.dart';
import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class AdhkarPage extends StatefulWidget {
  const AdhkarPage({super.key});

  @override
  State<AdhkarPage> createState() => _AdhkarPageState();
}

class _AdhkarPageState extends State<AdhkarPage> {
  static const List<_Dhikr> _adhkar = [
    _Dhikr(
      id: 'istighfar',
      titleKey: 'adhkar_istighfar_title',
      titleFallback: 'الاستغفار',
      text: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
      target: 100,
      occasionKey: 'adhkar_daily',
      occasionFallback: 'خلال اليوم',
      source: 'حصن المسلم 96',
      reference: 'صحيح البخاري، وراجع صحيح مسلم 2702',
    ),
    _Dhikr(
      id: 'subhanallah',
      titleKey: 'adhkar_subhanallah_title',
      titleFallback: 'سبحان الله وبحمده',
      text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      target: 100,
      occasionKey: 'adhkar_morning_evening',
      occasionFallback: 'صباحاً ومساءً',
      source: 'حصن المسلم 91',
      reference: 'صحيح مسلم 2692',
    ),
    _Dhikr(
      id: 'tahlil',
      titleKey: 'adhkar_tahlil_title',
      titleFallback: 'كلمة التوحيد',
      text: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، '
          'لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، '
          'وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      target: 100,
      occasionKey: 'adhkar_daily',
      occasionFallback: 'خلال اليوم',
      source: 'حصن المسلم 93',
      reference: 'صحيح البخاري 3293، وصحيح مسلم 2691',
    ),
  ];

  final Map<String, int> _counts = {};
  Future<void> _saveQueue = Future<void>.value();

  int _selectedIndex = 0;
  bool _isLoading = true;

  _Dhikr get _selected => _adhkar[_selectedIndex];

  MuminLocalizations get _localizations {
    final code = MuminLanguageRegistry.normalizeLanguageCode(
      Localizations.localeOf(context).languageCode,
    );
    return MuminLocalizations.fromCode(code);
  }

  String _text(String key, String fallback) {
    return _localizations.textOr(key, fallback: fallback);
  }

  int _countFor(_Dhikr dhikr) => _counts[dhikr.id] ?? 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final restored = <String, int>{};

      for (final dhikr in _adhkar) {
        final saved = preferences.getInt(_storageKey(dhikr));
        restored[dhikr.id] = (saved ?? 0).clamp(0, dhikr.target);
      }

      if (!mounted) return;

      setState(() {
        _counts.addAll(restored);
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Adhkar: unable to restore progress: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _storageKey(_Dhikr dhikr) => 'mumin_adhkar_${dhikr.id}';

  void _increment() {
    final dhikr = _selected;
    final current = _countFor(dhikr);

    if (current >= dhikr.target) {
      return;
    }

    final next = current + 1;

    HapticFeedback.selectionClick();

    setState(() {
      _counts[dhikr.id] = next;
    });

    _saveProgress(dhikr, next);
  }

  void _saveProgress(_Dhikr dhikr, int count) {
    _saveQueue = _saveQueue
        .then((_) async {
          final preferences = await SharedPreferences.getInstance();
          await preferences.setInt(_storageKey(dhikr), count);
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Adhkar: unable to save progress: $error');
          debugPrintStack(stackTrace: stackTrace);
        });
  }

  Future<void> _resetSelected() async {
    final dhikr = _selected;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_text('adhkar_reset_title', 'إعادة ضبط العدّاد')),
          content: Text(
            _text(
              'adhkar_reset_message',
              'هل تريد تصفير عدّاد هذا الذكر؟',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_text('cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(_text('reset', 'إعادة الضبط')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _counts[dhikr.id] = 0;
    });

    _saveProgress(dhikr, 0);
    HapticFeedback.lightImpact();
  }

  void _selectDhikr(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? MuminColors.midnightEmerald
          : const Color(0xFFF5F3EC),
      appBar: AppBar(
        title: Text(_text('adhkar', 'الأذكار')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 22),
                  _buildDhikrList(isDark),
                  const SizedBox(height: 22),
                  _buildCounter(isDark),
                  const SizedBox(height: 18),
                  _buildSourceNote(isDark),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            MuminColors.deepEmerald,
            MuminColors.midnightEmerald,
          ],
        ),
        border: Border.all(
          color: MuminColors.gold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: MuminColors.goldLight,
            size: 30,
          ),
          const SizedBox(height: 14),
          Text(
            _text('adhkar_header_title', 'اذكر الله واطمئن'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _text(
              'adhkar_header_description',
              'اختر ذكراً وابدأ العدّ. سيُحفظ تقدمك على جهازك.',
            ),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDhikrList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text('adhkar_choose_dhikr', 'اختر الذكر'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < _adhkar.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildDhikrTile(index, isDark),
          ),
      ],
    );
  }

  Widget _buildDhikrTile(int index, bool isDark) {
    final dhikr = _adhkar[index];
    final selected = index == _selectedIndex;
    final count = _countFor(dhikr);

    return Semantics(
      button: true,
      selected: selected,
      label: _text(dhikr.titleKey, dhikr.titleFallback),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _selectDhikr(index),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: selected
                  ? MuminColors.emerald.withValues(
                      alpha: isDark ? 0.42 : 0.10,
                    )
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.045)
                      : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? MuminColors.gold.withValues(alpha: 0.75)
                    : MuminColors.gold.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: MuminColors.gold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text(dhikr.titleKey, dhikr.titleFallback),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_text('adhkar_target', 'العدد')}: ${dhikr.target}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$count/${dhikr.target}',
                  style: const TextStyle(
                    color: MuminColors.goldDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(bool isDark) {
    final dhikr = _selected;
    final count = _countFor(dhikr);
    final completed = count >= dhikr.target;
    final progress = count / dhikr.target;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: isDark
            ? MuminColors.deepEmerald.withValues(alpha: 0.72)
            : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: MuminColors.gold.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _text(dhikr.titleKey, dhikr.titleFallback),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            dhikr.text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 25,
              height: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          TweenAnimationBuilder<double>(
            key: ValueKey('${dhikr.id}-$count'),
            tween: Tween(begin: 0.94, end: 1),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: completed ? null : _increment,
              child: Semantics(
                button: true,
                label: _text('adhkar_tap_to_count', 'اضغط للتسبيح والعدّ'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: completed
                          ? const [
                              Color(0xFFB18B42),
                              Color(0xFFD8B66A),
                            ]
                          : const [
                              Color(0xFF147A60),
                              Color(0xFF063E31),
                            ],
                    ),
                    border: Border.all(
                      color: MuminColors.goldLight,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MuminColors.gold.withValues(alpha: 0.22),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        completed
                            ? Icons.check_circle_rounded
                            : Icons.touch_app_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/ ${dhikr.target}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: MuminColors.gold.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                MuminColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            completed
                ? _text('adhkar_completed', 'اكتمل العدد، تقبّل الله منك')
                : '${_text('adhkar_remaining', 'المتبقي')}: ${dhikr.target - count}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: completed ? MuminColors.gold : null,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: count == 0 ? null : _resetSelected,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(_text('adhkar_reset', 'إعادة ضبط العدّاد')),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceNote(bool isDark) {
    final dhikr = _selected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : MuminColors.emerald.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text('adhkar_source', 'المصدر والتوثيق'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(dhikr.source),
          const SizedBox(height: 4),
          Text(
            dhikr.reference,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            _text(dhikr.occasionKey, dhikr.occasionFallback),
            style: const TextStyle(
              color: MuminColors.goldDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dhikr {
  const _Dhikr({
    required this.id,
    required this.titleKey,
    required this.titleFallback,
    required this.text,
    required this.target,
    required this.occasionKey,
    required this.occasionFallback,
    required this.source,
    required this.reference,
  });

  final String id;
  final String titleKey;
  final String titleFallback;
  final String text;
  final int target;
  final String occasionKey;
  final String occasionFallback;
  final String source;
  final String reference;
}
