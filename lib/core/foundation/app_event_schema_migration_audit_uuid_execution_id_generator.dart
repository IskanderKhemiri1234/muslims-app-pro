
import 'dart:math';

import 'app_event_schema_migration_audit_execution_id_generator.dart';

/// UUID v4 implementation of the execution identifier generator.
///
/// This implementation generates identifiers using random values
/// provided by the injected Random instance.
///
/// Architectural responsibilities:
///
/// - Generate UUID v4 formatted execution identifiers.
/// - Implement the execution identifier generator contract.
/// - Allow the random source to be injected.
///
/// Architectural restrictions:
///
/// - Does not execute repository operations.
/// - Does not create diagnostic records.
/// - Does not record diagnostic events.
/// - Does not resolve or validate repository scopes.
/// - Does not access repositories or scope registries.
/// - Does not introduce external package dependencies.
///
/// Security note:
///
/// The default Random implementation is not cryptographically secure.
/// Generated identifiers are intended for diagnostic correlation,
/// not authentication, authorization, or security tokens.
final class AppEventSchemaMigrationAuditUuidExecutionIdGenerator
    implements AppEventSchemaMigrationAuditExecutionIdGenerator {
  /// Creates a UUID v4 execution identifier generator.
  ///
  /// A random source may be injected to support deterministic
  /// implementations where required.
  AppEventSchemaMigrationAuditUuidExecutionIdGenerator({
    Random? random,
  }) : _random = random ?? Random();

  final Random _random;


  /// Generates a UUID v4 formatted execution identifier.
  ///
  /// The returned identifier contains 36 characters and is already
  /// normalized.
  @override
  String generate() {
    final bytes = List<int>.generate(
      16,
      (_) => _random.nextInt(256),
      growable: false,
    );

    // Set the UUID version to 4.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;

    // Set the UUID variant to RFC 4122.
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
