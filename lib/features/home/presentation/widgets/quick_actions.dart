import 'package:flutter/material.dart';

import '../../../../core/localization/mumin_domain_localizations.dart';
import '../../../../core/localization/mumin_language_registry.dart';
import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/design_system/mumin_design_tokens.dart';

/// Mumin Pro — Continuous animated quick actions marquee.
///
/// All action tiles move together in one seamless horizontal loop.
/// Navigation IDs remain independent from the visual presentation.
class QuickActions extends StatefulWidget {
  const QuickActions({
    super.key,
    required this.onAction,
  });

  final ValueChanged<String> onAction;

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions>
    with SingleTickerProviderStateMixin {
  static const double _itemHeight = 116;
  static const double _itemWidth = 96;
  static const double _spacing = 12;
  static const double _pixelsPerSecond = 26;

  static const int _actionCount = 6;

  static const double _cycleWidth =
      (_itemWidth * _actionCount) +
      (_spacing * (_actionCount - 1));

    late final Duration _animationDuration;
  late final AnimationController _animationController;

  bool _motionDisabled = false;
  double _manualDragOffset = 0;
  int? _dragPointer;
  double? _dragStartX;
  double? _dragStartY;
  double? _lastDragX;
  bool _isHorizontalDrag = false;

  @override
  void initState() {
    super.initState();

    final durationMilliseconds =
        (_cycleWidth / _pixelsPerSecond * 1000).round();

    _animationDuration =
        Duration(milliseconds: durationMilliseconds);

    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final disableMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (_motionDisabled == disableMotion) return;

    _motionDisabled = disableMotion;

    if (disableMotion) {
      _animationController.stop();
    } else {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  MuminLocalizations _getLocalizations(BuildContext context) {
    final languageCode =
        MuminLanguageRegistry.normalizeLanguageCode(
      Localizations.localeOf(context).languageCode,
    );

    return MuminLocalizations.fromCode(languageCode);
  }

  List<_ActionData> _buildActions(
    MuminLocalizations localizations,
  ) {
    return <_ActionData>[
      _ActionData(
        id: 'qibla',
        title: localizations.qibla,
        semanticLabel: localizations.qibla,
        icon: Icons.explore_rounded,
        color: const Color(0xFF58C9A1),
      ),
      _ActionData(
        id: 'quran',
        title: localizations.quran,
        semanticLabel: localizations.quran,
        icon: Icons.menu_book_rounded,
        color: MuminColors.goldLight,
      ),
      _ActionData(
        id: 'mosques',
        title: localizations.domainText(
          'nearby_mosques_title',
        ),
        semanticLabel: localizations.domainText(
          'nearby_mosques_title',
        ),
        icon: Icons.mosque_rounded,
        color: MuminColors.gold,
      ),
      _ActionData(
        id: 'adhan',
        title: localizations.text(
          'permission_notifications_title',
        ),
        semanticLabel: localizations.text(
          'permission_notifications_title',
        ),
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFF8DB8F1),
      ),
      _ActionData(
        id: 'adhkar',
        title: localizations.adhkar,
        semanticLabel: localizations.adhkar,
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFFCB9AE8),
      ),
      _ActionData(
        id: 'tasbih',
        title: localizations.tasbih,
        semanticLabel: localizations.tasbih,
        icon: Icons.fingerprint_rounded,
        color: MuminColors.gold,
      ),
    ];
  }

  Widget _buildActionSet(
    List<_ActionData> actions, {
    required bool duplicate,
  }) {
    return SizedBox(
      width: _cycleWidth,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            SizedBox(
              width: _itemWidth,
              child: _QuickActionTile(
                key: ValueKey<String>(
                  '${duplicate ? 'duplicate_' : ''}${actions[index].id}',
                ),
                action: actions[index],
                animationDelay: index * 55,
                onTap: () => widget.onAction(actions[index].id),
              ),
            ),
            if (index < actions.length - 1)
              const SizedBox(width: _spacing),
          ],
        ],
      ),
    );
  }
    
    void _handlePointerDown(PointerDownEvent event) {
    if (_dragPointer != null) return;

    _dragPointer = event.pointer;
    _dragStartX = event.position.dx;
    _dragStartY = event.position.dy;
    _lastDragX = event.position.dx;
    _isHorizontalDrag = false;

    // Freeze the marquee while the user touches it.
    _animationController.stop(canceled: false);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _dragPointer) return;

    final startX = _dragStartX;
    final startY = _dragStartY;
    final lastX = _lastDragX;

    if (startX == null || startY == null || lastX == null) {
      return;
    }

    final totalDx = event.position.dx - startX;
    final totalDy = event.position.dy - startY;

    if (!_isHorizontalDrag) {
      if (totalDx.abs() < 6 ||
          totalDx.abs() <= totalDy.abs() * 1.15) {
        return;
      }

      _isHorizontalDrag = true;
    }

    final delta = event.position.dx - lastX;
    _lastDragX = event.position.dx;

    if (delta == 0 || !mounted) return;

    setState(() {
      _manualDragOffset =
          (_manualDragOffset + delta) % _cycleWidth;
    });
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer != _dragPointer) return;

    _dragPointer = null;
    _dragStartX = null;
    _dragStartY = null;
    _lastDragX = null;
    _isHorizontalDrag = false;

        // Resume after the tap gesture has been resolved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _motionDisabled || _dragPointer != null) {
        return;
      }

            setState(() {
        _manualDragOffset =
            (_manualDragOffset -
                    (_cycleWidth * _animationController.value)) %
                _cycleWidth;
      });

      _animationController.repeat(
        period: _animationDuration,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = _getLocalizations(context);
    final actions = _buildActions(localizations);

    return SizedBox(
      height: _itemHeight,
      child: ClipRect(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerEnd,
          onPointerCancel: _handlePointerEnd,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedBuilder(
              animation: _animationController,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionSet(
                    actions,
                    duplicate: false,
                  ),
                  _buildActionSet(
                    actions,
                    duplicate: true,
                  ),
                ],
              ),
              builder: (context, child) {
                final automaticOffset =
                    -_cycleWidth * _animationController.value;

                final rawOffset =
                    automaticOffset + _manualDragOffset;

                final wrappedOffset = rawOffset % _cycleWidth;

                final visibleOffset = wrappedOffset > 0
                    ? wrappedOffset - _cycleWidth
                    : wrappedOffset;

                return Transform.translate(
                  offset: Offset(visibleOffset, 0),
                  child: child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    super.key,
    required this.action,
    required this.onTap,
    required this.animationDelay,
  });

  final _ActionData action;
  final VoidCallback onTap;
  final int animationDelay;

  static const double _radius = 23;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = theme.colorScheme.onSurface;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final duration = reduceMotion
        ? Duration.zero
        : Duration(milliseconds: 280 + animationDelay);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: reduceMotion ? 1 : 0.94,
        end: 1,
      ),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Semantics(
        button: true,
        label: action.semanticLabel,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_radius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(_radius),
              splashColor: action.color.withValues(alpha: 0.16),
              highlightColor: action.color.withValues(alpha: 0.08),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_radius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF12382D),
                            Color(0xFF09251D),
                          ]
                        : const [
                            Color(0xFFFFFEFA),
                            Color(0xFFF0F4ED),
                          ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(
                      color: action.color.withValues(
                        alpha: isDark ? 0.34 : 0.25,
                      ),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: action.color.withValues(
                          alpha: isDark ? 0.09 : 0.07,
                        ),
                        blurRadius: 13,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -18,
                        right: -15,
                        child: IgnorePointer(
                          child: Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: action.color.withValues(
                                alpha: 0.055,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 9,
                        left: 9,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 11,
                          color: action.color.withValues(
                            alpha: 0.48,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 12,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    action.color.withValues(
                                      alpha: 0.23,
                                    ),
                                    action.color.withValues(
                                      alpha: 0.07,
                                    ),
                                  ],
                                ),
                                border: Border.all(
                                  color: action.color.withValues(
                                    alpha: 0.48,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: action.color.withValues(
                                      alpha: 0.13,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                action.icon,
                                color: action.color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Center(
                                child: Text(
                                  action.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  textDirection:
                                      Directionality.of(context),
                                  style: TextStyle(
                                    color: foreground,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }
}

class _ActionData {
  const _ActionData({
    required this.id,
    required this.title,
    required this.semanticLabel,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String semanticLabel;
  final IconData icon;
  final Color color;
}
