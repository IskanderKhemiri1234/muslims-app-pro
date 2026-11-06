
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'mumin_localizations.dart';

/// Official Flutter localization delegate for Mumin Pro.
///
/// The central MuminLocalizations engine remains the single
/// source of application translations and language metadata.
final class MuminLocalizationsDelegate
    extends LocalizationsDelegate<MuminLocalizations> {
  const MuminLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return MuminLocalizations.isSupported(
      locale.languageCode,
    );
  }

  @override
  Future<MuminLocalizations> load(Locale locale) {
    final languageCode =
        MuminLocalizations.normalizeLanguageCode(
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
