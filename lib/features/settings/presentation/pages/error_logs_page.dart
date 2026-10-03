import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/core/providers/error_provider.dart';
import 'package:flux_convert/core/services/error_log_service.dart';

// IMPROVED: Error Viewer Page with color-coded severity, category filter, expandable stack trace, and log export
class ErrorLogsPage extends ConsumerStatefulWidget {
  const ErrorLogsPage({super.key});

  @override
  ConsumerState<ErrorLogsPage> createState() => _ErrorLogsPageState();
}

class _ErrorLogsPageState extends ConsumerState<ErrorLogsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportAndShareLogs() async {
    try {
      final file = await ref.read(errorLogNotifierProvider.notifier).exportLogs();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'FluxConvert System Error Diagnostic Logs',
      );
    } catch (e) {
      if (mounted) {
        AppPopups.showSnackBar(
          context: context,
          message: 'Failed to export logs: $e',
          isError: true,
        );
      }
    }
  }

  void _confirmClearLogs() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Error Logs'),
        content: const Text(
          'Are you sure you want to permanently clear all stored diagnostic logs?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(errorLogNotifierProvider.notifier).clearLogs();
              if (mounted) {
                AppPopups.showSnackBar(
                  context: context,
                  message: 'Diagnostic error logs cleared',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(errorLogNotifierProvider);
    final notifier = ref.read(errorLogNotifierProvider.notifier);
    final filteredLogs = state.filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Error Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: state.logs.isEmpty ? null : _exportAndShareLogs,
            tooltip: 'Export & Share Logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: state.logs.isEmpty ? null : _confirmClearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search TextField
                TextField(
                  controller: _searchController,
                  onChanged: notifier.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search logs by message or screen...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // Category Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: state.selectedCategory == null,
                        onSelected: (_) => notifier.selectCategory(null),
                      ),
                      const SizedBox(width: 6),
                      for (final category in ErrorCategory.values) ...[
                        FilterChip(
                          label: Text(category.name.toUpperCase()),
                          selected: state.selectedCategory == category,
                          onSelected: (_) => notifier.selectCategory(category),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Log List View
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.green.shade400),
                        const SizedBox(height: 12),
                        const Text('No Error Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          state.logs.isEmpty ? 'Your system is running smoothly with 0 errors.' : 'No logs match your filter query.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final entry = filteredLogs[filteredLogs.length - 1 - index];
                      return _buildErrorLogCard(entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorLogCard(ErrorLogEntry entry) {
    final color = switch (entry.severity) {
      ErrorSeverity.crash => Colors.red.shade700,
      ErrorSeverity.warning => Colors.orange.shade800,
      ErrorSeverity.performance => Colors.amber.shade900,
      ErrorSeverity.info => Colors.blue.shade700,
    };

    final icon = switch (entry.category) {
      ErrorCategory.crash => Icons.error_outline_rounded,
      ErrorCategory.freeze => Icons.timer_off_rounded,
      ErrorCategory.performance => Icons.speed_rounded,
      ErrorCategory.network => Icons.wifi_off_rounded,
      ErrorCategory.file => Icons.folder_off_rounded,
      ErrorCategory.memory => Icons.memory_rounded,
      ErrorCategory.navigation => Icons.alt_route_rounded,
      ErrorCategory.state => Icons.report_problem_rounded,
    };

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(80), width: 1.5),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              child: Text(
                entry.severity.name.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '[${entry.category.name.toUpperCase()}]',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              entry.timestamp.split(' ').last,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            entry.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildInfoRow('Screen', entry.screenName),
                if (entry.durationMs != null) _buildInfoRow('Duration', '${entry.durationMs}ms'),
                _buildInfoRow('Timestamp', entry.timestamp),
                _buildInfoRow('App Version', entry.appVersion),

                if (entry.lastUserActions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('User Breadcrumbs:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: entry.lastUserActions.map((b) => Text('• $b', style: const TextStyle(fontSize: 11))).toList(),
                    ),
                  ),
                ],

                if (entry.stackTrace.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Stack Trace:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: entry.stackTrace));
                          AppPopups.showSnackBar(context: context, message: 'Stack trace copied to clipboard');
                        },
                      ),
                    ],
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          entry.stackTrace,
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
