
import 'package:flutter/material.dart';

import '../../domain/models/qibla_landmark.dart';
import '../controllers/qibla_landmark_search_controller.dart';

/// Search field and localized result list for the Qibla Atlas.
///
/// The page supplies translated labels so this widget remains independent
/// from any duplicated localization system.
class QiblaLandmarkSearchSection extends StatefulWidget {
  const QiblaLandmarkSearchSection({
    super.key,
    required this.controller,
    required this.languageCode,
    required this.isDark,
    required this.searchHint,
    required this.emptyResultsLabel,
    required this.loadingLabel,
    required this.errorLabel,
    required this.onLandmarkTap,
  });

  final QiblaLandmarkSearchController controller;
  final String languageCode;
  final bool isDark;

  final String searchHint;
  final String emptyResultsLabel;
  final String loadingLabel;
  final String errorLabel;

  final ValueChanged<QiblaLandmark> onLandmarkTap;

  @override
  State<QiblaLandmarkSearchSection> createState() =>
      _QiblaLandmarkSearchSectionState();
}

class _QiblaLandmarkSearchSectionState
    extends State<QiblaLandmarkSearchSection> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  static const Color _gold = Color(0xFFD8B66A);
  static const Color _emerald = Color(0xFF075B46);

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.query,
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant QiblaLandmarkSearchSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.languageCode != widget.languageCode) {
      widget.controller.setLanguageCode(widget.languageCode);
    }

    if (oldWidget.controller != widget.controller) {
      _textController.text = widget.controller.query;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    widget.controller.search(
      value,
      languageCode: widget.languageCode,
    );
  }

  void _clearSearch() {
    _textController.clear();
    widget.controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.isDark
        ? const Color(0xFF1A2B24)
        : Colors.white;

    final foreground = widget.isDark
        ? Colors.white
        : const Color(0xFF19382E);

    final secondary = widget.isDark
        ? Colors.white70
        : Colors.black54;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: _gold.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: widget.isDark ? 0.12 : 0.035,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                textDirection: Directionality.of(context),
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: TextStyle(
                    color: secondary.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _gold,
                  ),
                  suffixIcon: controller.hasQuery
                      ? IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .deleteButtonTooltip,
                          onPressed: _clearSearch,
                          icon: Icon(
                            Icons.close_rounded,
                            color: secondary,
                            size: 19,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 16,
                  ),
                ),
                onChanged: _onQueryChanged,
              ),
            ),
            if (controller.hasQuery) ...[
              const SizedBox(height: 10),
              if (controller.isLoading)
                _statusRow(
                  icon: Icons.search_rounded,
                  label: widget.loadingLabel,
                  color: secondary,
                )
              else if (controller.hasError)
                _statusRow(
                  icon: Icons.error_outline_rounded,
                  label: widget.errorLabel,
                  color: Colors.redAccent,
                )
              else if (controller.isEmpty)
                _statusRow(
                  icon: Icons.travel_explore_rounded,
                  label: widget.emptyResultsLabel,
                  color: secondary,
                )
              else
                _buildResults(
                  controller.results,
                  foreground,
                  secondary,
                  background,
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _statusRow({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF1A2B24)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (widget.controller.isLoading)
            const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _gold,
              ),
            )
          else
            Icon(icon, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    List<QiblaLandmark> results,
    Color foreground,
    Color secondary,
    Color background,
  ) {
    final visibleResults = results.take(6).toList(growable: false);

    return Column(
      children: [
        for (var index = 0; index < visibleResults.length; index++) ...[
          if (index > 0) const SizedBox(height: 7),
          _buildResultTile(
            visibleResults[index],
            foreground,
            secondary,
            background,
          ),
        ],
      ],
    );
  }

  Widget _buildResultTile(
    QiblaLandmark landmark,
    Color foreground,
    Color secondary,
    Color background,
  ) {
    final name = landmark.nameForLanguage(widget.languageCode);
    final city = landmark.cityForLanguage(widget.languageCode);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => widget.onLandmarkTap(landmark),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _emerald.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: _gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    if (city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _gold,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
