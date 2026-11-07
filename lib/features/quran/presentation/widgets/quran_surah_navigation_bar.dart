
import 'package:flutter/material.dart';

@immutable
class QuranSurahNavigationItem {
  const QuranSurahNavigationItem({
    required this.number,
    required this.name,
    required this.startPage,
  });

  final int number;
  final String name;
  final int startPage;
}

class QuranSurahNavigationBar extends StatefulWidget {
  const QuranSurahNavigationBar({
    super.key,
    required this.title,
    required this.items,
    required this.currentPage,
    required this.onSurahSelected,
  });

  final String title;
  final List<QuranSurahNavigationItem> items;
  final int currentPage;
  final ValueChanged<int> onSurahSelected;

  @override
  State<QuranSurahNavigationBar> createState() =>
      _QuranSurahNavigationBarState();
}

class _QuranSurahNavigationBarState
    extends State<QuranSurahNavigationBar> {
  static const Color _emerald = Color(0xFF075B46);
  static const Color _deepEmerald = Color(0xFF063E31);
  static const Color _gold = Color(0xFFD8B66A);

  final ScrollController _scrollController =
      ScrollController();

  final Map<int, GlobalKey> _itemKeys = {};

  int get _selectedIndex {
    if (widget.items.isEmpty) return -1;

    var selected = 0;

    for (var index = 0; index < widget.items.length; index++) {
      if (widget.items[index].startPage <= widget.currentPage) {
        selected = index;
      } else {
        break;
      }
    }

    return selected;
  }

  @override
  void initState() {
    super.initState();
    _scheduleSelectedItemVisibility();
  }

  @override
  void didUpdateWidget(
    covariant QuranSurahNavigationBar oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentPage != widget.currentPage ||
        oldWidget.items != widget.items) {
      _scheduleSelectedItemVisibility();
    }
  }

  void _scheduleSelectedItemVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final index = _selectedIndex;
      if (index < 0 || index >= widget.items.length) return;

      final key = _itemKeys[index];
      final itemContext = key?.currentContext;

      if (itemContext == null) return;

      Scrollable.ensureVisible(
        itemContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignmentPolicy:
            ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  GlobalKey _keyFor(int index) {
    return _itemKeys.putIfAbsent(
      index,
      () => GlobalKey(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final selectedIndex = _selectedIndex;

    final background = isDark
        ? const Color(0xFF14251D)
        : const Color(0xFFFFFCF5);

    final foreground = isDark
        ? const Color(0xFFECE5D5)
        : const Color(0xFF183D30);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _gold.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.12 : 0.045,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${widget.items.length}',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final selected = index == selectedIndex;

                return Padding(
                  key: _keyFor(index),
                  padding: const EdgeInsetsDirectional.only(
                    end: 8,
                  ),
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label:
                        '${item.number}. ${item.name}',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          widget.onSurahSelected(
                            item.startPage,
                          );
                        },
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: 108,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _emerald,
                                      _deepEmerald,
                                    ],
                                  )
                                : null,
                            color: selected ? null : background,
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? _gold
                                  : _gold.withValues(
                                      alpha: 0.18,
                                    ),
                              width: selected ? 1.3 : 0.8,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                item.number.toString(),
                                style: TextStyle(
                                  color: selected
                                      ? _gold
                                      : foreground.withValues(
                                          alpha: 0.65,
                                        ),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : foreground,
                                      fontSize: 12,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
