
/// Central registry for every notification type in Mumin Pro.
///
/// This registry describes notification capabilities and metadata.
/// Actual delivery and scheduling are handled by dedicated services.
enum MuminNotificationCategory {
  worship,
  quran,
  prayer,
  islamicCalendar,
  reminders,
  system,
}

enum MuminNotificationDelivery {
  localScheduled,
  localEvent,
  remotePush,
  inApp,
}

enum MuminNotificationPriority {
  low,
  normal,
  high,
}

class MuminNotificationDefinition {
  const MuminNotificationDefinition({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.category,
    required this.delivery,
    required this.priority,
    required this.channelId,
    this.defaultEnabled = false,
    this.requiresLocation = false,
    this.requiresNetwork = false,
    this.supportsQuietHours = true,
  });

  /// Stable identifier. Never use translated text as an identifier.
  final String id;

  /// Translation catalog key for the notification title.
  final String titleKey;

  /// Translation catalog key for the notification description.
  final String descriptionKey;

  final MuminNotificationCategory category;
  final MuminNotificationDelivery delivery;
  final MuminNotificationPriority priority;

  /// Android notification channel identifier.
  final String channelId;

  final bool defaultEnabled;
  final bool requiresLocation;
  final bool requiresNetwork;
  final bool supportsQuietHours;

  String get enabledPreferenceKey =>
      'mumin_notification_enabled_$id';

  String get channelNameKey =>
      'notification_channel_$id';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MuminNotificationDefinition &&
          other.id == id;

  @override
  int get hashCode => id.hashCode;
}

abstract final class MuminNotificationRegistry {
  static final Map<String, MuminNotificationDefinition>
      _definitions = {
    for (final definition in _builtInDefinitions)
      definition.id: definition,
  };

  static const List<MuminNotificationDefinition>
      _builtInDefinitions = [
    // Prayer notifications.
    MuminNotificationDefinition(
      id: 'prayer_fajr',
      titleKey: 'notification_prayer_fajr_title',
      descriptionKey: 'notification_prayer_fajr_description',
      category: MuminNotificationCategory.prayer,
      delivery: MuminNotificationDelivery.localScheduled,
      priority: MuminNotificationPriority.high,
      channelId: 'mumin_prayer_time_alerts',
      requiresLocation: true,
    ),
    MuminNotificationDefinition(
      id: 'prayer_dhuhr',
      titleKey: 'notification_prayer_dhuhr_title',
      descriptionKey: 'notification_prayer_dhuhr_description',
      category: MuminNotificationCategory.prayer,
      delivery: MuminNotificationDelivery.localScheduled,
      priority: MuminNotificationPriority.high,
      channelId: 'mumin_prayer_time_alerts',
      requiresLocation: true,
    ),
    MuminNotificationDefinition(
      id: 'prayer_asr',
      titleKey: 'notification_prayer_asr_title',
      descriptionKey: 'notification_prayer_asr_description',
      category: MuminNotificationCategory.prayer,
      delivery: MuminNotificationDelivery.localScheduled,
      priority: MuminNotificationPriority.high,
      channelId: 'mumin_prayer_time_alerts',
      requiresLocation: true,
    ),
    MuminNotificationDefinition(
      id: 'prayer_maghrib',
      titleKey: 'notification_prayer_maghrib_title',
      descriptionKey: 'notification_prayer_maghrib_description',
      category: MuminNotificationCategory.prayer,
      delivery: MuminNotificationDelivery.localScheduled,
      priority: MuminNotificationPriority.high,
      channelId: 'mumin_prayer_time_alerts',
      requiresLocation: true,
    ),
    MuminNotificationDefinition(
      id: 'prayer_isha',
      titleKey: 'notification_prayer_isha_title',
      descriptionKey: 'notification_prayer_isha_description',
      category: MuminNotificationCategory.prayer,
      delivery: MuminNotificationDelivery.localScheduled,
      priority: MuminNotificationPriority.high,
      channelId: 'mumin_prayer_time_alerts',
      requiresLocation: true,
    ),

    // Daily worship reminders.
    MuminNotificationDefinition(
      id: 'daily_adhkar',
      titleKey: 'notification_daily_adhkar_title',
      descriptionKey: 'notification_daily_adhkar_description',
      category: MuminNotificationCategory.worship,
      delivery: MuminNotificationDelivery.localScheduled,
      priority: MuminNotificationPriority.normal,
      channelId: 'mumin_worship_reminders',
    ),
    MuminNotificationDefinition(
      id: 'morning_adhkar',
      titleKey: 'notification_morning_adhkar_title',
      descriptionKey: 'notification_morning_adhkar_description',
      category: MuminNotificationCategory.worship,
      delivery: MuminNotificationDelivery.localScheduled,
      priority: MuminNotificationPriority.normal,
      channelId: 'mumin_worship_reminders',
    ),
    MuminNotificationDefinition(
      id: 'evening_adhkar',
      titleKey: 'notification_evening_adhkar_title',
      descriptionKey: 'notification_evening_adhkar_description',
      category: MuminNotificationCategory.worship,
      delivery: MuminNotificationDelivery.localScheduled,
      priority: MuminNotificationPriority.normal,
      channelId: 'mumin_worship_reminders',
    ),

    // Quran reminders.
    MuminNotificationDefinition(
      id: 'daily_quran',
      titleKey: 'notification_daily_quran_title',
      descriptionKey: 'notification_daily_quran_description',
      category: MuminNotificationCategory.quran,
      delivery: MuminNotificationDelivery.localScheduled,
      priority: MuminNotificationPriority.normal,
      channelId: 'mumin_quran_reminders',
    ),
    MuminNotificationDefinition(
      id: 'quran_reading_goal',
      titleKey: 'notification_quran_goal_title',
      descriptionKey: 'notification_quran_goal_description',
      category: MuminNotificationCategory.quran,
      delivery: MuminNotificationDelivery.localEvent,
      priority: MuminNotificationPriority.normal,
      channelId: 'mumin_quran_reminders',
    ),
    MuminNotificationDefinition(
      id: 'khatma_progress',
      titleKey: 'notification_khatma_progress_title',
      descriptionKey: 'notification_khatma_progress_description',
      category: MuminNotificationCategory.quran,
      delivery: MuminNotificationDelivery.localEvent,
      priority: MuminNotificationPriority.normal,
      channelId: 'mumin_quran_reminders',
    ),

    // Islamic calendar.
    MuminNotificationDefinition(
      id: 'islamic_events',
      titleKey: 'notification_islamic_events_title',
      descriptionKey: 'notification_islamic_events_description',
      category: MuminNotificationCategory.islamicCalendar,
      delivery: MuminNotificationDelivery.localScheduled,
      priority: MuminNotificationPriority.normal,
      channelId: 'mumin_islamic_calendar',
    ),
    MuminNotificationDefinition(
      id: 'fasting_reminder',
      titleKey: 'notification_fasting_title',
      descriptionKey: 'notification_fasting_description',
      category: MuminNotificationCategory.islamicCalendar,
      delivery: MuminNotificationDelivery.localScheduled,
      priority: MuminNotificationPriority.normal,
      channelId: 'mumin_islamic_calendar',
    ),

    // User-created reminders.
    MuminNotificationDefinition(
      id: 'personal_reminders',
      titleKey: 'notification_personal_reminders_title',
      descriptionKey: 'notification_personal_reminders_description',
      category: MuminNotificationCategory.reminders,
      delivery: MuminNotificationDelivery.localScheduled,
      priority: MuminNotificationPriority.normal,
      channelId: 'mumin_personal_reminders',
    ),

    // Optional server-delivered announcements.
    MuminNotificationDefinition(
      id: 'service_announcements',
      titleKey: 'notification_service_announcements_title',
      descriptionKey: 'notification_service_announcements_description',
      category: MuminNotificationCategory.system,
      delivery: MuminNotificationDelivery.remotePush,
      priority: MuminNotificationPriority.low,
      channelId: 'mumin_service_announcements',
      requiresNetwork: true,
    ),
  ];

  /// All registered definitions, including approved extensions.
  static List<MuminNotificationDefinition> get all =>
      List<MuminNotificationDefinition>.unmodifiable(
        _definitions.values,
      );

  /// Built-in definitions cannot be removed or overwritten.
  static List<MuminNotificationDefinition> get builtIns =>
      List<MuminNotificationDefinition>.unmodifiable(
        _builtInDefinitions,
      );

  static MuminNotificationDefinition? find(String id) =>
      _definitions[id.trim()];

  static bool contains(String id) =>
      _definitions.containsKey(id.trim());

  static List<MuminNotificationDefinition> byCategory(
    MuminNotificationCategory category,
  ) =>
      List<MuminNotificationDefinition>.unmodifiable(
        _definitions.values.where(
          (definition) => definition.category == category,
        ),
      );

  static List<MuminNotificationDefinition> byDelivery(
    MuminNotificationDelivery delivery,
  ) =>
      List<MuminNotificationDefinition>.unmodifiable(
        _definitions.values.where(
          (definition) => definition.delivery == delivery,
        ),
      );

  /// Registers a new feature notification without modifying
  /// existing notification definitions.
  ///
  /// IDs must be unique and stable across app releases.
  static void register(
    MuminNotificationDefinition definition,
  ) {
    final id = definition.id.trim();

    if (id.isEmpty) {
      throw ArgumentError.value(
        definition.id,
        'id',
        'Notification ID cannot be empty.',
      );
    }

    if (id != definition.id ||
        !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id)) {
      throw ArgumentError.value(
        definition.id,
        'id',
        'Use lowercase letters, numbers and underscores.',
      );
    }

    if (_definitions.containsKey(id)) {
      throw StateError(
        'Notification "$id" is already registered.',
      );
    }

    if (definition.titleKey.trim().isEmpty ||
        definition.descriptionKey.trim().isEmpty ||
        definition.channelId.trim().isEmpty) {
      throw ArgumentError(
        'Notification translation keys and channel ID are required.',
      );
    }

    _definitions[id] = definition;
  }

  /// Removes an extension only.
  ///
  /// Built-in notification definitions are protected.
  static bool unregisterExtension(String id) {
    final normalized = id.trim();

    if (_builtInDefinitions.any(
      (definition) => definition.id == normalized,
    )) {
      return false;
    }

    return _definitions.remove(normalized) != null;
  }

  /// Checks the integrity of the registry.
  static List<String> validate() {
    final issues = <String>[];
    final seenChannels = <String>{};

    for (final entry in _definitions.entries) {
      final definition = entry.value;

      if (entry.key != definition.id) {
        issues.add(
          'Registry key does not match notification ID: ${entry.key}',
        );
      }

      if (definition.titleKey.trim().isEmpty) {
        issues.add(
          'Missing title translation key: ${definition.id}',
        );
      }

      if (definition.descriptionKey.trim().isEmpty) {
        issues.add(
          'Missing description translation key: ${definition.id}',
        );
      }

      if (definition.channelId.trim().isEmpty) {
        issues.add(
          'Missing notification channel: ${definition.id}',
        );
      }

      if (definition.delivery ==
              MuminNotificationDelivery.remotePush &&
          !definition.requiresNetwork) {
        issues.add(
          'Remote notification must require network: ${definition.id}',
        );
      }

      seenChannels.add(definition.channelId);
    }

    return List<String>.unmodifiable(issues);
  }

  static Set<String> get registeredIds =>
      Set<String>.unmodifiable(_definitions.keys);

  static Set<String> get channelIds =>
      Set<String>.unmodifiable(
        _definitions.values.map(
          (definition) => definition.channelId,
        ),
      );
}
