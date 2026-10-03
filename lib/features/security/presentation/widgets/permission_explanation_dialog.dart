import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PermissionExplanationDialog — Beautiful Material 3 dialog for permissions.
/// ─────────────────────────────────────────────────────────────────────────────
class PermissionExplanationDialog extends StatelessWidget {
  const PermissionExplanationDialog({
    required this.title,
    required this.message,
    required this.onOpenSettings,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onOpenSettings;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onOpenSettings,
  }) {
    return showDialog(
      context: context,
      builder: (context) => PermissionExplanationDialog(
        title: title,
        message: message,
        onOpenSettings: onOpenSettings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.security_rounded,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onOpenSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    );
  }
}
