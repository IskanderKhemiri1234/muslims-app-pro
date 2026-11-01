
import 'app_event.dart';

/// Contract for an independently reusable application event filter.
abstract interface class AppEventFilter {
  /// Returns true when [event] satisfies this filter.
  bool matches(AppEvent event);

  /// Combines this filter with another filter using logical AND.
  AppEventFilter and(AppEventFilter other) {
    return AppEventAndFilter(<AppEventFilter>[
      this,
      other,
    ]);
  }

  /// Combines this filter with another filter using logical OR.
  AppEventFilter or(AppEventFilter other) {
    return AppEventOrFilter(<AppEventFilter>[
      this,
      other,
    ]);
  }

  /// Negates this filter.
  AppEventFilter negate() {
    return AppEventNotFilter(this);
  }
}

/// Matches events by their exact event type.
final class AppEventTypeFilter implements AppEventFilter {
  AppEventTypeFilter(String eventType)
      : eventType = _validateEventType(eventType);

  final String eventType;

  static String _validateEventType(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'eventType',
        'Event type must not be empty.',
      );
    }

    return normalized;
  }

  @override
  bool matches(AppEvent event) {
    return event.eventType == eventType;
  }
}

/// Matches events originating from one specific source.
final class AppEventSourceFilter implements AppEventFilter {
  const AppEventSourceFilter(this.source);

  final AppEventSource source;

  @override
  bool matches(AppEvent event) {
    return event.source == source;
  }
}

/// Matches events whose type is included in a predefined collection.
final class AppEventTypesFilter implements AppEventFilter {
  AppEventTypesFilter(Iterable<String> eventTypes)
      : eventTypes = _normalizeEventTypes(eventTypes);

  final Set<String> eventTypes;

  static Set<String> _normalizeEventTypes(
    Iterable<String> values,
  ) {
    final normalized = <String>{};

    for (final value in values) {
      final eventType = value.trim();

      if (eventType.isEmpty) {
        throw ArgumentError.value(
          value,
          'eventTypes',
          'Event types must not contain empty values.',
        );
      }

      normalized.add(eventType);
    }

    if (normalized.isEmpty) {
      throw ArgumentError(
        'At least one event type must be provided.',
      );
    }

    return Set<String>.unmodifiable(normalized);
  }

  @override
  bool matches(AppEvent event) {
    return eventTypes.contains(event.eventType);
  }
}

/// Matches events originating from any source in a predefined collection.
final class AppEventSourcesFilter implements AppEventFilter {
  AppEventSourcesFilter(Iterable<AppEventSource> sources)
      : sources = _normalizeSources(sources);

  final Set<AppEventSource> sources;

  static Set<AppEventSource> _normalizeSources(
    Iterable<AppEventSource> values,
  ) {
    final normalized = Set<AppEventSource>.of(values);

    if (normalized.isEmpty) {
      throw ArgumentError(
        'At least one event source must be provided.',
      );
    }

    return Set<AppEventSource>.unmodifiable(normalized);
  }

  @override
  bool matches(AppEvent event) {
    return sources.contains(event.source);
  }
}

/// Matches events using a custom predicate.
final class AppEventPredicateFilter implements AppEventFilter {
  AppEventPredicateFilter(this._predicate);

  final bool Function(AppEvent event) _predicate;

  @override
  bool matches(AppEvent event) {
    return _predicate(event);
  }
}

/// Matches an event only when every child filter matches.
///
/// Logical operation: AND.
final class AppEventAndFilter implements AppEventFilter {
  AppEventAndFilter(Iterable<AppEventFilter> filters)
      : filters = _validateFilters(filters);

  final List<AppEventFilter> filters;

  static List<AppEventFilter> _validateFilters(
    Iterable<AppEventFilter> values,
  ) {
    final result = List<AppEventFilter>.unmodifiable(values);

    if (result.isEmpty) {
      throw ArgumentError(
        'An AND filter requires at least one child filter.',
      );
    }

    return result;
  }

  @override
  bool matches(AppEvent event) {
    for (final filter in filters) {
      if (!filter.matches(event)) {
        return false;
      }
    }

    return true;
  }
}

/// Matches an event when at least one child filter matches.
///
/// Logical operation: OR.
final class AppEventOrFilter implements AppEventFilter {
  AppEventOrFilter(Iterable<AppEventFilter> filters)
      : filters = _validateFilters(filters);

  final List<AppEventFilter> filters;

  static List<AppEventFilter> _validateFilters(
    Iterable<AppEventFilter> values,
  ) {
    final result = List<AppEventFilter>.unmodifiable(values);

    if (result.isEmpty) {
      throw ArgumentError(
        'An OR filter requires at least one child filter.',
      );
    }

    return result;
  }

  @override
  bool matches(AppEvent event) {
    for (final filter in filters) {
      if (filter.matches(event)) {
        return true;
      }
    }

    return false;
  }
}

/// Matches an event when its child filter does not match.
///
/// Logical operation: NOT.
final class AppEventNotFilter implements AppEventFilter {
  const AppEventNotFilter(this.filter);

  final AppEventFilter filter;

  @override
  bool matches(AppEvent event) {
    return !filter.matches(event);
  }
}

/// Provides commonly used event filter constructors.
abstract final class AppEventFilters {
  /// Matches every event.
  static const AppEventFilter all = _MatchAllAppEventFilter();

  /// Matches no events.
  static const AppEventFilter none = _MatchNoAppEventFilter();

  /// Creates a filter for an exact event type.
  static AppEventFilter type(String eventType) {
    return AppEventTypeFilter(eventType);
  }

  /// Creates a filter for one event source.
  static AppEventFilter source(AppEventSource source) {
    return AppEventSourceFilter(source);
  }

  /// Creates a filter for multiple event types.
  static AppEventFilter types(Iterable<String> eventTypes) {
    return AppEventTypesFilter(eventTypes);
  }

  /// Creates a filter for multiple event sources.
  static AppEventFilter sources(
    Iterable<AppEventSource> sources,
  ) {
    return AppEventSourcesFilter(sources);
  }

  /// Creates a filter from a custom predicate.
  static AppEventFilter where(
    bool Function(AppEvent event) predicate,
  ) {
    return AppEventPredicateFilter(predicate);
  }

  /// Creates an AND combination.
  static AppEventFilter and(
    Iterable<AppEventFilter> filters,
  ) {
    return AppEventAndFilter(filters);
  }

  /// Creates an OR combination.
  static AppEventFilter or(
    Iterable<AppEventFilter> filters,
  ) {
    return AppEventOrFilter(filters);
  }

  /// Creates a NOT combination.
  static AppEventFilter not(AppEventFilter filter) {
    return AppEventNotFilter(filter);
  }
}

final class _MatchAllAppEventFilter implements AppEventFilter {
  const _MatchAllAppEventFilter();

  @override
  bool matches(AppEvent event) => true;
}

final class _MatchNoAppEventFilter implements AppEventFilter {
  const _MatchNoAppEventFilter();

  @override
  bool matches(AppEvent event) => false;
}
