
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../localization/mumin_localizations.dart';
import '../../../features/adhan/data/services/mumin_adhan_notification_service.dart';

/// First-launch permission setup.
///
/// Permissions are requested only after an explicit user action.
/// The application remains usable when permissions are declined.
class MuminPermissionOnboarding extends StatefulWidget {
  const MuminPermissionOnboarding({
    required this.child,
    super.key,
  });

  final Widget child;

  static const String completedPreferenceKey =
      'mumin_permission_onboarding_completed_v1';

  @override
  State<MuminPermissionOnboarding> createState() =>
      _MuminPermissionOnboardingState();
}

class _MuminPermissionOnboardingState
    extends State<MuminPermissionOnboarding>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _setupCompleted = false;
  bool _requesting = false;

  bool _notificationGranted = false;
  bool _locationGranted = false;
  bool _locationServiceEnabled = false;
  bool _locationPermanentlyDenied = false;

  String? _errorMessage;

  MuminLocalizations get _texts {
    return MuminLocalizations.fromCode(
      Localizations.localeOf(context).languageCode,
    );
  }

  bool get _allPermissionsGranted {
    return _notificationGranted && _locationGranted;
  }

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _restoreSetupState();
}

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed && !_setupCompleted) {
    _refreshPermissionStatus();
  }
}

  Future<void> _refreshPermissionStatus() async {
  if (!mounted || _requesting || _setupCompleted) return;

  try {
    final notificationService =
        context.read<MuminAdhanNotificationService>();

    final notificationGranted =
        await notificationService.areNotificationsEnabled();

    final locationPermission = await Geolocator.checkPermission();

    final locationGranted =
        locationPermission == LocationPermission.whileInUse ||
        locationPermission == LocationPermission.always;

    final locationPermanentlyDenied =
        locationPermission == LocationPermission.deniedForever;

    final locationServiceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!mounted) return;

    setState(() {
      _notificationGranted = notificationGranted;
      _locationGranted = locationGranted;
      _locationPermanentlyDenied = locationPermanentlyDenied;
      _locationServiceEnabled = locationServiceEnabled;
    });
  } catch (error, stackTrace) {
    debugPrint('Mumin permission refresh error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  }

  Future<void> _restoreSetupState() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final completed = preferences.getBool(
            MuminPermissionOnboarding.completedPreferenceKey,
          ) ??
          false;

      if (!mounted) return;

      setState(() {
        _setupCompleted = completed;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: permission setup state could not be restored: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (_requesting) return;

    setState(() {
      _requesting = true;
      _errorMessage = null;
    });

    var notificationGranted = _notificationGranted;
    var locationGranted = _locationGranted;
    var locationServiceEnabled = _locationServiceEnabled;
    var locationPermanentlyDenied = _locationPermanentlyDenied;

    // Request notifications only when they have not already been granted.
    if (!notificationGranted) {
      try {
        final notificationService =
            context.read<MuminAdhanNotificationService>();

        notificationGranted =
            await notificationService.requestNotificationPermission();
      } catch (error, stackTrace) {
        debugPrint(
          'Mumin Pro: notification permission request failed: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    // Request location independently from notification permission.
    if (!locationGranted) {
      try {
        var permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        locationGranted =
            permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always;

        locationPermanentlyDenied =
            permission == LocationPermission.deniedForever;

        locationServiceEnabled =
            await Geolocator.isLocationServiceEnabled();
      } catch (error, stackTrace) {
        debugPrint(
          'Mumin Pro: location permission request failed: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    } else {
      try {
        locationServiceEnabled =
            await Geolocator.isLocationServiceEnabled();
      } catch (error, stackTrace) {
        debugPrint(
          'Mumin Pro: location service status check failed: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    if (!mounted) return;

    setState(() {
      _notificationGranted = notificationGranted;
      _locationGranted = locationGranted;
      _locationServiceEnabled = locationServiceEnabled;
      _locationPermanentlyDenied = locationPermanentlyDenied;
      _requesting = false;
    });
  }

  Future<void> _finishSetup() async {
    if (_requesting) return;

    try {
      final preferences = await SharedPreferences.getInstance();

      final saved = await preferences.setBool(
        MuminPermissionOnboarding.completedPreferenceKey,
        true,
      );

      if (!saved) {
        throw StateError(
          'Permission onboarding state could not be saved.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: permission onboarding could not be saved: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _errorMessage = _texts.text(
          'permission_setup_save_failed',
        );
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _setupCompleted = true;
    });
  }

  Future<void> _openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: application settings could not be opened: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: location settings could not be opened: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_setupCompleted) {
      return widget.child;
    }

    return _buildSetupScreen();
  }

  Widget _buildSetupScreen() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 52,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: const Color(0xFF075B46),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: const Color(0xFFD8B66A),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF075B46)
                                  .withValues(alpha: 0.22),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mosque_rounded,
                          size: 43,
                          color: Color(0xFFE8CE91),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _texts.text('permission_setup_title'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _texts.text('permission_setup_description'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.65,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _PermissionCard(
                      icon: Icons.notifications_active_rounded,
                      title: _texts.text(
                        'permission_notifications_title',
                      ),
                      description: _texts.text(
                        'permission_notifications_description',
                      ),
                      granted: _notificationGranted,
                      statusGranted: _texts.text(
                        'permission_status_granted',
                      ),
                      statusPending: _texts.text(
                        'permission_status_pending',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PermissionCard(
                      icon: Icons.location_on_rounded,
                      title: _texts.text('permission_location_title'),
                      description: _texts.text(
                        'permission_location_description',
                      ),
                      granted: _locationGranted,
                      statusGranted: _texts.text(
                        'permission_status_granted',
                      ),
                      statusPending: _texts.text(
                        'permission_status_pending',
                      ),
                    ),
                    if (_locationGranted &&
                        !_locationServiceEnabled) ...[
                      const SizedBox(height: 12),
                      _InformationNotice(
                        message: _texts.text(
                          'permission_location_service_disabled',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _openLocationSettings,
                        icon: const Icon(Icons.gps_fixed_rounded),
                        label: Text(
                          _texts.text(
                            'permission_open_location_settings',
                          ),
                        ),
                      ),
                    ],
                    if (_locationPermanentlyDenied) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openAppSettings,
                        icon: const Icon(Icons.settings_rounded),
                        label: Text(
                          _texts.text(
                            'permission_open_app_settings',
                          ),
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _requesting
                          ? null
                          : _allPermissionsGranted
                              ? _finishSetup
                              : _requestPermissions,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF075B46),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: _requesting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _allPermissionsGranted
                                  ? _texts.text('permission_continue')
                                  : _texts.text(
                                      'permission_allow_and_continue',
                                    ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    if (_notificationGranted || _locationGranted) ...[
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _openAppSettings,
                        child: Text(
                          _texts.text(
                            'permission_open_app_settings',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _requesting ? null : _finishSetup,
                      child: Text(
                        _texts.text('permission_skip_for_now'),
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _texts.text('permission_privacy_note'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.statusGranted,
    required this.statusPending,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final String statusGranted;
  final String statusPending;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: granted
              ? const Color(0xFF147A60).withValues(alpha: 0.45)
              : colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF075B46).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFD8B66A),
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.5,
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(
                      granted
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      size: 15,
                      color: granted
                          ? const Color(0xFF2E9D78)
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      granted ? statusGranted : statusPending,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: granted
                            ? const Color(0xFF2E9D78)
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationNotice extends StatelessWidget {
  const _InformationNotice({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colors.onTertiaryContainer,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onTertiaryContainer,
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
