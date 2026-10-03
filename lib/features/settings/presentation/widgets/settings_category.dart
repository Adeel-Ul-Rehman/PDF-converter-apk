import 'package:flutter/material.dart';

import 'package:flux_convert/core/core.dart';

// IMPROVED: Category header & container widget for grouping settings options
class SettingsCategory extends StatelessWidget {
  const SettingsCategory({
    required this.title,
    required this.children,
    this.icon,
    super.key,
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColorScheme.primaryBlueStart),
                const SizedBox(width: 8),
              ],
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColorScheme.primaryBlueStart,
                ),
              ),
            ],
          ),
        ),

        // Children Card Container
        Card(
          elevation: 0,
          color: isDark ? AppColorScheme.cardDark : AppColorScheme.cardLight,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? AppColorScheme.borderDark : AppColorScheme.borderLight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: isDark ? AppColorScheme.borderDark : AppColorScheme.borderLight,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
