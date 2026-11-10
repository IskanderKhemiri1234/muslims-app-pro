import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../../data/services/mumin_adhan_notification_coordinator.dart';
import '../../data/services/mumin_prayer_countdown_notification_service.dart';

class PrayerCountdownDiagnosticsPage extends StatefulWidget {
  const PrayerCountdownDiagnosticsPage({super.key});

  @override
  State<PrayerCountdownDiagnosticsPage> createState() =>
      _PrayerCountdownDiagnosticsPageState();
}

class _PrayerCountdownDiagnosticsPageState
    extends State<PrayerCountdownDiagnosticsPage> {
  static const MethodChannel _channel =
      MethodChannel('com.iskander.muslimspro/prayer_countdown');

  bool _loading = true;
  bool _syncing = false;
  String? _loadError;
  Map<String, Object?> _report = <String, Object?>{};

  String _t(String ar, String en, String fr) {
    switch (Localizations.localeOf(context).languageCode) {
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
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      final android = await _channel.invokeMapMethod<String, Object?>(
        'getPrayerCountdownDiagnostics',
      );
      if (android == null) {
        throw StateError('Android returned an empty diagnostics response.');
      }
      if (!mounted) return;

      final controller = context.read<PrayerController>();
      final local = <String, Object?>{
        'syncStatus': preferences.getString(
          MuminPrayerCountdownNotificationService.diagnosticsStatusKey,
        ) ?? 'not_started',
        'syncError': preferences.getString(
          MuminPrayerCountdownNotificationService.diagnosticsErrorKey,
        ),
        'generatedEntries': preferences.getInt(
          MuminPrayerCountdownNotificationService.diagnosticsGeneratedEntriesKey,
        ) ?? 0,
        'lastSyncAt': preferences.getString(
          MuminPrayerCountdownNotificationService.diagnosticsLastSyncAtKey,
        ),
        'dartTimezone': preferences.getString(
          MuminPrayerCountdownNotificationService.diagnosticsTimezoneKey,
        ),
        'dartNextPrayer': preferences.getString(
          MuminPrayerCountdownNotificationService.diagnosticsNextPrayerKey,
        ),
        'dartNextPrayerTimeMillis': preferences.getInt(
          MuminPrayerCountdownNotificationService.diagnosticsNextPrayerTimeKey,
        ),
        'controllerInitialized': controller.isInitialized,
        'controllerHasUsableSchedule': controller.hasUsableSchedule,
        'controllerTimezone': controller.timezoneLocation?.name,
        'controllerTimezoneId': controller.timezoneId,
        'latitude': controller.latitude,
        'longitude': controller.longitude,
        'countdownEnabled': preferences.getBool(
          MuminAdhanNotificationCoordinator.countdownEnabledPreferenceKey,
        ) ?? false,
      };

      if (!mounted) return;
      setState(() {
        _report = <String, Object?>{
          'dart': local,
          'android': android,
        };
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _synchronizeNow() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _loadError = null;
    });

    try {
      await context.read<MuminAdhanNotificationCoordinator>().refresh(
            force: true,
            rethrowErrors: true,
          );
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = error.toString());
      }
    } finally {
      await _loadReport();
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _copyReport() async {
    final encoded = const JsonEncoder.withIndent('  ').convert(_report);
    await Clipboard.setData(ClipboardData(text: encoded));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t(
          'تم نسخ تقرير التشخيص.',
          'Diagnostics report copied.',
          'Rapport de diagnostic copié.',
        )),
      ),
    );
  }

  String _yesNo(Object? value) => value == true
      ? _t('نعم', 'Yes', 'Oui')
      : value == false
          ? _t('لا', 'No', 'Non')
          : _t('غير معروف', 'Unknown', 'Inconnu');

  String _formatTimestamp(Object? value) {
    if (value is! num || value <= 0) return '—';
    return DateTime.fromMillisecondsSinceEpoch(value.toInt())
        .toLocal()
        .toString();
  }

  Widget _section(String title, List<Widget> children) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _value(String label, Object? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: SelectableText(
              value?.toString() ?? '—',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dart = (_report['dart'] as Map?)?.cast<String, Object?>() ??
        <String, Object?>{};
    final android = (_report['android'] as Map?)?.cast<String, Object?>() ??
        <String, Object?>{};
    final status = dart['syncStatus']?.toString() ?? 'not_started';
    final statusLabel = switch (status) {
      'synchronized' => _t('تمت المزامنة', 'Synchronized', 'Synchronisé'),
      'sending' => _t('جارٍ الإرسال', 'Sending', 'Envoi en cours'),
      'generating' => _t('جارٍ توليد المواقيت', 'Generating schedule', 'Calcul des horaires'),
      'failed' => _t('فشلت المزامنة', 'Synchronization failed', 'Échec de synchronisation'),
      _ => _t('لم تبدأ المزامنة', 'Not synchronized yet', 'Pas encore synchronisé'),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(
          'تشخيص شريط الصلاة',
          'Prayer countdown diagnostics',
          'Diagnostic du compte à rebours',
        )),
        actions: [
          IconButton(
            tooltip: _t('تحديث', 'Refresh', 'Actualiser'),
            onPressed: _loading ? null : _loadReport,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section(
                    _t('حالة المزامنة من Flutter', 'Flutter synchronization', 'Synchronisation Flutter'),
                    [
                      _value(_t('النتيجة', 'Status', 'État'), statusLabel),
                      _value(_t('المزامنة مفعّلة', 'Countdown enabled', 'Compte à rebours activé'), _yesNo(dart['countdownEnabled'])),
                      _value(_t('المتحكم مهيأ', 'Controller initialized', 'Contrôleur initialisé'), _yesNo(dart['controllerInitialized'])),
                      _value(_t('جدول صالح', 'Usable schedule', 'Horaires valides'), _yesNo(dart['controllerHasUsableSchedule'])),
                      _value(_t('المنطقة الزمنية', 'Timezone', 'Fuseau horaire'), dart['controllerTimezone'] ?? dart['dartTimezone']),
                      _value(_t('عدد المواقيت المولدة', 'Generated prayer entries', 'Horaires générés'), dart['generatedEntries']),
                      _value(_t('الصلاة القادمة', 'Next prayer', 'Prochaine prière'), dart['dartNextPrayer']),
                      _value(_t('وقت الصلاة القادمة', 'Next prayer time', 'Heure de la prochaine prière'), _formatTimestamp(dart['dartNextPrayerTimeMillis'])),
                      _value(_t('آخر محاولة', 'Last attempt', 'Dernière tentative'), dart['lastSyncAt']),
                    ],
                  ),
                  _section(
                    _t('الحالة الفعلية داخل Android', 'Android runtime state', 'État réel d’Android'),
                    [
                      _value(_t('إذن POST_NOTIFICATIONS', 'POST_NOTIFICATIONS permission', 'Autorisation POST_NOTIFICATIONS'), _yesNo(android['permissionGranted'])),
                      _value(_t('إشعارات التطبيق مسموحة', 'App notifications allowed', 'Notifications de l’application autorisées'), _yesNo(android['notificationsEnabled'])),
                      _value(_t('قناة الإشعار موجودة', 'Notification channel exists', 'Canal de notification présent'), _yesNo(android['channelExists'])),
                      _value(_t('أهمية القناة', 'Channel importance', 'Importance du canal'), android['channelImportance']),
                      _value(_t('القناة محظورة', 'Channel blocked', 'Canal bloqué'), _yesNo(android['channelBlocked'])),
                      _value(_t('الجدول محفوظ في Android', 'Schedule stored in Android', 'Horaires enregistrés dans Android'), _yesNo(android['scheduleStored'])),
                      _value(_t('عدد المواقيت المحفوظة', 'Prayer entries stored', 'Horaires enregistrés'), android['storedEntriesCount']),
                      _value(_t('الإشعار موجود فعلياً', 'Notification active in Android', 'Notification active dans Android'), _yesNo(android['activeNotification'])),
                      _value(_t('الصلاة القادمة في Android', 'Android next prayer', 'Prochaine prière Android'), android['nextPrayerName'] ?? android['nextPrayerEnglishName']),
                      _value(_t('وقت الصلاة القادمة في Android', 'Android next prayer time', 'Heure Android de la prochaine prière'), _formatTimestamp(android['nextPrayerTimeMillis'])),
                      _value('Channel ID', android['channelId']),
                      _value('Notification ID', android['notificationId']),
                    ],
                  ),
                  if (dart['syncError'] != null || _loadError != null || android['activeNotificationCheckError'] != null)
                    _section(
                      _t('الخطأ الحقيقي', 'Actual error', 'Erreur réelle'),
                      [
                        if (_loadError != null) SelectableText(_loadError!),
                        if (dart['syncError'] != null) SelectableText(dart['syncError'].toString()),
                        if (android['activeNotificationCheckError'] != null)
                          SelectableText(android['activeNotificationCheckError'].toString()),
                      ],
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _syncing ? null : _synchronizeNow,
                    icon: _syncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: Text(_t(
                      'إعادة المزامنة الآن',
                      'Synchronize now',
                      'Synchroniser maintenant',
                    )),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _report.isEmpty ? null : _copyReport,
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(_t(
                      'نسخ تقرير التشخيص الكامل',
                      'Copy full diagnostics report',
                      'Copier le rapport complet',
                    )),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
