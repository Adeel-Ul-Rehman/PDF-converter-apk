import 'package:flutter/material.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/storage/domain/usecases/scan_all_files_use_case.dart';

// IMPROVED: File List Row Card widget
class FileCard extends StatelessWidget {
  const FileCard({
    required this.file,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
    super.key,
  });

  final DiscoveredFile file;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  Color _getFormatColor(String ext) {
    return AppColorScheme.primaryBlueStart;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatColor = _getFormatColor(file.extension);
    final sizeFormatted = FileSizeUtils.format(file.sizeBytes);
    final dateFormatted = DateFormatter.formatShortDate(file.modifiedDate);
    final titleColor = isDark ? AppColorScheme.textPrimaryDark : AppColorScheme.textPrimaryLight;
    final subtitleColor = isDark ? AppColorScheme.textSecondaryDark : AppColorScheme.textSecondaryLight;
    final cardBgColor = isDark ? AppColorScheme.cardDark : AppColorScheme.cardLight;

    return RepaintBoundary(
      child: Card(
        color: cardBgColor,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColorScheme.borderDark : AppColorScheme.borderLight,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Format Icon Badge
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: formatColor.withOpacity(isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      file.extension.toUpperCase(),
                      style: TextStyle(
                        color: formatColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // File Name & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$sizeFormatted  •  $dateFormatted',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  onPressed: onShare,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (val) {
                    if (val == 'open') onTap();
                    if (val == 'share') onShare();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'open', child: Text('Open File')),
                    const PopupMenuItem(value: 'share', child: Text('Share')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
