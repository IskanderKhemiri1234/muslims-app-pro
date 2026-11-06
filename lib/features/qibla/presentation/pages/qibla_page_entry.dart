
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/mumin_language_controller.dart';
import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/localization/mumin_qibla_localizations.dart';
import '../../domain/models/qibla_landmark.dart';
import '../widgets/qibla_landmark_search_feature.dart';
import 'qibla_page.dart' as compass;

class QiblaPageEntry extends StatelessWidget {
  const QiblaPageEntry({super.key});

  static const Color _gold = Color(0xFFD8B66A);
  static const Color _deepGreen = Color(0xFF063E31);

  MuminLocalizations _localizations(String languageCode) {
    return MuminLocalizations.fromCode(languageCode);
  }

  Future<void> _openSearch(
    BuildContext context,
    MuminLocalizations localizations,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark =
            Theme.of(sheetContext).brightness == Brightness.dark;

        return FractionallySizedBox(
          heightFactor: 0.88,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              border: Border.all(
                color: _gold.withValues(alpha: 0.28),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 11),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.travel_explore_rounded,
                        color: _gold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          localizations.qiblaText(
                            'qibla_atlas_search_title',
                          ),
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(sheetContext)
                            .closeButtonTooltip,
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: _gold.withValues(alpha: 0.18),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      16,
                    ),
                    child: QiblaLandmarkSearchFeature(
                      onLandmarkTap: (landmark) {
                        Navigator.of(sheetContext).pop();
                        _showLandmarkDetails(
                          context,
                          landmark,
                          localizations,
                          isDark,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLandmarkDetails(
    BuildContext context,
    QiblaLandmark landmark,
    MuminLocalizations localizations,
    bool isDark,
  ) {
    if (!context.mounted) return;

    final languageCode = localizations.languageCode;
    final name = landmark.nameForLanguage(languageCode);
    final description =
        landmark.descriptionForLanguage(languageCode).trim();
    final city = landmark.cityForLanguage(languageCode).trim();
    final region = landmark.regionForLanguage(languageCode).trim();

    final location = [
      city,
      region,
      landmark.countryCode,
    ].where((value) => value.isNotEmpty).join(' • ');

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final textColor =
            Theme.of(dialogContext).colorScheme.onSurface;

        return AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF1A2B24)
              : const Color(0xFFFFFCF3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            name,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  description.isEmpty
                      ? localizations.qiblaText(
                          'qibla_landmark_no_description',
                        )
                      : description,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.88),
                    height: 1.65,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: _gold,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '${landmark.latitude.toStringAsFixed(5)}, '
                  '${landmark.longitude.toStringAsFixed(5)}',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: _gold,
                    fontSize: 12,
                    fontFeatures: const [],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                localizations.qiblaText('qibla_landmark_close'),
                style: const TextStyle(
                  color: _deepGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageCode =
        context.watch<MuminLanguageController>().languageCode;
    final localizations = _localizations(languageCode);

    return Stack(
      fit: StackFit.expand,
      children: [
        const compass.QiblaPage(),
        PositionedDirectional(
          end: 18,
          bottom: 24,
          child: FloatingActionButton.extended(
            heroTag: 'mumin_qibla_atlas_search',
            backgroundColor: _deepGreen,
            foregroundColor: Colors.white,
            elevation: 5,
            onPressed: () => _openSearch(
              context,
              localizations,
            ),
            icon: const Icon(Icons.search_rounded),
            label: Text(
              localizations.qiblaText(
                'qibla_atlas_search_title',
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
