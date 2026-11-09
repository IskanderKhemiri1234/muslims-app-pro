import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/mumin_design_tokens.dart';
import '../../../../core/localization/mumin_domain_localizations.dart';
import '../../../../core/localization/mumin_language_registry.dart';
import '../../../../core/localization/mumin_localizations.dart';

/// Six accessible home shortcuts with stable identities and real tap targets.
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onAction,
  });

  final ValueChanged<String> onAction;

  List<_ActionData> _buildActions(MuminLocalizations localizations) {
    return <_ActionData>[
      _ActionData(
        id: 'qibla',
        title: localizations.qibla,
        semanticLabel: localizations.qibla,
        icon: Icons.explore_rounded,
        assetPath: 'assets/images/home/reference_ui/processed/icon_qibla.png',
        color: const Color(0xFF58C9A1),
      ),
      _ActionData(
        id: 'quran',
        title: localizations.quran,
        semanticLabel: localizations.quran,
        icon: Icons.menu_book_rounded,
        assetPath: 'assets/images/home/reference_ui/processed/icon_quran.png',
        color: MuminColors.goldLight,
      ),
      _ActionData(
        id: 'mosques',
        title: localizations.domainText('nearby_mosques_title'),
        semanticLabel: localizations.domainText('nearby_mosques_title'),
        icon: Icons.mosque_rounded,
        assetPath: 'assets/images/home/reference_ui/processed/icon_kaaba.png',
        color: MuminColors.gold,
      ),
      _ActionData(
        id: 'adhan',
        title: localizations.text('adhan'),
        semanticLabel: localizations.text('adhan'),
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFFE5B95F),
      ),
      _ActionData(
        id: 'adhkar',
        title: localizations.adhkar,
        semanticLabel: localizations.adhkar,
        icon: Icons.volunteer_activism_rounded,
        assetPath: 'assets/images/home/reference_ui/processed/icon_azkar.png',
        color: const Color(0xFFCB9AE8),
      ),
      _ActionData(
        id: 'tasbih',
        title: localizations.tasbih,
        semanticLabel: localizations.tasbih,
        icon: Icons.fingerprint_rounded,
        assetPath: 'assets/images/home/reference_ui/processed/icon_tasbih.png',
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
      height: 132,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = constraints.maxWidth < 340 ? 76.0 : 84.0;
          final iconSize = (tileWidth - 16).clamp(58.0, 68.0).toDouble();

          return Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final action in actions)
                    SizedBox(
                      width: tileWidth,
                      child: _QuickActionTile(
                        action: action,
                        iconSize: iconSize,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onAction(action.id);
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.action,
    required this.iconSize,
    required this.onTap,
  });

  final _ActionData action;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;

    return Semantics(
      button: true,
      label: action.semanticLabel,
      onTap: onTap,
      child: Material(
        key: ValueKey<String>(action.id),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: action.color.withValues(alpha: 0.12),
          highlightColor: action.color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: action.assetPath != null
                      ? _TransparentIconArtwork(
                          assetPath: action.assetPath!,
                          fallback: action.icon,
                        )
                      : Icon(
                          action.icon,
                          size: iconSize * 0.66,
                          color: Color.lerp(
                            action.color,
                            MuminColors.goldLight,
                            0.28,
                          ),
                          shadows: [
                            Shadow(
                              color: action.color.withValues(alpha: 0.48),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textDirection: Directionality.of(context),
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.12,
                    ),
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

/// Displays preprocessed RGBA artwork without clipping, frames, or tile fills.
class _TransparentIconArtwork extends StatelessWidget {
  const _TransparentIconArtwork({
    required this.assetPath,
    required this.fallback,
  });

  final String assetPath;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Image.asset(
        assetPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => Icon(
          fallback,
          size: 38,
          color: MuminColors.goldLight,
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
    this.assetPath,
    required this.color,
  });

  final String id;
  final String title;
  final String semanticLabel;
  final IconData icon;
  final String? assetPath;
  final Color color;
}
