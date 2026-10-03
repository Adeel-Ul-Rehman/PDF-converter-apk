import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/history/domain/entities/conversion_history.dart';

// IMPROVED: Recent file card widget for the horizontal carousel on home screen
class RecentFileCard extends StatelessWidget {
  const RecentFileCard({
    required this.item,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
    super.key,
  });

  final ConversionHistory item;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  Color _colorForFormat(String format) {
    switch (format.toLowerCase()) {
      case 'pdf':
        return Colors.red.shade700;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return Colors.purple.shade600;
      case 'doc':
      case 'docx':
        return Colors.blue.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmtColor = _colorForFormat(item.destinationFormat);
    final sizeText = FileSizeUtils.format(item.convertedFileSize);
    final hasThumb = item.thumbnailPath != null &&
        File(item.thumbnailPath!).existsSync();

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showOptionsSheet(context),
        child: Container(
          width: 150,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColorScheme.border.withAlpha(100)),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail or format icon
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: hasThumb
                      ? Image.file(
                          File(item.thumbnailPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => ColoredBox(
                            color: fmtColor.withOpacity(0.1),
                            child: Center(
                              child: Text(
                                item.destinationFormat.toUpperCase(),
                                style: TextStyle(
                                  color: fmtColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        )
                      : ColoredBox(
                          color: fmtColor.withOpacity(0.1),
                          child: Center(
                            child: Text(
                              item.destinationFormat.toUpperCase(),
                              style: TextStyle(
                                color: fmtColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              // File info
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.destinationFileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sizeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open File'),
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(ctx);
                onShare();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
