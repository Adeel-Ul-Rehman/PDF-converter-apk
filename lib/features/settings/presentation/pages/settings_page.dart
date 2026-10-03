import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/core/services/error_log_service.dart';
import 'package:flux_convert/features/settings/presentation/providers/settings_providers.dart';
import 'package:flux_convert/features/settings/presentation/widgets/settings_category.dart';
import 'package:flux_convert/features/settings/presentation/widgets/settings_tile.dart';
import 'package:flux_convert/features/storage/data/repositories/storage_repository_impl.dart';
import 'package:flux_convert/features/storage/presentation/storage_manager.dart';

// IMPROVED: Enterprise Settings Screen with 5 organized categories (Layer 7 Rewrite)
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _currentSaveLocation = 'Default Storage Folder';
  bool _isSaveLocationLoaded = false;

  // Local preferences state
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  String _defaultOutputFormat = 'PDF';
  String _defaultQuality = 'High (90%)';
  bool _autoSaveToGallery = true;

  @override
  void initState() {
    super.initState();
    _loadCustomSettings();
  }

  Future<void> _loadCustomSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final customLoc = prefs.getString('custom_save_location');
    final lang = prefs.getString('pref_language') ?? 'English';
    final notifs = prefs.getBool('pref_notifications') ?? true;
    final fmt = prefs.getString('pref_default_format') ?? 'PDF';
    final qual = prefs.getString('pref_default_quality') ?? 'High (90%)';
    final autoSave = prefs.getBool('pref_auto_save') ?? true;

    if (!mounted) return;
    setState(() {
      _currentSaveLocation = (customLoc != null && customLoc.isNotEmpty)
          ? customLoc
          : 'Default: Converted Documents';
      _selectedLanguage = lang;
      _notificationsEnabled = notifs;
      _defaultOutputFormat = fmt;
      _defaultQuality = qual;
      _autoSaveToGallery = autoSave;
      _isSaveLocationLoaded = true;
    });
  }

  Future<void> _changeSaveLocation() async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_save_location', selectedDirectory);

        ref.read(directoryManagerProvider).clearCache();
        final repo = ref.read(storageRepositoryProvider);
        if (repo is StorageRepositoryImpl) {
          repo.clearCache();
        }

        await ref.read(storageNotifierProvider.notifier).initialise();

        if (!mounted) return;
        setState(() => _currentSaveLocation = selectedDirectory);

        AppPopups.showSnackBar(
          context: context,
          message: 'Save folder updated: $selectedDirectory',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to select custom save directory', e);
      if (!mounted) return;
      AppPopups.showSnackBar(
        context: context,
        message: 'Could not access directory. Try another path.',
        isError: true,
      );
    }
  }

  void _showLanguageSelector() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Hindi'];

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select App Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...languages.map(
              (lang) => ListTile(
                title: Text(lang),
                trailing: _selectedLanguage == lang
                    ? const Icon(Icons.check_rounded, color: Colors.blue)
                    : null,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('pref_language', lang);
                  if (!ctx.mounted) return;
                  setState(() => _selectedLanguage = lang);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDefaultFormatSelector() {
    final formats = ['PDF', 'JPG', 'PNG', 'DOCX'];

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Default Output Format', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...formats.map(
              (fmt) => ListTile(
                title: Text(fmt),
                trailing: _defaultOutputFormat == fmt
                    ? const Icon(Icons.check_rounded, color: Colors.blue)
                    : null,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('pref_default_format', fmt);
                  if (!ctx.mounted) return;
                  setState(() => _defaultOutputFormat = fmt);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQualitySelector() {
    final qualities = ['High (90%)', 'Medium (75%)', 'Low (50%)'];

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Default Image Quality', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...qualities.map(
              (q) => ListTile(
                title: Text(q),
                trailing: _defaultQuality == q
                    ? const Icon(Icons.check_rounded, color: Colors.blue)
                    : null,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('pref_default_quality', q);
                  if (!ctx.mounted) return;
                  setState(() => _defaultQuality = q);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureRequestDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request a Feature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tell us what new tools or improvements you would like to see:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe your idea...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppPopups.showSnackBar(
                context: context,
                message: 'Thank you for your feedback!',
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch theme from SettingsEntity (themeMode string: 'light' | 'dark')
    final settingsEntity = ref.watch(settingsNotifierProvider);
    final isDarkMode = settingsEntity.themeMode == 'dark';
    final isDark = Theme.of(context).brightness == Brightness.dark || isDarkMode;
    final errorLogsCount = ErrorLogService.instance.currentLogs.length;

    final bgColor = isDark ? AppColorScheme.backgroundDark : AppColorScheme.backgroundLight;
    final textPrimaryColor = isDark ? AppColorScheme.textPrimaryDark : AppColorScheme.textPrimaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimaryColor),
        title: Text(
          'Settings',
          style: TextStyle(
            color: textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── CATEGORY 1: GENERAL SETTINGS ─────────────────────────────────
          SettingsCategory(
            title: 'General',
            icon: Icons.tune_rounded,
            children: [
              SettingsTile(
                title: 'Dark Mode Theme',
                subtitle: 'Sleek dark theme for night reading',
                icon: Icons.dark_mode_outlined,
                iconColor: AppColorScheme.primaryBlueStart,
                isSwitch: true,
                switchValue: isDarkMode,
                onSwitchChanged: (val) {
                  ref.read(settingsNotifierProvider.notifier).updateTheme(
                    val ? 'dark' : 'light',
                  );
                },
              ),
              SettingsTile(
                title: 'Language',
                subtitle: 'Choose display language',
                icon: Icons.language_rounded,
                iconColor: Colors.blue,
                valueText: _selectedLanguage,
                onTap: _showLanguageSelector,
              ),
              SettingsTile(
                title: 'Notifications',
                subtitle: 'Conversion completion alerts',
                icon: Icons.notifications_none_rounded,
                iconColor: Colors.orange,
                isSwitch: true,
                switchValue: _notificationsEnabled,
                onSwitchChanged: (val) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('pref_notifications', val);
                  if (!mounted) return;
                  setState(() => _notificationsEnabled = val);
                },
              ),
            ],
          ),

          // ── CATEGORY 2: CONVERSION SETTINGS ──────────────────────────────
          SettingsCategory(
            title: 'Conversion',
            icon: Icons.transform_rounded,
            children: [
              SettingsTile(
                title: 'Default Format',
                subtitle: 'Preferred conversion target',
                icon: Icons.picture_as_pdf_outlined,
                iconColor: Colors.red.shade600,
                valueText: _defaultOutputFormat,
                onTap: _showDefaultFormatSelector,
              ),
              SettingsTile(
                title: 'Image Quality',
                subtitle: 'Compression & resolution scale',
                icon: Icons.high_quality_outlined,
                iconColor: Colors.teal,
                valueText: _defaultQuality,
                onTap: _showQualitySelector,
              ),
              SettingsTile(
                title: 'Auto-Save to Gallery',
                subtitle: 'Save image conversions directly to Photos',
                icon: Icons.photo_library_outlined,
                iconColor: Colors.purple,
                isSwitch: true,
                switchValue: _autoSaveToGallery,
                onSwitchChanged: (val) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('pref_auto_save', val);
                  if (!mounted) return;
                  setState(() => _autoSaveToGallery = val);
                },
              ),
              SettingsTile(
                title: 'Save Folder Location',
                subtitle: _isSaveLocationLoaded ? _currentSaveLocation : 'Loading...',
                icon: Icons.folder_open_outlined,
                iconColor: Colors.amber.shade800,
                onTap: _changeSaveLocation,
              ),
            ],
          ),

          // ── CATEGORY 3: STORAGE & ERROR LOGS ────────────────────────────
          SettingsCategory(
            title: 'Storage & Diagnostics',
            icon: Icons.sd_storage_outlined,
            children: [
              SettingsTile(
                title: 'Clear Cache Files',
                subtitle: 'Free temporary file storage',
                icon: Icons.cleaning_services_outlined,
                iconColor: Colors.deepOrange,
                onTap: () async {
                  final ctx = context;
                  await ref.read(storageManagerProvider).runTempCleanup();
                  if (!mounted) return;
                  AppPopups.showSnackBar(
                    // ignore: use_build_context_synchronously
                    context: ctx,
                    message: 'Temporary cache cleaned.',
                  );
                },
              ),
              SettingsTile(
                title: 'Error Logs Viewer',
                subtitle: 'Dedicated error log inspector (Layer 1)',
                icon: Icons.bug_report_outlined,
                iconColor: Colors.red.shade700,
                badgeCount: errorLogsCount,
                onTap: () => _showErrorLogsSheet(context),
              ),
              SettingsTile(
                title: 'Export Diagnostic Logs',
                subtitle: 'Share error log report for support',
                icon: Icons.ios_share_rounded,
                iconColor: Colors.blue.shade700,
                onTap: () async {
                  final logFile = await ErrorLogService.instance.exportLogsToFile();
                  await Share.shareXFiles([XFile(logFile.path)], text: 'App Error Logs Report');
                },
              ),
              SettingsTile(
                title: 'Clear Error Logs',
                subtitle: 'Purge saved error history ($errorLogsCount entries)',
                icon: Icons.delete_outline_rounded,
                iconColor: Colors.red,
                onTap: () async {
                  final ctx = context;
                  await ErrorLogService.instance.clearLogs();
                  if (!mounted) return;
                  setState(() {});
                  // ignore: use_build_context_synchronously
                  AppPopups.showSnackBar(context: ctx, message: 'Error logs cleared.');
                },
              ),
            ],
          ),

          // ── CATEGORY 4: ABOUT ────────────────────────────────────────────
          SettingsCategory(
            title: 'About',
            icon: Icons.info_outline_rounded,
            children: [
              const SettingsTile(
                title: 'App Version',
                subtitle: 'FluxConvert Enterprise v1.2.0 (Build 55)',
                icon: Icons.verified_outlined,
                iconColor: Colors.blue,
              ),
              SettingsTile(
                title: 'Privacy Policy',
                subtitle: 'Read how your local data is protected',
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.green,
                onTap: () => _showInfoDialog(
                  'Privacy Policy',
                  'FluxConvert processes all file conversions locally on your device. We do not transmit your documents or personal data to any external cloud servers.',
                ),
              ),
              SettingsTile(
                title: 'Terms of Service',
                subtitle: 'App terms & license agreements',
                icon: Icons.description_outlined,
                iconColor: Colors.blueGrey,
                onTap: () => _showInfoDialog(
                  'Terms of Service',
                  'FluxConvert is provided as-is. All converted files remain your exclusive property. Always verify critical documents after conversion.',
                ),
              ),
            ],
          ),

          // ── CATEGORY 5: HELP & SUPPORT ──────────────────────────────────
          SettingsCategory(
            title: 'Help & Support',
            icon: Icons.help_outline_rounded,
            children: [
              SettingsTile(
                title: 'Frequently Asked Questions',
                subtitle: 'Common conversion & PDF questions',
                icon: Icons.quiz_outlined,
                iconColor: Colors.purple,
                onTap: () => _showInfoDialog(
                  'Frequently Asked Questions',
                  'Q: Are my files uploaded to the internet?\nA: No, 100% offline local processing.\n\nQ: How do I unlock password PDFs?\nA: Open the PDF in Viewer and enter the password when prompted.',
                ),
              ),
              SettingsTile(
                title: 'Request a Feature',
                subtitle: 'Suggest ideas or new formats',
                icon: Icons.lightbulb_outline_rounded,
                iconColor: Colors.amber.shade700,
                onTap: _showFeatureRequestDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showErrorLogsSheet(BuildContext context) {
    final logs = ErrorLogService.instance.currentLogs.reversed.toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.bug_report_outlined, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error Logs (${logs.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Log list
            Expanded(
              child: logs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green),
                          SizedBox(height: 8),
                          Text('No errors logged', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final severityColor = switch (log.severity) {
                          ErrorSeverity.crash => Colors.red,
                          ErrorSeverity.performance => Colors.deepOrange,
                          ErrorSeverity.warning => Colors.amber.shade800,
                          ErrorSeverity.info => Colors.blue,
                        };

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: severityColor.withOpacity(0.3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: severityColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        log.severity.name.toUpperCase(),
                                        style: TextStyle(
                                          color: severityColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      log.category.name.toUpperCase(),
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                    const Spacer(),
                                    Text(
                                      log.timestamp,
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  log.message,
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (log.screenName.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Screen: ${log.screenName}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
