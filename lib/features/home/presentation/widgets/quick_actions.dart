
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'glass_container.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.isArabic,
    required this.onAction,
  });

  final bool isArabic;
  final ValueChanged<String> onAction;

  static const double _itemWidth = 83;
  static const double _itemHeight = 112;
  static const double _spacing = 12;

  List<_ActionData> get _actions => [
        _ActionData(
          id: 'qibla',
          title: isArabic ? 'القبلة' : 'Qibla',
          semanticLabel: isArabic ? 'فتح اتجاه القبلة' : 'Open Qibla direction',
          icon: Icons.explore_rounded,
          color: const Color(0xFF58C9A1),
        ),
        _ActionData(
          id: 'quran',
          title: isArabic ? 'القرآن' : 'Quran',
          semanticLabel: isArabic ? 'فتح القرآن الكريم' : 'Open Quran',
          icon: Icons.menu_book_rounded,
          color: AppColors.goldLight,
        ),
        _ActionData(
          id: 'adhan',
          title: isArabic ? 'الأذان' : 'Adhan',
          semanticLabel: isArabic ? 'إعدادات الأذان' : 'Adhan settings',
          icon: Icons.notifications_active_rounded,
          color: const Color(0xFF8DB8F1),
        ),
        _ActionData(
          id: 'adhkar',
          title: isArabic ? 'الأذكار' : 'Adhkar',
          semanticLabel: isArabic ? 'فتح الأذكار' : 'Open Adhkar',
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFFCB9AE8),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final actions = _actions;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      height: _itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: isRtl,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: actions.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: _spacing),
        itemBuilder: (context, index) {
          final action = actions[index];

          return SizedBox(
            width: _itemWidth,
            child: _QuickActionTile(
              action: action,
              onTap: () => onAction(action.id),
              animationDelay: index * 70,
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
    required this.onTap,
    required this.animationDelay,
  });

  final _ActionData action;
  final VoidCallback onTap;
  final int animationDelay;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.92, end: 1),
      duration: Duration(milliseconds: 300 + animationDelay),
      curve: Curves.easeOutCubic,
      child: Semantics(
        button: true,
        label: action.semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: GlassContainer(
              radius: 22,
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      action.icon,
                      color: action.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
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
