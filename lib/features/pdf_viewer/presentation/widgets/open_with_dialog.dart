import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/storage/presentation/storage_manager.dart';

// IMPROVED: Open With Dialog & App Selector (Layer 9)
class OpenWithDialog extends ConsumerStatefulWidget {
  const OpenWithDialog({
    required this.filePath,
    super.key,
  });

  final String filePath;

  static void show(BuildContext context, {required String filePath}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => OpenWithDialog(filePath: filePath),
    );
  }

  @override
  ConsumerState<OpenWithDialog> createState() => _OpenWithDialogState();
}

class _OpenWithDialogState extends ConsumerState<OpenWithDialog> {
  bool _rememberChoice = false;

  Future<void> _openWithOption(String optionKey) async {
    if (_rememberChoice) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_open_action', optionKey);
    }

    if (!mounted) return;
    Navigator.pop(context);

    try {
      final storageMgr = ref.read(storageManagerProvider);
      await storageMgr.openFile(widget.filePath);
    } catch (e) {
      AppLogger.error('OpenWithDialog: Failed to open file', e);
      if (mounted) {
        AppPopups.showSnackBar(
          context: context,
          message: 'Could not open file with selected application.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last.split(r'\').last;
    final ext = widget.filePath.split('.').last.toUpperCase();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.open_in_new_rounded, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          const Text('Open With'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fileName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Text('Choose application to open $ext file:'),
          const SizedBox(height: 12),

          // Application Option List
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
            title: const Text('Built-in PDF Viewer'),
            subtitle: const Text('FluxConvert Reader'),
            onTap: () => _openWithOption('internal_pdf'),
          ),
          ListTile(
            leading: const Icon(Icons.system_update_alt_rounded, color: Colors.blue),
            title: const Text('System Default App'),
            subtitle: const Text('Open with external Android app'),
            onTap: () => _openWithOption('system_default'),
          ),

          const Divider(),

          // Remember choice checkbox
          CheckboxListTile(
            title: const Text('Always use this app', style: TextStyle(fontSize: 12)),
            value: _rememberChoice,
            onChanged: (val) => setState(() => _rememberChoice = val ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
