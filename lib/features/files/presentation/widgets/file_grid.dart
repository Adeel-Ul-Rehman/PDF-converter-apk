import 'package:flutter/material.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/storage/domain/usecases/scan_all_files_use_case.dart';

// IMPROVED: File Grid Card widget
class FileGridCard extends StatelessWidget {
  const FileGridCard({
    required this.file,
    required this.onTap,
    super.key,
  });

  final DiscoveredFile file;
  final VoidCallback onTap;

  Color _getFormatColor(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Colors.red.shade700;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
      case 'bmp':
        return Colors.purple.shade600;
      case 'doc':
      case 'docx':
        return Colors.blue.shade700;
      case 'xlsx':
      case 'csv':
        return Colors.green.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatColor = _getFormatColor(file.extension);
    final sizeFormatted = FileSizeUtils.format(file.sizeBytes);

    return RepaintBoundary(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColorScheme.border.withAlpha(100)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: formatColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        file.extension.toUpperCase(),
                        style: TextStyle(
                          color: formatColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(Icons.insert_drive_file_outlined, color: formatColor, size: 24),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sizeFormatted,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
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
