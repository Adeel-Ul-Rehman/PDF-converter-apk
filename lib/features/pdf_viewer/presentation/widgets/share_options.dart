import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flux_convert/core/core.dart';

// IMPROVED: Comprehensive Share Options Modal Sheet (Layer 9)
/// Renders share options grid & list: Email, WhatsApp, Google Drive, Dropbox,
/// Telegram, Copy Path to Clipboard, Save to Specific Location, and Share Link.
class ShareOptionsSheet extends StatelessWidget {
  const ShareOptionsSheet({
    required this.filePath,
    this.fileName,
    super.key,
  });

  final String filePath;
  final String? fileName;

  static void show(BuildContext context, {required String filePath, String? fileName}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ShareOptionsSheet(filePath: filePath, fileName: fileName),
    );
  }

  Future<void> _shareViaSystem(BuildContext context, [String? text]) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      AppPopups.showSnackBar(context: context, message: 'File not found.', isError: true);
      return;
    }
    await Share.shareXFiles([XFile(filePath)], text: text);
  }

  Future<void> _saveToFolder(BuildContext context) async {
    try {
      final selectedDir = await FilePicker.platform.getDirectoryPath();
      if (selectedDir != null) {
        final srcFile = File(filePath);
        final name = fileName ?? filePath.split('/').last.split(r'\').last;
        final destPath = '$selectedDir/$name';
        await srcFile.copy(destPath);

        if (!context.mounted) return;
        AppPopups.showSnackBar(
          context: context,
          message: 'File saved to: $destPath',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.error('Failed copying file to directory', e);
      if (!context.mounted) return;
      AppPopups.showSnackBar(
        context: context,
        message: 'Could not save file to selected folder.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = fileName ?? filePath.split('/').last.split(r'\').last;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share_rounded, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Share Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Share Targets Grid
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _ShareGridItem(
                label: 'Email',
                icon: Icons.email_outlined,
                color: Colors.red.shade600,
                onTap: () => _shareViaSystem(context, 'Sharing file attachment via Email'),
              ),
              _ShareGridItem(
                label: 'WhatsApp',
                icon: Icons.chat_bubble_outline_rounded,
                color: Colors.green.shade600,
                onTap: () => _shareViaSystem(context, 'Sharing file via WhatsApp'),
              ),
              _ShareGridItem(
                label: 'Drive',
                icon: Icons.add_to_drive_rounded,
                color: Colors.amber.shade800,
                onTap: () => _shareViaSystem(context, 'Save file to Google Drive'),
              ),
              _ShareGridItem(
                label: 'Telegram',
                icon: Icons.send_rounded,
                color: Colors.lightBlue.shade600,
                onTap: () => _shareViaSystem(context, 'Sharing file via Telegram'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Advanced File Action Options
          ListTile(
            leading: const Icon(Icons.folder_special_outlined, color: Colors.indigo),
            title: const Text('Save to Custom Folder'),
            subtitle: const Text('Pick target directory on device'),
            onTap: () => _saveToFolder(context),
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded, color: Colors.teal),
            title: const Text('Copy File Path to Clipboard'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: filePath));
              AppPopups.showSnackBar(context: context, message: 'File path copied to clipboard.');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link_rounded, color: Colors.purple),
            title: const Text('Share File Link'),
            subtitle: const Text('Copy file URI link'),
            onTap: () {
              final fileUri = Uri.file(filePath).toString();
              Clipboard.setData(ClipboardData(text: fileUri));
              AppPopups.showSnackBar(context: context, message: 'File URI link copied.');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ShareGridItem extends StatelessWidget {
  const _ShareGridItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
