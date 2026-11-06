
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'mumin_language_registry.dart';
import 'mumin_localizations.dart';

/// Official Flutter localization delegate for Mumin Pro.
///
/// Language availability and metadata are owned exclusively by
/// MuminLanguageRegistry. Translation resolution is owned by
/// MuminLocalizations.
final class MuminLocalizationsDelegate
    extends LocalizationsDelegate<MuminLocalizations> {
  const MuminLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return MuminLanguageRegistry.isSupported(
      locale.languageCode,
    );
  }

  @override
  Future<MuminLocalizations> load(Locale locale) {
    final languageCode =
        MuminLanguageRegistry.normalizeLanguageCode(
      locale.languageCode,
    );

    return SynchronousFuture<MuminLocalizations>(
      MuminLocalizations.fromCode(languageCode),
    );
  }

  @override
  bool shouldReload(
    covariant MuminLocalizationsDelegate old,
  ) {
    return false;
  }
}
