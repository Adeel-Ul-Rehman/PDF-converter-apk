import 'package:flutter/material.dart';

import 'package:flux_convert/core/core.dart';

// IMPROVED: Settings Tile Widget supporting switches, value indicators, and navigation
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.valueText,
    this.isSwitch = false,
    this.switchValue = false,
    this.onSwitchChanged,
    this.onTap,
    this.badgeCount,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final String? valueText;
  final bool isSwitch;
  final bool switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final VoidCallback? onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColorScheme.textPrimaryDark : AppColorScheme.textPrimaryLight;
    final subtitleColor = isDark ? AppColorScheme.textSecondaryDark : AppColorScheme.textSecondaryLight;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColorScheme.primaryBlueStart.withOpacity(isDark ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColorScheme.primaryBlueStart, size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
          ),
          if (badgeCount != null && badgeCount! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColorScheme.danger,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor,
              ),
            )
          : null,
      trailing: isSwitch
          ? Switch(
              value: switchValue,
              onChanged: onSwitchChanged,
              activeColor: AppColorScheme.primaryBlueStart,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (valueText != null)
                  Text(
                    valueText!,
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: subtitleColor, size: 20),
              ],
            ),
      onTap: isSwitch
          ? () => onSwitchChanged?.call(!switchValue)
          : onTap,
    );
  }
}
