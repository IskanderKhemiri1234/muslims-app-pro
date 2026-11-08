
import 'package:flutter/material.dart';

import '../../../../core/localization/mumin_language_registry.dart';
import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/design_system/mumin_design_tokens.dart';

/// Mumin Pro — Premium horizontally scrollable quick actions.
///
/// Add future actions by adding one _ActionData entry.
/// Stable action IDs keep navigation independent from presentation.
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onAction,
  });

  final ValueChanged<String> onAction;

  static const double _itemHeight = 124;
  static const double _itemWidth = 104;
  static const double _spacing = 12;

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
        id: 'adhan',
        title: localizations.text('permission_notifications_title'),
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

  @override
  Widget build(BuildContext context) {
    final languageCode =
        MuminLanguageRegistry.normalizeLanguageCode(
      Localizations.localeOf(context).languageCode,
    );

    final localizations =
        MuminLocalizations.fromCode(languageCode);

    final actions = _buildActions(localizations);

    return SizedBox(
      height: _itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: false,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: actions.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: _spacing),
        itemBuilder: (context, index) {
          final action = actions[index];

          return SizedBox(
            width: _itemWidth,
            child: _QuickActionTile(
              key: ValueKey<String>(action.id),
              action: action,
              animationDelay: index * 55,
              onTap: () => onAction(action.id),
            ),
          );
        },
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
                              width: 49,
                              height: 49,
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
                                size: 25,
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
