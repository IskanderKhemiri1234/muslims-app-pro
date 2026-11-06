
import 'package:flutter/material.dart';

import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'glass_container.dart';

/// Responsive, localized quick-action shortcuts for the home page.
///
/// The existing constructor API is preserved to avoid breaking callers.
/// The active language is resolved from the application's current locale.
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.isArabic,
    required this.onAction,
  });

  /// Retained for backward compatibility with existing callers.
  ///
  /// The active MaterialApp locale takes precedence when available.
  final bool isArabic;

  /// Receives the stable action identifier.
  ///
  /// Supported identifiers: qibla, quran, adhan, adhkar.
  final ValueChanged<String> onAction;

  static const double _itemHeight = 112;
  static const double _spacing = 12;
  static const double _minimumItemWidth = 72;
  static const double _maximumItemWidth = 96;
  static const double _defaultItemWidth = 83;

  List<_ActionData> _buildActions(
    MuminLocalizations localizations,
  ) {
    final isArabicLanguage = localizations.isArabic;
    final isFrenchLanguage = localizations.isFrench;

    return <_ActionData>[
      _ActionData(
        id: 'qibla',
        title: isArabicLanguage
            ? 'القبلة'
            : 'Qibla',
        semanticLabel: localizations.qibla,
        icon: Icons.explore_rounded,
        color: const Color(0xFF58C9A1),
      ),
      _ActionData(
        id: 'quran',
        title: isArabicLanguage
            ? 'القرآن'
            : isFrenchLanguage
                ? 'Coran'
                : 'Quran',
        semanticLabel: localizations.quran,
        icon: Icons.menu_book_rounded,
        color: AppColors.goldLight,
      ),
      _ActionData(
        id: 'adhan',
        title: isArabicLanguage
            ? 'الأذان'
            : 'Adhan',
        semanticLabel: isArabicLanguage
            ? 'إعدادات الأذان'
            : isFrenchLanguage
                ? 'Paramètres de l’adhan'
                : 'Adhan settings',
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFF8DB8F1),
      ),
      _ActionData(
        id: 'adhkar',
        title: isArabicLanguage
            ? 'الأذكار'
            : isFrenchLanguage
                ? 'Invocations'
                : 'Adhkar',
        semanticLabel: localizations.adhkar,
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFFCB9AE8),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    final languageCode = locale.languageCode.isEmpty
        ? (isArabic ? 'ar' : 'en')
        : locale.languageCode;

    final localizations = MuminLocalizations.fromCode(languageCode);
    final actions = _buildActions(localizations);

    return SizedBox(
      height: _itemHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;

          final calculatedWidth = availableWidth.isFinite &&
                  availableWidth > 0
              ? (availableWidth - (_spacing * 3)) / 4
              : _defaultItemWidth;

          final itemWidth = calculatedWidth
              .clamp(
                _minimumItemWidth,
                _maximumItemWidth,
              )
              .toDouble();

          return ListView.separated(
            scrollDirection: Axis.horizontal,

            // Flutter resolves the horizontal scroll direction from the
            // surrounding Directionality. Do not reverse it a second time.
            reverse: false,

            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: actions.length,
            separatorBuilder: (context, index) {
              return const SizedBox(width: _spacing);
            },
            itemBuilder: (context, index) {
              final action = actions[index];

              return SizedBox(
                width: itemWidth,
                child: _QuickActionTile(
                  key: ValueKey<String>(action.id),
                  action: action,
                  onTap: () => onAction(action.id),
                  animationDelay: index * 70,
                ),
              );
            },
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

  static const double _borderRadius = 22;
  static const double _iconContainerSize = 43;
  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final animationDuration = reduceMotion
        ? Duration.zero
        : Duration(milliseconds: 300 + animationDelay);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: reduceMotion ? 1 : 0.92,
        end: 1,
      ),
      duration: animationDuration,
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
            borderRadius: BorderRadius.circular(_borderRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(_borderRadius),
              splashColor: action.color.withValues(alpha: 0.12),
              highlightColor: action.color.withValues(alpha: 0.06),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                child: GlassContainer(
                  radius: _borderRadius,
                  enableBlur: false,
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 4,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: _iconContainerSize,
                        height: _iconContainerSize,
                        decoration: BoxDecoration(
                          color: action.color.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          action.icon,
                          color: action.color,
                          size: _iconSize,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Flexible(
                        child: Center(
                          child: Text(
                            action.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            textDirection: Directionality.of(context),
                            style: TextStyle(
                              color: foreground,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
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
