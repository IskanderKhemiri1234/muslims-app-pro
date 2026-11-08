
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/design_system/mumin_design_tokens.dart';
import '../../../../core/localization/mumin_language_registry.dart';
import '../../../../core/localization/mumin_localizations.dart';

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  static const List<int> _targets = [33, 100, 1000];

  static const String _countKey = 'mumin_tasbih_count';
  static const String _targetKey = 'mumin_tasbih_target';

  int _count = 0;
  int _target = 33;
  bool _isLoading = true;

  Future<void> _saveQueue = Future<void>.value();

  MuminLocalizations get _localizations {
    final code = MuminLanguageRegistry.normalizeLanguageCode(
      Localizations.localeOf(context).languageCode,
    );
    return MuminLocalizations.fromCode(code);
  }

  String _text(String key, String fallback) {
    return _localizations.textOr(key, fallback: fallback);
  }

  double get _progress {
    if (_target <= 0) return 0;
    return (_count / _target).clamp(0.0, 1.0).toDouble();
  }

  bool get _completed => _count >= _target;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final savedTarget = preferences.getInt(_targetKey) ?? 33;
      final validTarget = _targets.contains(savedTarget) ? savedTarget : 33;

      final savedCount = preferences.getInt(_countKey) ?? 0;
      final validCount = savedCount.clamp(0, validTarget).toInt();

      if (!mounted) return;

      setState(() {
        _target = validTarget;
        _count = validCount;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Tasbih: unable to restore progress: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _saveProgress() {
    final count = _count;
    final target = _target;

    _saveQueue = _saveQueue
        .then((_) async {
          final preferences = await SharedPreferences.getInstance();
          await preferences.setInt(_countKey, count);
          await preferences.setInt(_targetKey, target);
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Tasbih: unable to save progress: $error');
          debugPrintStack(stackTrace: stackTrace);
        });
  }

  void _increment() {
    if (_completed) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _count++;
    });

    HapticFeedback.selectionClick();
    _saveProgress();
  }

  void _undo() {
    if (_count <= 0) return;

    setState(() {
      _count--;
    });

    HapticFeedback.lightImpact();
    _saveProgress();
  }

  void _selectTarget(int target) {
    if (!_targets.contains(target) || target == _target) return;

    setState(() {
      _target = target;
      if (_count > target) {
        _count = target;
      }
    });

    HapticFeedback.selectionClick();
    _saveProgress();
  }

  Future<void> _resetCounter() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _text('tasbih_reset_title', 'إعادة ضبط المسبحة'),
          ),
          content: Text(
            _text(
              'tasbih_reset_message',
              'هل تريد تصفير العدّاد الحالي؟',
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
      _count = 0;
    });

    HapticFeedback.lightImpact();
    _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? MuminColors.midnightEmerald
          : const Color(0xFFF5F3EC),
      appBar: AppBar(
        title: Text(_text('tasbih', 'المسبحة')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 28),
                    _buildTargetSelector(isDark),
                    const SizedBox(height: 28),
                    _buildCounter(isDark),
                    const SizedBox(height: 24),
                    _buildControls(isDark),
                    const SizedBox(height: 22),
                    _buildNote(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
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
          color: MuminColors.gold.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.grain_rounded,
            color: MuminColors.goldLight,
            size: 32,
          ),
          const SizedBox(height: 14),
          Text(
            _text('tasbih_header_title', 'مسبحتك الرقمية'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _text(
              'tasbih_header_description',
              'اختر هدف العدّ واضغط على الدائرة لتسجيل كل تسبيحة.',
            ),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            _text('tasbih_choose_target', 'اختر هدف العدّ'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _targets.map((target) {
            final selected = target == _target;

            return ChoiceChip(
              label: Text('$target'),
              selected: selected,
              onSelected: (_) => _selectTarget(target),
              selectedColor: MuminColors.emerald,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white,
              side: BorderSide(
                color: selected
                    ? MuminColors.gold
                    : MuminColors.gold.withValues(alpha: 0.25),
              ),
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCounter(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 26),
      decoration: BoxDecoration(
        color: isDark
            ? MuminColors.deepEmerald.withValues(alpha: 0.72)
            : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: MuminColors.gold.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _text('tasbih_current_count', 'العدد الحالي'),
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: _increment,
            child: Semantics(
              button: true,
              label: _text(
                'tasbih_tap_to_count',
                'اضغط لزيادة العدّاد',
              ),
              child: SizedBox(
                width: 230,
                height: 230,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor:
                            MuminColors.gold.withValues(alpha: 0.15),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          MuminColors.gold,
                        ),
                      ),
                    ),
                    Container(
                      width: 204,
                      height: 204,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _completed
                              ? const [
                                  Color(0xFFD8B66A),
                                  Color(0xFFB18B42),
                                ]
                              : const [
                                  Color(0xFF147A60),
                                  Color(0xFF063E31),
                                ],
                        ),
                        border: Border.all(
                          color: MuminColors.goldLight,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: MuminColors.gold.withValues(
                              alpha: 0.20,
                            ),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _completed
                                ? Icons.check_circle_rounded
                                : Icons.touch_app_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Text(
                              '$_count',
                              key: ValueKey<int>(_count),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '/ $_target',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _completed
                ? _text('tasbih_completed', 'اكتمل هدف العدّ')
                : '${_text('tasbih_remaining', 'المتبقي')}: ${_target - _count}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _completed ? MuminColors.goldDark : null,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _text(
              'tasbih_tap_instruction',
              'المس الدائرة الكبيرة لإضافة تسبيحة',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _count == 0 ? null : _undo,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: Text(_text('tasbih_undo', 'تراجع')),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isDark ? MuminColors.goldLight : MuminColors.deepEmerald,
              side: BorderSide(
                color: MuminColors.gold.withValues(alpha: 0.6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _count == 0 ? null : _resetCounter,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(_text('reset', 'إعادة الضبط')),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isDark ? MuminColors.goldLight : MuminColors.deepEmerald,
              side: BorderSide(
                color: MuminColors.gold.withValues(alpha: 0.6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNote(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : MuminColors.emerald.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: MuminColors.goldDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _text(
                'tasbih_personal_target_note',
                'الأعداد المعروضة أهداف شخصية للعدّ، ويمكنك اختيار ما يناسبك. لا تمثل هذه الأهداف تحديداً شرعياً لعدد الذكر.',
              ),
              style: TextStyle(
                height: 1.6,
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
