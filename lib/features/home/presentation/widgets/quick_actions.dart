import 'dart:math' as math;

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
    with TickerProviderStateMixin {
  static const double _itemHeight = 72;
  static const double _itemWidth = 68;
  static const double _spacing = 0;
  static const double _pixelsPerSecond = 22;

  static const int _actionCount = 6;

  static const double _cycleWidth =
      (_itemWidth * _actionCount) +
      (_spacing * (_actionCount - 1));

    late final Duration _animationDuration;
  late final AnimationController _animationController;
  late final AnimationController _artworkController;

  bool _motionDisabled = false;
  double _manualDragOffset = 0;
  bool _isUserDragging = false;

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

    _artworkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
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
      _artworkController.stop();
    } else {
      _animationController.repeat();
      _artworkController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _artworkController.dispose();
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
        icon: Icons.volunteer_activism_rounded,
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
            _buildActionTile(
              actions[index],
              index: index,
              duplicate: duplicate,
            ),
            if (index < actions.length - 1)
              const SizedBox(width: _spacing),
          ],
        ],
      ),
    );
  }
    
    Widget _buildActionTile(
    _ActionData action, {
    required int index,
    required bool duplicate,
  }) {
    return SizedBox(
      width: _itemWidth,
      child: _QuickActionTile(
        key: ValueKey<String>(
          '${duplicate ? 'duplicate_' : ''}${action.id}',
        ),
        action: action,
        animationDelay: index * 55,
        artworkMotion: _artworkController,
        onTap: () => _handleActionTap(action.id),
      ),
    );
  }

  void _handleActionTap(String actionId) {
    widget.onAction(actionId);
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _isUserDragging = true;
    _animationController.stop(canceled: false);
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (!mounted || !_isUserDragging) return;

    final delta = details.delta.dx;
    if (delta == 0) return;

    setState(() {
      _manualDragOffset =
          (_manualDragOffset + delta) % _cycleWidth;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    _isUserDragging = false;

    if (!mounted || _motionDisabled) return;

    setState(() {
      _manualDragOffset =
          (_manualDragOffset -
                  (_cycleWidth * _animationController.value)) %
              _cycleWidth;
    });

    _animationController.repeat(
      period: _animationDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = _getLocalizations(context);
    final actions = _buildActions(localizations);

    return SizedBox(
      height: _itemHeight,
      child: ClipRect(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _handleHorizontalDragStart,
          onHorizontalDragUpdate: _handleHorizontalDragUpdate,
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          onHorizontalDragCancel: () {
            _handleHorizontalDragEnd(
              DragEndDetails(),
            );
          },
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
    required this.artworkMotion,
  });

  final _ActionData action;
  final VoidCallback onTap;
  final int animationDelay;
  final Animation<double> artworkMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final entranceDuration = reduceMotion
        ? Duration.zero
        : Duration(milliseconds: 260 + animationDelay);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: reduceMotion ? 1 : 0.88,
        end: 1,
      ),
      duration: entranceDuration,
      curve: Curves.easeOutBack,
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
          child: SizedBox(
            height: _QuickActionsState._itemHeight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                splashColor: action.color.withValues(alpha: 0.13),
                highlightColor: action.color.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Center(
                          child: _AnimatedActionArtwork(
                            icon: action.icon,
                            color: action.color,
                            motion: artworkMotion,
                            phase: animationDelay / 55,
                            reduceMotion: reduceMotion,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            action.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            textDirection: Directionality.of(context),
                            style: TextStyle(
                              color: foreground,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              height: 1.12,
                              letterSpacing: 0.05,
                            ),
                          ),
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

class _AnimatedActionArtwork extends StatelessWidget {
  const _AnimatedActionArtwork({
    required this.icon,
    required this.color,
    required this.motion,
    required this.phase,
    required this.reduceMotion,
  });

  final IconData icon;
  final Color color;
  final Animation<double> motion;
  final double phase;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: motion,
      builder: (context, child) {
        final wave = math.sin(
          (motion.value * math.pi * 2) + phase,
        );
        final scale = reduceMotion ? 1.0 : 1 + (wave * 0.025);
        final verticalOffset = reduceMotion ? 0.0 : wave * 1.15;
        final glowOpacity = reduceMotion ? 0.16 : 0.12 + ((wave + 1) * 0.055);

        return Transform.translate(
          offset: Offset(0, verticalOffset),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.45),
                  radius: 0.95,
                  colors: [
                    Color.lerp(
                      color.withValues(alpha: 0.42),
                      MuminColors.goldLight.withValues(alpha: 0.38),
                      0.24,
                    )!,
                    color.withValues(alpha: 0.16),
                    const Color(0xFF06271E).withValues(alpha: 0.94),
                  ],
                  stops: const [0, 0.58, 1],
                ),
                border: Border.all(
                  color: MuminColors.goldLight.withValues(
                    alpha: 0.42 + glowOpacity * 0.35,
                  ),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: glowOpacity),
                    blurRadius: 13,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: MuminColors.gold.withValues(
                      alpha: glowOpacity * 0.42,
                    ),
                    blurRadius: 5,
                    spreadRadius: 0.4,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 5,
                    right: 7,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 7,
                      color: MuminColors.goldLight.withValues(
                        alpha: 0.62 + glowOpacity,
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    size: 22,
                    color: Color.lerp(
                      color,
                      MuminColors.goldLight,
                      0.28,
                    ),
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.7),
                        blurRadius: 9,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
