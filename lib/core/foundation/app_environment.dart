
/// Defines the runtime environment of Muslims Pro.
///
/// Environment values can be supplied at build time through
/// Dart's `--dart-define` mechanism:
///
/// flutter run --dart-define=APP_ENV=development
/// flutter run --dart-define=APP_ENV=staging
/// flutter run --dart-define=APP_ENV=production
///
/// If no value is supplied, production is selected by default.
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment parse(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'development':
      case 'dev':
        return AppEnvironment.development;

      case 'staging':
      case 'stage':
        return AppEnvironment.staging;

      case 'production':
      case 'prod':
      case null:
      case '':
        return AppEnvironment.production;

      default:
        throw FormatException(
          'Unsupported APP_ENV value: "$value". '
          'Expected development, staging, or production.',
        );
    }
  }

  bool get isDevelopment => this == AppEnvironment.development;

  bool get isStaging => this == AppEnvironment.staging;

  bool get isProduction => this == AppEnvironment.production;

  String get label => switch (this) {
        AppEnvironment.development => 'Development',
        AppEnvironment.staging => 'Staging',
        AppEnvironment.production => 'Production',
      };
}

/// Immutable configuration describing the active application environment.
final class AppEnvironmentConfig {
  const AppEnvironmentConfig({
    required this.environment,
    required this.enableDebugLogging,
    required this.enableDiagnostics,
    required this.allowInsecureNetworkConnections,
  });

  final AppEnvironment environment;

  /// Enables verbose diagnostic logging.
  final bool enableDebugLogging;

  /// Enables local diagnostic and performance instrumentation.
  final bool enableDiagnostics;

  /// Allows insecure HTTP connections.
  ///
  /// This must remain disabled in production.
  final bool allowInsecureNetworkConnections;

  bool get isProduction => environment.isProduction;

  bool get isDevelopment => environment.isDevelopment;

  bool get isStaging => environment.isStaging;

  static AppEnvironmentConfig forEnvironment(
    AppEnvironment environment,
  ) {
    return switch (environment) {
      AppEnvironment.development => const AppEnvironmentConfig(
          environment: AppEnvironment.development,
          enableDebugLogging: true,
          enableDiagnostics: true,
          allowInsecureNetworkConnections: true,
        ),
      AppEnvironment.staging => const AppEnvironmentConfig(
          environment: AppEnvironment.staging,
          enableDebugLogging: true,
          enableDiagnostics: true,
          allowInsecureNetworkConnections: false,
        ),
      AppEnvironment.production => const AppEnvironmentConfig(
          environment: AppEnvironment.production,
          enableDebugLogging: false,
          enableDiagnostics: false,
          allowInsecureNetworkConnections: false,
        ),
    };
  }

  /// Resolves the active configuration from build-time environment values.
  factory AppEnvironmentConfig.fromBuildDefines() {
    const environmentValue = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'production',
    );

    final environment = AppEnvironment.parse(environmentValue);

    return AppEnvironmentConfig.forEnvironment(environment);
  }
}
