
import 'package:shared_preferences/shared_preferences.dart';

import 'mumin_notification_registry.dart';

/// Persistent, independent notification preferences.
///
/// This class stores user choices only.
/// It does not schedule notifications or send remote pushes.
class MuminNotificationPreferences {
  MuminNotificationPreferences({
    SharedPreferences? preferences,
  }) : _providedPreferences = preferences;

  static const String _enabledPrefix =
      'mumin_notification_enabled_';

  final SharedPreferences? _providedPreferences;

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async {
    return _preferences ??=
        _providedPreferences ??
        await SharedPreferences.getInstance();
  }

  /// Returns whether a notification type is enabled.
  ///
  /// Unknown IDs are rejected instead of silently creating
  /// preferences for unregistered notification types.
  Future<bool> isEnabled(String notificationId) async {
    final definition =
        _requireDefinition(notificationId);

    final preferences = await _store;

    return preferences.getBool(
          definition.enabledPreferenceKey,
        ) ??
        definition.defaultEnabled;
  }

  /// Saves the enabled state for one notification type.
  Future<void> setEnabled(
    String notificationId, {
    required bool enabled,
  }) async {
    final definition =
        _requireDefinition(notificationId);

    final preferences = await _store;

    final saved = await preferences.setBool(
      definition.enabledPreferenceKey,
      enabled,
    );

    if (!saved) {
      throw StateError(
        'Could not save notification preference: $notificationId',
      );
    }
  }

  /// Reads every registered notification preference.
  ///
  /// Defaults are applied when no explicit user choice exists.
  Future<Map<String, bool>> loadAll() async {
    final preferences = await _store;

    return Map<String, bool>.unmodifiable({
      for (final definition
          in MuminNotificationRegistry.all)
        definition.id:
            preferences.getBool(
                  definition.enabledPreferenceKey,
                ) ??
                definition.defaultEnabled,
    });
  }

  /// Returns enabled notification IDs.
  Future<Set<String>> getEnabledIds() async {
    final all = await loadAll();

    return Set<String>.unmodifiable(
      all.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key),
    );
  }

  /// Enables or disables all registered notifications
  /// belonging to a category.
  ///
  /// This only changes preferences. Delivery remains the
  /// responsibility of the corresponding notification service.
  Future<void> setCategoryEnabled(
    MuminNotificationCategory category, {
    required bool enabled,
  }) async {
    final definitions =
        MuminNotificationRegistry.byCategory(category);

    await _setDefinitions(
      definitions,
      enabled: enabled,
    );
  }

  /// Returns whether every notification in a category is enabled.
  ///
  /// An empty category is considered disabled.
  Future<bool> isCategoryEnabled(
    MuminNotificationCategory category,
  ) async {
    final definitions =
        MuminNotificationRegistry.byCategory(category);

    if (definitions.isEmpty) return false;

    for (final definition in definitions) {
      if (!await isEnabled(definition.id)) {
        return false;
      }
    }

    return true;
  }

  /// Returns true when at least one notification in a category
  /// is enabled.
  Future<bool> hasEnabledNotifications(
    MuminNotificationCategory category,
  ) async {
    final definitions =
        MuminNotificationRegistry.byCategory(category);

    for (final definition in definitions) {
      if (await isEnabled(definition.id)) {
        return true;
      }
    }

    return false;
  }

  /// Removes the saved choice for one notification.
  ///
  /// The definition's defaultEnabled value becomes active again.
  Future<void> reset(String notificationId) async {
    final definition =
        _requireDefinition(notificationId);

    final preferences = await _store;

    await preferences.remove(
      definition.enabledPreferenceKey,
    );
  }

  /// Removes saved choices for a whole category.
  Future<void> resetCategory(
    MuminNotificationCategory category,
  ) async {
    final definitions =
        MuminNotificationRegistry.byCategory(category);

    final preferences = await _store;

    for (final definition in definitions) {
      await preferences.remove(
        definition.enabledPreferenceKey,
      );
    }
  }

  /// Removes saved choices for all registered notification types.
  ///
  /// This does not clear unrelated application preferences.
  Future<void> resetAll() async {
    final preferences = await _store;

    for (final definition
        in MuminNotificationRegistry.all) {
      await preferences.remove(
        definition.enabledPreferenceKey,
      );
    }
  }

  Future<void> _setDefinitions(
    List<MuminNotificationDefinition> definitions, {
    required bool enabled,
  }) async {
    final preferences = await _store;

    for (final definition in definitions) {
      final saved = await preferences.setBool(
        definition.enabledPreferenceKey,
        enabled,
      );

      if (!saved) {
        throw StateError(
          'Could not save notification preference: ${definition.id}',
        );
      }
    }
  }

  MuminNotificationDefinition _requireDefinition(
    String notificationId,
  ) {
    final normalized = notificationId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        notificationId,
        'notificationId',
        'Notification ID cannot be empty.',
      );
    }

    final definition =
        MuminNotificationRegistry.find(normalized);

    if (definition == null) {
      throw ArgumentError.value(
        notificationId,
        'notificationId',
        'Notification type is not registered.',
      );
    }

    return definition;
  }

  /// Exposes the preference key convention for migration tools.
  static String preferenceKeyFor(String notificationId) =>
      '$_enabledPrefix$notificationId';
}
