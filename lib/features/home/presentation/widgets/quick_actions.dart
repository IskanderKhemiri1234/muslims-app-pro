import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/mumin_design_tokens.dart';
import '../../../../core/localization/mumin_domain_localizations.dart';
import '../../../../core/localization/mumin_language_registry.dart';
import '../../../../core/localization/mumin_localizations.dart';

/// Five fixed home shortcuts, matching the reference layout.
/// Navigation IDs remain connected to the existing home action handler.
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onAction,
  });

  final ValueChanged<String> onAction;

  List<_ActionData> _buildActions(MuminLocalizations localizations) {
    return <_ActionData>[
      _ActionData(
        id: 'quran',
        title: localizations.quran,
        semanticLabel: localizations.quran,
        icon: Icons.menu_book_rounded,
        color: MuminColors.goldLight,
      ),
      _ActionData(
        id: 'adhkar',
        title: localizations.adhkar,
        semanticLabel: localizations.adhkar,
        icon: Icons.volunteer_activism_rounded,
        color: const Color(0xFFCB9AE8),
      ),
      _ActionData(
        id: 'mosques',
        title: localizations.domainText('nearby_mosques_title'),
        semanticLabel: localizations.domainText('nearby_mosques_title'),
        icon: Icons.mosque_rounded,
        color: MuminColors.gold,
      ),
      _ActionData(
        id: 'qibla',
        title: localizations.qibla,
        semanticLabel: localizations.qibla,
        icon: Icons.explore_rounded,
        color: const Color(0xFF58C9A1),
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
    final languageCode = MuminLanguageRegistry.normalizeLanguageCode(
      Localizations.localeOf(context).languageCode,
    );
    final localizations = MuminLocalizations.fromCode(languageCode);
    final actions = _buildActions(localizations);

    return SizedBox(
      height: 106,
      child: Row(
        children: [
          for (final action in actions)
            Expanded(
              child: _QuickActionTile(
                action: action,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onAction(action.id);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.action,
    required this.onTap,
  });

  final _ActionData action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final foreground = Theme.of(context).colorScheme.onSurface;

    return Semantics(
      button: true,
      label: action.semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: action.color.withValues(alpha: 0.13),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.35, -0.45),
                        radius: 0.95,
                        colors: [
                          Color.lerp(
                            action.color.withValues(alpha: 0.42),
                            MuminColors.goldLight.withValues(alpha: 0.38),
                            0.24,
                          )!,
                          action.color.withValues(alpha: 0.16),
                          const Color(0xFF06271E).withValues(alpha: 0.94),
                        ],
                        stops: const [0, 0.58, 1],
                      ),
                      border: Border.all(
                        color: MuminColors.goldLight.withValues(alpha: 0.62),
                        width: 1.35,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: action.color.withValues(alpha: 0.18),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: MuminColors.gold.withValues(alpha: 0.16),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: MuminColors.goldLight.withValues(
                                    alpha: 0.25,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 7,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 7,
                            color: MuminColors.goldLight.withValues(
                              alpha: 0.78,
                            ),
                          ),
                        ),
                        Icon(
                          action.icon,
                          size: 27,
                          color: Color.lerp(
                            action.color,
                            MuminColors.goldLight,
                            0.28,
                          ),
                          shadows: [
                            Shadow(
                              color: action.color.withValues(alpha: 0.7),
                              blurRadius: 9,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textDirection: Directionality.of(context),
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11.8,
                      fontWeight: FontWeight.w700,
                      height: 1.12,
                    ),
                  ),
                ],
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
