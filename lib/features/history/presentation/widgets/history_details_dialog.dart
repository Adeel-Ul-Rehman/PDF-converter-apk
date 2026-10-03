import 'package:flutter/material.dart';

import 'package:flux_convert/features/history/domain/entities/conversion_history.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// HistoryDetailsDialog
///
/// Material 3 modal bottom sheet detailing conversion file metrics securely.
/// ─────────────────────────────────────────────────────────────────────────────
class HistoryDetailsDialog extends StatelessWidget {
  const HistoryDetailsDialog({
    required this.item,
    super.key,
  });

  final ConversionHistory item;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.conversionStatus == 'completed'
        ? Colors.green.shade700
        : item.conversionStatus == 'failed'
            ? Colors.red.shade700
            : Colors.orange.shade700;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pull bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Conversion Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Source info
            _buildDetailRow(
              context,
              label: 'Source Name',
              value: item.sourceFileName,
              icon: Icons.description_outlined,
            ),
            const Divider(height: 24),

            // Destination info
            _buildDetailRow(
              context,
              label: 'Destination Name',
              value: item.destinationFileName,
              icon: Icons.insert_drive_file_outlined,
            ),
            const Divider(height: 24),

            // Duration
            _buildDetailRow(
              context,
              label: 'Duration',
              value: '${item.conversionDuration.inMilliseconds} ms',
              icon: Icons.timer_outlined,
            ),
            const Divider(height: 24),

            // Output Size
            _buildDetailRow(
              context,
              label: 'File Size',
              value: _formatBytes(item.convertedFileSize),
              icon: Icons.storage_outlined,
            ),
            const Divider(height: 24),

            // Status Badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.conversionStatus.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),

            if (item.errorMessage != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                context,
                label: 'Failure Reason',
                value: item.errorMessage!,
                icon: Icons.error_outline,
                textColor: Colors.red.shade800,
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? textColor,
  }) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor ?? Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    var d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
