
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/mumin_language_controller.dart';
import '../../../../core/localization/mumin_qibla_localizations.dart';
import '../../data/datasources/qibla_landmark_local_data_source.dart';
import '../../data/repositories/qibla_landmark_repository_impl.dart';
import '../../domain/models/qibla_landmark.dart';
import '../controllers/qibla_landmark_search_controller.dart';
import 'qibla_landmark_search_section.dart';

/// Complete search feature for the Qibla Atlas.
///
/// Architecture:
/// - Reads the active language exclusively from MuminLanguageController.
/// - Uses the centralized Arabic, English and French Qibla catalog.
/// - Owns the search controller lifecycle.
/// - Loads landmark data through the local data source and repository.
/// - Keeps search presentation separate from the Qibla page.
/// - Refreshes the active query when the application language changes.
class QiblaLandmarkSearchFeature extends StatefulWidget {
  const QiblaLandmarkSearchFeature({
    super.key,
    required this.onLandmarkTap,
  });

  final ValueChanged<QiblaLandmark> onLandmarkTap;

  @override
  State<QiblaLandmarkSearchFeature> createState() =>
      _QiblaLandmarkSearchFeatureState();
}

class _QiblaLandmarkSearchFeatureState
    extends State<QiblaLandmarkSearchFeature> {
  QiblaLandmarkSearchController? _searchController;
  MuminLanguageController? _languageController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final languageController =
        Provider.of<MuminLanguageController>(context);

    final languageChanged =
        !identical(_languageController, languageController);

    if (_searchController == null) {
      _languageController = languageController;

      final repository = QiblaLandmarkRepositoryImpl(
        dataSource: QiblaLandmarkLocalDataSource(),
      );

      _searchController = QiblaLandmarkSearchController(
        repository: repository,
        initialLanguageCode: languageController.languageCode,
      );

      return;
    }

    if (languageChanged) {
      _languageController = languageController;
    }

    final activeSearch = _searchController!;

    if (activeSearch.languageCode !=
        languageController.languageCode) {
      unawaited(
        activeSearch.setLanguageCode(
          languageController.languageCode,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languages = _languageController;

    final searchController = _searchController;

    if (languages == null || searchController == null) {
      return const SizedBox.shrink();
    }

    final localizations = languages.localizations;
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final textColor = Theme.of(context).colorScheme.onSurface;

    return Semantics(
      container: true,
      label: localizations.qiblaText(
        'qibla_landmark_search_semantics',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: 11,
              start: 2,
              end: 2,
            ),
            child: Text(
              localizations.qiblaText(
                'qibla_atlas_search_title',
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          QiblaLandmarkSearchSection(
            controller: searchController,
            languageCode: languages.languageCode,
            isDark: isDark,
            searchHint: localizations.qiblaText(
              'qibla_atlas_search_hint',
            ),
            emptyResultsLabel: localizations.qiblaText(
              'qibla_atlas_search_empty',
            ),
            loadingLabel: localizations.qiblaText(
              'qibla_atlas_search_loading',
            ),
            errorLabel: localizations.qiblaText(
              'qibla_atlas_search_error',
            ),
            onLandmarkTap: widget.onLandmarkTap,
          ),
        ],
      ),
    );
  }
}
