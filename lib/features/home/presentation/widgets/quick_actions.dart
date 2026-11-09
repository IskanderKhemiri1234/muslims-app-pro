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
        assetPath: 'assets/images/home/reference_ui/icon_qibla.png',
        color: const Color(0xFF58C9A1),
      ),
      _ActionData(
        id: 'quran',
        title: localizations.quran,
        semanticLabel: localizations.quran,
        icon: Icons.menu_book_rounded,
        assetPath: 'assets/images/home/reference_ui/icon_quran.png',
        color: MuminColors.goldLight,
      ),
      _ActionData(
        id: 'mosques',
        title: localizations.domainText('nearby_mosques_title'),
        semanticLabel: localizations.domainText('nearby_mosques_title'),
        icon: Icons.mosque_rounded,
        assetPath: 'assets/images/home/reference_ui/icon_kaaba.png',
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
        assetPath: 'assets/images/home/reference_ui/icon_azkar.png',
        color: const Color(0xFFCB9AE8),
      ),
      _ActionData(
        id: 'tasbih',
        title: localizations.tasbih,
        semanticLabel: localizations.tasbih,
        icon: Icons.fingerprint_rounded,
        assetPath: 'assets/images/home/reference_ui/icon_tasbih.png',
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
          final iconSize = (tileWidth - 20).clamp(54.0, 64.0).toDouble();

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
          borderRadius: BorderRadius.circular(22),
          splashColor: action.color.withValues(alpha: 0.16),
          highlightColor: action.color.withValues(alpha: 0.07),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.45),
                      radius: 0.95,
                      colors: [
                        Color.lerp(
                          action.color.withValues(alpha: 0.46),
                          MuminColors.goldLight.withValues(alpha: 0.38),
                          0.24,
                        )!,
                        action.color.withValues(alpha: 0.17),
                        const Color(0xFF06271E).withValues(alpha: 0.96),
                      ],
                      stops: const [0, 0.58, 1],
                    ),
                    border: Border.all(
                      color: MuminColors.goldLight.withValues(alpha: 0.76),
                      width: 1.35,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: action.color.withValues(alpha: 0.20),
                        blurRadius: 16,
                        spreadRadius: 0.5,
                      ),
                      BoxShadow(
                        color: MuminColors.gold.withValues(alpha: 0.14),
                        blurRadius: 4,
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
                                  alpha: 0.26,
                                ),
                                width: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 5,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 6,
                          color: MuminColors.goldLight.withValues(alpha: 0.82),
                        ),
                      ),
                      if (action.assetPath != null)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: _RotatingIconArtwork(
                              assetPath: action.assetPath!,
                              fallback: action.icon,
                            ),
                          ),
                        )
                      else
                        Icon(
                          action.icon,
                          size: iconSize * 0.47,
                          color: Color.lerp(
                            action.color,
                            MuminColors.goldLight,
                            0.28,
                          ),
                          shadows: [
                            Shadow(
                              color: action.color.withValues(alpha: 0.72),
                              blurRadius: 8,
                            ),
                          ],
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

/// Moves the artwork gently backward and returns it to neutral.
/// The circular frame, border, glow and sparkle remain perfectly still.
class _RotatingIconArtwork extends StatelessWidget {
  const _RotatingIconArtwork({
    required this.assetPath,
    required this.fallback,
  });

  final String assetPath;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipOval(
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: Transform.scale(
            scale: 1.12,
            child: Image.asset(
              assetPath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => Icon(
                fallback,
                size: 30,
                color: MuminColors.goldLight,
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
