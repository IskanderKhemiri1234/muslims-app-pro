import 'package:flutter/material.dart';

import '../../../../core/updates/mumin_app_update_service.dart';
import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../adhan/presentation/pages/adhan_media_settings_page.dart';
import '../../../adhan/presentation/pages/adhan_notification_settings_page.dart';

/// Premium, structured settings hub for Mumin Pro.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.localizations,
    required this.onLanguageTap,
    super.key,
  });

  final MuminLocalizations localizations;
  final VoidCallback onLanguageTap;

  String _copy(String ar, String en, String fr) {
    if (localizations.isFrench) return fr;
    if (localizations.isArabic) return ar;
    return en;
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localizations.text('settings')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            _SettingsHero(
              title: 'Mumin Pro',
              subtitle: _copy(
                'كل ما تحتاجه لتخصيص تجربتك الإسلامية في مكان واحد',
                'Everything you need to personalize your Muslim companion',
                'Tout pour personnaliser votre compagnon musulman',
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeading(
              title: _copy('التفضيلات العامة', 'General preferences', 'Préférences générales'),
              subtitle: _copy('اللغة وطريقة استخدام التطبيق', 'Language and app experience', 'Langue et expérience de l’application'),
            ),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.translate_rounded,
                  title: localizations.text('language'),
                  subtitle: localizations.text('select_language'),
                  onTap: onLanguageTap,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SectionHeading(
              title: _copy('الصلاة والأذان', 'Prayer & Adhan', 'Prière et Adhan'),
              subtitle: _copy('إدارة التنبيهات والصوت والمظهر', 'Manage alerts, audio and appearance', 'Gérer les alertes, le son et l’apparence'),
            ),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_active_rounded,
                  title: _copy('إشعارات الصلاة', 'Prayer notifications', 'Notifications de prière'),
                  subtitle: _copy(
                    'مواعيد التنبيه والعدّ التنازلي والوصول إلى الشاشة الكاملة',
                    'Prayer alerts, countdown and full-screen access',
                    'Alertes, compte à rebours et accès plein écran',
                  ),
                  onTap: () => _open(
                    context,
                    const AdhanNotificationSettingsPage(),
                  ),
                ),
                const _GroupDivider(),
                _SettingsTile(
                  icon: Icons.graphic_eq_rounded,
                  title: _copy('الصوت وخلفية الأذان', 'Adhan sound & background', 'Son et arrière-plan de l’Adhan'),
                  subtitle: _copy(
                    'اختر تسجيلاً واحداً، اختبره، وخصص صورة شاشة الأذان',
                    'Choose one recording, test it and personalize the Adhan screen',
                    'Choisissez un enregistrement, testez-le et personnalisez l’écran',
                  ),
                  onTap: () => _open(
                    context,
                    const AdhanMediaSettingsPage(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SectionHeading(
              title: _copy('التطبيق والتحديثات', 'App & updates', 'Application et mises à jour'),
              subtitle: _copy('الحصول على أحدث تحسينات Mumin Pro', 'Keep Mumin Pro up to date', 'Maintenir Mumin Pro à jour'),
            ),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _SettingsUpdateTile(localizations: localizations),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              localizations.text('update_signature_note'),
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
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C5944), Color(0xFF071C17), Color(0xFF04130F)],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.17),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.13),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.62)),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.gold, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 3, end: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.19),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 68,
        endIndent: 15,
        color: AppColors.gold.withValues(alpha: 0.14),
      );
}

class _SettingsUpdateTile extends StatefulWidget {
  const _SettingsUpdateTile({required this.localizations});

  final MuminLocalizations localizations;

  @override
  State<_SettingsUpdateTile> createState() => _SettingsUpdateTileState();
}

class _SettingsUpdateTileState extends State<_SettingsUpdateTile> {
  bool _isChecking = false;
  String _statusKey = 'update_channel_setup_required';

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
      _statusKey = 'update_checking';
    });

    try {
      final update = await MuminAppUpdateService().checkForUpdate();
      if (!mounted) return;
      if (!update.isUpdateAvailable) {
        setState(() => _statusKey = 'update_latest');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.localizations.text('update_latest'))),
        );
        return;
      }

      setState(() => _statusKey = 'update_available');
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(widget.localizations.text('update_available')),
          content: Text(
            widget.localizations.text('update_release_version') +
                ' ' +
                update.latestVersion,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(widget.localizations.text('update_later')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(widget.localizations.text('update_download')),
            ),
          ],
        ),
      );

      if (shouldDownload == true && mounted) {
        try {
          await MuminAppUpdateService().downloadAndInstall(update);
        } catch (_) {
          if (!mounted) return;
          setState(() => _statusKey = 'update_download_failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.localizations.text('update_download_failed'))),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusKey = 'update_check_failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.localizations.text('update_check_failed'))),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.system_update_alt_rounded,
      title: widget.localizations.text('app_updates'),
      subtitle: widget.localizations.text(_statusKey),
      trailing: _isChecking
          ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            )
          : const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
      onTap: _checkForUpdates,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 82),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.13),
                    ),
                  ),
                  child: Icon(icon, color: AppColors.gold, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w850,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
