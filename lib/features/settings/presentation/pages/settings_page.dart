import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/updates/mumin_app_update_service.dart';

import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Central settings hub for Mumin Pro.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.localizations,
    required this.onLanguageTap,
    super.key,
  });

  final MuminLocalizations localizations;
  final VoidCallback onLanguageTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localizations.text('settings')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B4939),
                    Color(0xFF071C17),
                  ],
                ),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.34),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.13),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.55),
                      ),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.gold,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mumin Pro',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations.text('settings_subtitle'),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            _SettingsSectionTitle(
              title: localizations.text('general_settings'),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.translate_rounded,
              title: localizations.text('language'),
              subtitle: localizations.text('select_language'),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gold,
              ),
              onTap: onLanguageTap,
            ),
            const SizedBox(height: 24),
            _SettingsSectionTitle(
              title: localizations.text('app_updates'),
            ),
            const SizedBox(height: 10),
            _SettingsUpdateTile(localizations: localizations),
            const SizedBox(height: 24),
            Text(
              localizations.text('update_signature_note'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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


class _SettingsUpdateTile extends StatefulWidget {
  const _SettingsUpdateTile({
    required this.localizations,
  });

  final MuminLocalizations localizations;

  @override
  State<_SettingsUpdateTile> createState() =>
      _SettingsUpdateTileState();
}

class _SettingsUpdateTileState extends State<_SettingsUpdateTile> {
  bool _isChecking = false;

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final update = await MuminAppUpdateService().checkForUpdate();
      if (!mounted) return;

      if (!update.isUpdateAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.localizations.text('update_latest'),
            ),
          ),
        );
        return;
      }

      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              widget.localizations.text('update_available'),
            ),
            content: Text(
              '${widget.localizations.text('update_release_version')} '
              '${update.latestVersion}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  widget.localizations.text('update_later'),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  widget.localizations.text('update_download'),
                ),
              ),
            ],
          );
        },
      );

      if (shouldDownload == true && mounted) {
        final opened = await launchUrl(
          update.apkUri,
          mode: LaunchMode.externalApplication,
        );

        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.localizations.text('update_download_failed'),
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.localizations.text('update_check_failed'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.system_update_alt_rounded,
      title: widget.localizations.text('app_updates'),
      subtitle: widget.localizations.text('update_channel_setup_required'),
      trailing: _isChecking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            )
          : const Icon(
              Icons.system_update_alt_rounded,
              color: AppColors.gold,
            ),
      onTap: _checkForUpdates,
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.gold,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: AppColors.gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
