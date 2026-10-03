import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/scan_session.dart';
import 'package:flux_convert/features/smart_scan/presentation/controllers/scan_session_notifier.dart';

/// SmartScanReviewPage — Polished final review screen before PDF compilation.
/// Integrates directly with FluxConvert's existing converter architecture.
class SmartScanReviewPage extends ConsumerStatefulWidget {
  const SmartScanReviewPage({super.key});

  @override
  ConsumerState<SmartScanReviewPage> createState() =>
      _SmartScanReviewPageState();
}

class _SmartScanReviewPageState extends ConsumerState<SmartScanReviewPage> {
  late TextEditingController _filenameController;
  late TextEditingController _passwordController;

  bool _isPasswordEnabled = false;
  bool _isWhiteMarginsEnabled = false;
  bool _obscurePassword = true;

  String _selectedCompression = 'Low Compression';
  String _selectedPageSize = 'A4';
  String _selectedOrientation = 'Auto';
  bool _isConverting = false;

  static const Map<String, String> _pageSizeDimensions = {
    'A0': '84.1 × 118.9 cm',
    'A1': '59.4 × 84.1 cm',
    'A2': '42.0 × 59.4 cm',
    'A3': '29.7 × 42.0 cm',
    'A4': '21.0 × 29.7 cm',
    'A5': '14.8 × 21.0 cm',
    'Letter': '21.6 × 27.9 cm',
    'Legal': '21.6 × 35.6 cm',
    'Executive': '18.4 × 26.7 cm',
  };

  @override
  void initState() {
    super.initState();
    final timeStamp = DateTime.now().millisecondsSinceEpoch;
    _filenameController = TextEditingController(text: 'Scanned_Doc_$timeStamp');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _filenameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _calculateFormattedSize(List<String> filePaths) {
    var totalBytes = 0;
    for (final path in filePaths) {
      try {
        final f = File(path);
        if (f.existsSync()) {
          totalBytes += f.lengthSync();
        }
      } catch (_) {}
    }
    if (totalBytes == 0) return '~500 KB';
    if (totalBytes >= 1024 * 1024) {
      final mb = totalBytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    }
    final kb = totalBytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }

  Future<void> _createPdf() async {
    if (_isConverting) return;

    final session = ref.read(scanSessionProvider);
    if (session.pages.isEmpty) {
      AppPopups.showSnackBar(
        context: context,
        message: 'No document pages to compile.',
        isError: true,
      );
      return;
    }

    final finalPaths = session.pages.map((p) => p.processedPath).toList();
    for (final path in finalPaths) {
      if (!File(path).existsSync()) {
        AppPopups.showSnackBar(
          context: context,
          message: 'Page image missing at $path',
          isError: true,
        );
        return;
      }
    }

    setState(() => _isConverting = true);
    HapticFeedback.mediumImpact();

    final rawName = _filenameController.text.trim();
    final outputPdfName = rawName.isEmpty
        ? 'Scanned_Doc_${DateTime.now().millisecondsSinceEpoch}.pdf'
        : (rawName.endsWith('.pdf') ? rawName : '$rawName.pdf');

    final firstPath = finalPaths.first;
    final totalSize = finalPaths.fold<int>(0, (sum, p) {
      final f = File(p);
      return sum + (f.existsSync() ? f.lengthSync() : 0);
    });

    final converterNotifier = ref.read(converterNotifierProvider.notifier);

    converterNotifier.setFile(
      firstPath,
      outputPdfName,
      totalSize,
      FileCategory.image,
      ConversionFormat.jpg,
      additionalPaths: finalPaths.sublist(1),
      additionalNames: List.generate(
        finalPaths.length - 1,
        (i) => 'page_${i + 2}.jpg',
      ),
    );

    converterNotifier.setPdfPassword(_isPasswordEnabled ? _passwordController.text : null);
    converterNotifier.setMarginOption(_isWhiteMarginsEnabled ? 'small' : 'none');
    converterNotifier.setPageSizeOption(_selectedPageSize);
    converterNotifier.setOrientationOption(_selectedOrientation);
    converterNotifier.setCompressionOption(_selectedCompression);

    converterNotifier.selectOutputFormat(ConversionFormat.pdf);

    final router = GoRouter.of(context);
    router.go(AppRoutes.converter);

    await converterNotifier.startConversionFlow(() {
      if (mounted) {
        // Clean up temporary scan files safely after successful compilation
        ref.read(scanSessionProvider.notifier).clearSession(deleteFiles: true);
        router.go(AppRoutes.conversionSuccess);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scanSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filePaths = session.pages.map((p) => p.processedPath).toList();
    final sizeText = _calculateFormattedSize(filePaths);

    return Scaffold(
      backgroundColor: isDark ? AppColorScheme.backgroundDark : AppColorScheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Compile PDF Document',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Document Summary Card ─────────────────────────────
              _buildDocumentCard(context, session, sizeText, isDark),
              const SizedBox(height: 20),

              // ── 2. PDF Settings Card ─────────────────────────────────
              _buildSettingsCard(context, isDark),
              const SizedBox(height: 28),

              // ── 3. Action CTAs ───────────────────────────────────────
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColorScheme.primaryBlueStart),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.pop(),
                child: const Text(
                  'Continue Editing Pages',
                  style: TextStyle(
                    color: AppColorScheme.primaryBlueStart,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorScheme.primaryBlueStart,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isConverting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: Text(
                  _isConverting ? 'Compiling PDF...' : 'Create PDF Document',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isConverting ? null : _createPdf,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    ScanSession session,
    String sizeText,
    bool isDark,
  ) {
    final firstPage = session.activePage ?? (session.pages.isNotEmpty ? session.pages.first : null);
    final previewFile = firstPage != null
        ? File(firstPage.processedPath.isNotEmpty ? firstPage.processedPath : firstPage.originalPath)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColorScheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Page 1 Thumbnail Box
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColorScheme.primaryBlueStart, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: previewFile != null && previewFile.existsSync()
                    ? Image.file(previewFile, fit: BoxFit.cover)
                    : const Icon(Icons.description_rounded, color: Colors.white38),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _filenameController,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: const InputDecoration(
                        labelText: 'PDF Document Name',
                        border: UnderlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColorScheme.primaryBlueStart.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${session.pageCount} Pages',
                            style: const TextStyle(
                              color: AppColorScheme.primaryBlueStart,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Est. Size: $sizeText',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColorScheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PDF Output Settings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // 1. Page Size Row
          _buildSelectionRow(
            icon: Icons.description_outlined,
            title: 'PDF Page Size',
            subtext: '$_selectedPageSize (${_pageSizeDimensions[_selectedPageSize] ?? ''})',
            onTap: () => _showPageSizeDialog(),
          ),
          const Divider(height: 16),

          // 2. Orientation Row
          _buildSelectionRow(
            icon: Icons.screen_rotation_rounded,
            title: 'Page Orientation',
            subtext: _selectedOrientation,
            onTap: () => _showOrientationDialog(),
          ),
          const Divider(height: 16),

          // 3. Compression Row
          _buildSelectionRow(
            icon: Icons.compress_rounded,
            title: 'Image Compression',
            subtext: _selectedCompression,
            onTap: () => _showCompressionDialog(),
          ),
          const Divider(height: 16),

          // 4. White Margins Switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add White Margins', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Adds standard padding border around scanned pages', style: TextStyle(fontSize: 12, color: Colors.grey)),
            value: _isWhiteMarginsEnabled,
            activeColor: AppColorScheme.primaryBlueStart,
            onChanged: (val) => setState(() => _isWhiteMarginsEnabled = val),
          ),
          const Divider(height: 16),

          // 5. Password Protection Switch & Input
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('PDF Password Encryption', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Protect document with password', style: TextStyle(fontSize: 12, color: Colors.grey)),
            value: _isPasswordEnabled,
            activeColor: AppColorScheme.primaryBlueStart,
            onChanged: (val) => setState(() => _isPasswordEnabled = val),
          ),
          if (_isPasswordEnabled) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Enter PDF Password',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionRow({
    required IconData icon,
    required String title,
    required String subtext,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColorScheme.primaryBlueStart, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtext, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showPageSizeDialog() {
    final sizes = _pageSizeDimensions.keys.toList();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select PDF Page Size'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sizes.map((size) {
              final dims = _pageSizeDimensions[size] ?? '';
              return RadioListTile<String>(
                title: Text(size),
                subtitle: Text(dims),
                value: size,
                groupValue: _selectedPageSize,
                activeColor: AppColorScheme.primaryBlueStart,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedPageSize = val);
                    Navigator.pop(ctx);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showOrientationDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Orientation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Auto', 'Portrait', 'Landscape'].map((opt) {
            return RadioListTile<String>(
              title: Text(opt),
              value: opt,
              groupValue: _selectedOrientation,
              activeColor: AppColorScheme.primaryBlueStart,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedOrientation = val);
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCompressionDialog() {
    final options = [
      'Max Compression',
      'Medium Compression',
      'Regular Compression',
      'Low Compression',
    ];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Compression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            return RadioListTile<String>(
              title: Text(opt),
              value: opt,
              groupValue: _selectedCompression,
              activeColor: AppColorScheme.primaryBlueStart,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCompression = val);
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
