
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/mumin_language_controller.dart';
import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../../data/services/mumin_adhan_notification_service.dart';
import '../../data/services/mumin_adhan_notification_coordinator.dart';

class AdhanNotificationSettingsPage extends StatefulWidget {
  const AdhanNotificationSettingsPage({super.key});

  @override
  State<AdhanNotificationSettingsPage> createState() =>
      _AdhanNotificationSettingsPageState();
}

class _AdhanNotificationSettingsPageState
    extends State<AdhanNotificationSettingsPage> {
  static const String _exactPreferenceKey =
      'mumin_adhan_exact_preference';
  static const String _countdownPreferenceKey =
      MuminAdhanNotificationCoordinator.countdownEnabledPreferenceKey;

  late final MuminAdhanNotificationService _service;
  late final PrayerController _prayerController;

  final Set<Prayer> _enabledPrayers = <Prayer>{};

  bool _loading = true;
  bool _saving = false;
  bool _preferExact = false;
  bool _countdownEnabled = false;

  String? _errorMessage;

  String _t(String ar, String en, String fr) {
    final code = context
        .read<MuminLanguageController>()
        .languageCode;

    switch (code) {
      case 'en':
        return en;
      case 'fr':
        return fr;
      default:
        return ar;
    }
  }

  @override
  void initState() {
    super.initState();

    _service = context.read<MuminAdhanNotificationService>();
    _prayerController = context.read<PrayerController>();

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final preferences =
          await SharedPreferences.getInstance();

      final enabled = await _service.getEnabledPrayers();
      final hasCountdownChoice =
          preferences.containsKey(_countdownPreferenceKey);
      final notificationsAllowed =
          await _service.areNotificationsEnabled();
      final countdownEnabled =
          preferences.getBool(_countdownPreferenceKey) ??
              notificationsAllowed;

      if (!hasCountdownChoice && notificationsAllowed) {
        await preferences.setBool(_countdownPreferenceKey, true);
      }

      if (!mounted) return;

      setState(() {
        _enabledPrayers
          ..clear()
          ..addAll(enabled);

        _preferExact =
            preferences.getBool(_exactPreferenceKey) ?? false;
        _countdownEnabled = countdownEnabled;

        _loading = false;
      });

      if (countdownEnabled) {
        await context
            .read<MuminAdhanNotificationCoordinator>()
            .refresh(force: true);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _togglePrayer(
    Prayer prayer,
    bool enabled,
  ) async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      if (enabled) {
        final permission =
            await _service.requestNotificationPermission();

        if (!permission) {
          throw StateError(
            _t(
              'لم يتم منح إذن الإشعارات. فعّله من إعدادات التطبيق.',
              'Notification permission was not granted. Enable it in app settings.',
              'L’autorisation des notifications n’a pas été accordée. Activez-la dans les paramètres.',
            ),
          );
        }
      }

      await _service.setPrayerEnabled(
        prayer,
        enabled: enabled,
      );

      if (enabled) {
        _enabledPrayers.add(prayer);
      } else {
        _enabledPrayers.remove(prayer);
      }

      await _refreshSchedule();

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(
        enabled
            ? _t(
                'تم تفعيل تنبيه الصلاة.',
                'Prayer alert enabled.',
                'Alerte de prière activée.',
              )
            : _t(
                'تم إيقاف تنبيه الصلاة.',
                'Prayer alert disabled.',
                'Alerte de prière désactivée.',
              ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _errorMessage = error.toString();
      });

      _showMessage(
        _t(
          'تعذر تحديث التنبيه. تحقق من الأذونات والموقع.',
          'Could not update the alert. Check permissions and location.',
          'Impossible de modifier l’alerte. Vérifiez les autorisations et la localisation.',
        ),
      );
    }
  }

  Future<void> _toggleCountdown(bool enabled) async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      if (enabled) {
        final permission = await _service.requestNotificationPermission();
        if (!permission || !await _service.areNotificationsEnabled()) {
          throw StateError(
            _t(
              'إذن الإشعارات غير مفعّل. اسمح لتطبيق Mumin Pro بإرسال الإشعارات من إعدادات Android.',
              'Notifications are not enabled. Allow Mumin Pro notifications in Android settings.',
              'Les notifications ne sont pas activées. Autorisez Mumin Pro dans les paramètres Android.',
            ),
          );
        }
      }

      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool(
        _countdownPreferenceKey,
        enabled,
      );
      if (!saved) {
        throw StateError('Could not save the persistent countdown setting.');
      }

      await context
          .read<MuminAdhanNotificationCoordinator>()
          .refresh(force: true);

      if (!mounted) return;
      setState(() {
        _countdownEnabled = enabled;
        _saving = false;
      });

      _showMessage(
        enabled
            ? _t(
                'تم تفعيل شريط الوقت المتبقي للصلاة.',
                'Persistent prayer countdown enabled.',
                'Compte à rebours permanent des prières activé.',
              )
            : _t(
                'تم إيقاف شريط الوقت المتبقي للصلاة.',
                'Persistent prayer countdown disabled.',
                'Compte à rebours permanent des prières désactivé.',
              ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = error.toString();
      });
      _showMessage(
        _t(
          'تعذر تفعيل شريط الصلاة. تحقق من إذن الإشعارات.',
          'Could not update the prayer countdown. Check notification permission.',
          'Impossible de modifier le compte à rebours. Vérifiez l’autorisation des notifications.',
        ),
      );
    }
  }

  Future<void> _toggleExact(bool enabled) async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      if (enabled) {
        final granted =
            await _service.requestExactAlarmPermission();

        if (!granted) {
          throw StateError(
            _t(
              'لم يتم منح إذن التنبيهات الدقيقة.',
              'Exact alarm permission was not granted.',
              'L’autorisation des alarmes exactes n’a pas été accordée.',
            ),
          );
        }
      }

      final preferences =
          await SharedPreferences.getInstance();

      await preferences.setBool(
        _exactPreferenceKey,
        enabled,
      );

      _preferExact = enabled;

      await _refreshSchedule();

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(
        enabled
            ? _t(
                'تم تفعيل الجدولة الدقيقة.',
                'Precise scheduling enabled.',
                'Planification précise activée.',
              )
            : _t(
                'تم اعتماد الجدولة المرنة.',
                'Flexible scheduling enabled.',
                'Planification flexible activée.',
              ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _refreshSchedule() async {
    if (_enabledPrayers.isEmpty) {
      await _service.cancelPreviouslyScheduled();
      return;
    }

    if (!_prayerController.hasUsableSchedule ||
        _prayerController.timezoneLocation == null) {
      throw StateError(
        _t(
          'مواقيت الصلاة أو المنطقة الزمنية غير جاهزة. حدّث الموقع أولاً.',
          'Prayer times or timezone are not ready. Refresh your location first.',
          'Les horaires ou le fuseau horaire ne sont pas prêts. Actualisez d’abord votre position.',
        ),
      );
    }

    await _service.reschedule(
      controller: _prayerController,
      prayerName: _prayerName,
      notificationBody: _t(
        'حان الآن وقت الصلاة.',
        'It is now time to pray.',
        'C’est maintenant l’heure de la prière.',
      ),
      preferExact: _preferExact,
    );
  }

  String _prayerName(Prayer prayer) {
    final languageController =
        context.read<MuminLanguageController>();

    final translated =
        languageController.prayerName(prayer.name);

    if (translated.trim().isNotEmpty) {
      return translated;
    }

    switch (prayer) {
      case Prayer.fajr:
        return _t('الفجر', 'Fajr', 'Fajr');
      case Prayer.dhuhr:
        return _t('الظهر', 'Dhuhr', 'Dhuhr');
      case Prayer.asr:
        return _t('العصر', 'Asr', 'Asr');
      case Prayer.maghrib:
        return _t('المغرب', 'Maghrib', 'Maghrib');
      case Prayer.isha:
        return _t('العشاء', 'Isha', 'Icha');
      default:
        return prayer.name;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Widget _buildPrayerTile({
    required Prayer prayer,
    required IconData icon,
  }) {
    final enabled = _enabledPrayers.contains(prayer);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enabled
              ? const Color(0xFFD8B66A)
                  .withValues(alpha: 0.65)
              : Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.25),
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: enabled
              ? const Color(0xFFD8B66A)
              : Theme.of(context).iconTheme.color,
        ),
        title: Text(
          _prayerName(prayer),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          _t(
            'إشعار مستقل عند دخول الوقت',
            'Independent notification at prayer time',
            'Notification indépendante à l’heure de prière',
          ),
        ),
        value: enabled,
        onChanged: _saving
            ? null
            : (value) => _togglePrayer(prayer, value),
        activeThumbColor: const Color(0xFFD8B66A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t(
            'تنبيهات الصلاة',
            'Prayer alerts',
            'Alertes de prière',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF063E31),
                          Color(0xFF071C17),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: Color(0xFFD8B66A),
                          size: 34,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _t(
                            'تحكم مستقل في تنبيهاتك',
                            'Independent alert control',
                            'Contrôle indépendant des alertes',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _t(
                            'اختر الصلوات التي تريد تلقي إشعاراتها. يمكنك تغيير كل اختيار في أي وقت.',
                            'Choose which prayers should notify you. You can change each setting at any time.',
                            'Choisissez les prières pour lesquelles vous souhaitez recevoir une notification. Vous pouvez modifier chaque réglage à tout moment.',
                          ),
                          style: const TextStyle(
                            color: Color(0xFFE5E9E5),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    tileColor: theme.colorScheme.surface,
                    secondary: const Icon(
                      Icons.timer_outlined,
                      color: Color(0xFFD8B66A),
                    ),
                    title: Text(
                      _t(
                        'شريط الصلاة الدائم',
                        'Persistent prayer countdown',
                        'Compte à rebours permanent',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      _t(
                        'يعرض شعار Mumin Pro واسم الصلاة القادمة والوقت المتبقي في لوحة الإشعارات.',
                        'Shows the Mumin Pro logo, next prayer name and remaining time in notifications.',
                        'Affiche le logo Mumin Pro, la prochaine prière et le temps restant dans les notifications.',
                      ),
                    ),
                    value: _countdownEnabled,
                    onChanged: _saving ? null : _toggleCountdown,
                    activeThumbColor: const Color(0xFFD8B66A),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    _t(
                      'إشعارات الصلوات',
                      'Prayer notifications',
                      'Notifications de prière',
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildPrayerTile(
                    prayer: Prayer.fajr,
                    icon: Icons.wb_twilight,
                  ),
                  _buildPrayerTile(
                    prayer: Prayer.dhuhr,
                    icon: Icons.wb_sunny_outlined,
                  ),
                  _buildPrayerTile(
                    prayer: Prayer.asr,
                    icon: Icons.sunny,
                  ),
                  _buildPrayerTile(
                    prayer: Prayer.maghrib,
                    icon: Icons.wb_sunny,
                  ),
                  _buildPrayerTile(
                    prayer: Prayer.isha,
                    icon: Icons.nightlight_round,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    _t(
                      'دقة الجدولة',
                      'Scheduling precision',
                      'Précision de planification',
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    tileColor: theme.colorScheme.surface,
                    title: Text(
                      _t(
                        'التنبيهات الدقيقة',
                        'Exact-time alerts',
                        'Alertes à l’heure exacte',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      _t(
                        'تتطلب إذن المنبهات الدقيقة من Android. عند عدم توفره تُستخدم الجدولة المرنة.',
                        'Requires Android exact-alarm permission. Flexible scheduling is used when unavailable.',
                        'Nécessite l’autorisation Android des alarmes exactes. La planification flexible est utilisée si elle est indisponible.',
                      ),
                    ),
                    value: _preferExact,
                    onChanged: _saving
                        ? null
                        : _toggleExact,
                    activeThumbColor:
                        const Color(0xFFD8B66A),
                  ),

                  if (_saving) ...[
                    const SizedBox(height: 18),
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Text(
                    _t(
                      'ملاحظة: هذه الإعدادات تتحكم في إشعارات دخول وقت الصلاة، ولا تشغّل تسجيل الأذان تلقائياً.',
                      'Note: These settings control prayer-time notifications and do not automatically play an Adhan recording.',
                      'Remarque : ces réglages contrôlent les notifications de prière et ne lancent pas automatiquement un enregistrement de l’Adhan.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
