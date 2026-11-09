import 'package:flutter/material.dart';

import '../../../../core/localization/mumin_domain_localizations.dart';
import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/design_system/mumin_design_tokens.dart';

/// Stable, touch-friendly shortcuts.
///
/// The previous continuously translating marquee moved hit targets while
/// the user was touching them. A normal horizontal scroll view keeps every
/// action stationary until the user deliberately scrolls.
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onAction,
  });

  final ValueChanged<String> onAction;

  List<_ActionData> _actions(MuminLocalizations localizations) {
    return <_ActionData>[
      _ActionData(
        id: 'qibla',
        title: localizations.qibla,
        icon: Icons.explore_rounded,
        color: const Color(0xFF58C9A1),
      ),
      _ActionData(
        id: 'quran',
        title: localizations.quran,
        icon: Icons.menu_book_rounded,
        color: MuminColors.goldLight,
      ),
      _ActionData(
        id: 'mosques',
        title: localizations.domainText('nearby_mosques_title'),
        icon: Icons.mosque_rounded,
        color: MuminColors.gold,
      ),
      _ActionData(
        id: 'adhan',
        title: localizations.text('permission_notifications_title'),
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFF8DB8F1),
      ),
      _ActionData(
        id: 'adhkar',
        title: localizations.adhkar,
        icon: Icons.volunteer_activism_rounded,
        color: const Color(0xFFCB9AE8),
      ),
      _ActionData(
        id: 'tasbih',
        title: localizations.tasbih,
        icon: Icons.fingerprint_rounded,
        color: MuminColors.gold,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final localizations = MuminLocalizations.fromCode(code);
    final actions = _actions(localizations);

    return SizedBox(
      height: 94,
      child: Scrollbar(
        thumbVisibility: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final action in actions)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _QuickActionTile(
                    action: action,
                    onTap: () => onAction(action.id),
                  ),
                ),
            ],
          ),
        ),
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
    final foreground = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      width: 78,
      height: 88,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        action.color.withValues(alpha: 0.34),
                        const Color(0xFF06271E),
                      ],
                    ),
                    border: Border.all(
                      color: MuminColors.goldLight.withValues(alpha: 0.52),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: action.color.withValues(alpha: 0.16),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    action.icon,
                    size: 25,
                    color: action.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
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

class _ActionData {
  const _ActionData({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;
}
