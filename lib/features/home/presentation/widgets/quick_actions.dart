
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

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        id: 'qibla',
        title: isArabic ? 'القبلة' : 'Qibla',
        icon: Icons.explore_rounded,
        color: const Color(0xFF58C9A1),
      ),
      _ActionData(
        id: 'quran',
        title: isArabic ? 'القرآن' : 'Quran',
        icon: Icons.menu_book_rounded,
        color: AppColors.goldLight,
      ),
      _ActionData(
        id: 'adhan',
        title: isArabic ? 'الأذان' : 'Adhan',
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFF8DB8F1),
      ),
      _ActionData(
        id: 'adhkar',
        title: isArabic ? 'الأذكار' : 'Adhkar',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFFCB9AE8),
      ),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = actions[index];

          return SizedBox(
            width: 83,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: Duration(milliseconds: 350 + index * 100),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => onAction(action.id),
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
                        Text(
                          action.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
