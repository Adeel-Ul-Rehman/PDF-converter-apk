import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:flux_convert/features/conversion/core/adapters/placeholders.dart';
import 'package:flux_convert/features/conversion/core/adapters/conversion_context.dart';
import 'package:flux_convert/features/conversion/core/adapters/conversion_settings.dart';

class ConvertToPdfSheet extends ConsumerStatefulWidget {
  const ConvertToPdfSheet({super.key});

  @override
  ConsumerState<ConvertToPdfSheet> createState() => _ConvertToPdfSheetState();
}

class _ConvertToPdfSheetState extends ConsumerState<ConvertToPdfSheet> {
  late TextEditingController _renameController;
  late TextEditingController _passwordController;
  
  bool _isPasswordEnabled = false;
  bool _isWhiteMarginsEnabled = false;
  bool _obscurePassword = true;
  
  String _selectedCompression = 'Low Compression';
  String _selectedPageSize = 'A4';
  String _selectedOrientation = 'Auto';

  bool _isPreparingPreview = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(converterNotifierProvider);
    
    final currentName = state.selectedFileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ?? 'Image to PDF';
    _renameController = TextEditingController(text: currentName);
    
    _passwordController = TextEditingController(text: state.pdfPassword ?? '');
    _isPasswordEnabled = state.pdfPassword != null && state.pdfPassword!.isNotEmpty;
    _isWhiteMarginsEnabled = state.marginOption != 'none';
    
    _selectedCompression = state.compressionOption;
    _selectedPageSize = state.pageSizeOption;
    _selectedOrientation = state.orientationOption;
  }

  @override
  void dispose() {
    _renameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper: Open selection dialog
  void _showSelectionDialog({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select $title'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              return RadioListTile<String>(
                title: Text(opt),
                value: opt,
                groupValue: currentValue,
                activeColor: AppColorScheme.primaryBlueStart,
                onChanged: (val) {
                  if (val != null) {
                    onSelected(val);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Standard paper sizes with physical dimensions (width × height in cm)
  static const Map<String, String> _pageSizeDimensions = {
    'A0': '84.1 × 118.9 cm',
    'A1': '59.4 × 84.1 cm',
    'A2': '42.0 × 59.4 cm',
    'A3': '29.7 × 42.0 cm',
    'A4': '21.0 × 29.7 cm',
    'A5': '14.8 × 21.0 cm',
    'A6': '10.5 × 14.8 cm',
    'Letter': '21.6 × 27.9 cm',
    'Legal': '21.6 × 35.6 cm',
    'Executive': '18.4 × 26.7 cm',
    'Ledger': '43.2 × 27.9 cm',
    'Tabloid': '27.9 × 43.2 cm',
    'B4': '25.0 × 35.3 cm',
    'B5': '17.6 × 25.0 cm',
  };

  // Helper: Open page-size dialog with dimensions subtitle
  void _showPageSizeDialog({
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    final sizes = _pageSizeDimensions.keys.toList();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorScheme.primaryBlueStart.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_outlined,
                  color: AppColorScheme.primaryBlueStart, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('PDF Page Size',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: sizes.map((size) {
                final dims = _pageSizeDimensions[size] ?? '';
                final isSelected = currentValue == size;
                return InkWell(
                  onTap: () {
                    onSelected(size);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColorScheme.primaryBlueStart.withAlpha(15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColorScheme.primaryBlueStart
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio indicator
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColorScheme.primaryBlueStart
                                  : AppColorScheme.border,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColorScheme.primaryBlueStart,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        // Size name
                        Text(
                          size,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColorScheme.primaryBlueStart
                                : AppColorScheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        // Dimensions badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColorScheme.primaryBlueStart.withAlpha(20)
                                : AppColorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColorScheme.primaryBlueStart
                                      .withAlpha(60)
                                  : AppColorScheme.border,
                            ),
                          ),
                          child: Text(
                            dims,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColorScheme.primaryBlueStart
                                  : AppColorScheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  static const List<({String title, String subtitle})> _compressionOptions = [
    (title: 'Max Compression', subtitle: '(low quality, low size)'),
    (title: 'Medium Compression', subtitle: '(medium quality, medium size)'),
    (title: 'Regular Compression', subtitle: '(good quality, balanced size)'),
    (title: 'Low Compression', subtitle: '(high quality, high size)'),
  ];

  // Helper: Open 2-line formatted Compression Settings dialog
  void _showCompressionDialog({
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColorScheme.cardDark : AppColorScheme.cardLight,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorScheme.primaryBlueStart.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.compress_rounded,
                color: AppColorScheme.primaryBlueStart,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Compression Settings',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColorScheme.textPrimaryDark : AppColorScheme.textPrimaryLight,
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _compressionOptions.map((opt) {
                final isSelected = currentValue == opt.title;

                return InkWell(
                  onTap: () {
                    onSelected(opt.title);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColorScheme.primaryBlueStart.withAlpha(isDark ? 30 : 15)
                          : (isDark ? const Color(0xFF242834) : const Color(0xFFF6F7FA)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColorScheme.primaryBlueStart
                            : (isDark ? AppColorScheme.borderDark : AppColorScheme.borderLight),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio indicator
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColorScheme.primaryBlueStart
                                  : (isDark ? AppColorScheme.textSecondaryDark : AppColorScheme.borderLight),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColorScheme.primaryBlueStart,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),

                        // Title & Subtitle in 2 distinct lines
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isDark ? AppColorScheme.textPrimaryDark : AppColorScheme.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opt.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected
                                      ? AppColorScheme.primaryBlueStart
                                      : (isDark ? AppColorScheme.textSecondaryDark : AppColorScheme.textSecondaryLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Compile PDF locally and navigate to full-screen in-app PDF Viewer for Preview
  Future<void> _previewPdf() async {
    final state = ref.read(converterNotifierProvider);
    if (state.selectedFilePath == null) return;

    setState(() => _isPreparingPreview = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final previewFile = File('${tempDir.path}/preview_temp_${DateTime.now().millisecondsSinceEpoch}.pdf');

      // Create context parameters
      final conversionContext = ConversionContext(
        inputFile: File(state.selectedFilePath!),
        outputPath: previewFile.path,
        tempDirectory: tempDir,
        settings: ConversionSettings(
          customParameters: {
            'additionalFiles': state.additionalSelectedFilePaths,
            'margin': _isWhiteMarginsEnabled ? 'small' : 'none',
            'pageFit': 'fit',
            'pdfPassword': _isPasswordEnabled ? _passwordController.text : null,
            'pageSize': _selectedPageSize,
            'orientation': _selectedOrientation,
            'compression': _selectedCompression,
          },
        ),
      );

      // FIXED: Await async PDF compilation
      await const ImageConverter().executePackageConversion(conversionContext, (_) {});

      // FIXED: Open in-app full-screen PDF Viewer for crisp interactive preview
      if (previewFile.existsSync() && mounted) {
        Navigator.pop(context); // Close convert sheet
        context.push(AppRoutes.pdfViewer, extra: previewFile.path);
      }
    } catch (e) {
      if (!mounted) return;
      AppPopups.showSnackBar(
        context: context,
        message: 'Failed to generate preview: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isPreparingPreview = false);
      }
    }
  }

  // Apply parameters and trigger conversion
  void _convertPdf() {
    final state = ref.read(converterNotifierProvider);
    final notifier = ref.read(converterNotifierProvider.notifier);

    final finalName = _renameController.text.trim();
    final outputPdfName = finalName.endsWith('.pdf') ? finalName : '$finalName.pdf';

    // Apply states
    notifier.setFile(
      state.selectedFilePath!,
      outputPdfName,
      state.selectedFileSize ?? 0,
      state.selectedFileCategory ?? FileCategory.image,
      state.selectedInputFormat ?? ConversionFormat.png,
      additionalPaths: state.additionalSelectedFilePaths,
      additionalNames: state.additionalSelectedFileNames,
    );

    notifier.setPdfPassword(_isPasswordEnabled ? _passwordController.text : null);
    notifier.setMarginOption(_isWhiteMarginsEnabled ? 'small' : 'none');
    notifier.setPageSizeOption(_selectedPageSize);
    notifier.setOrientationOption(_selectedOrientation);
    notifier.setCompressionOption(_selectedCompression);

    notifier.selectOutputFormat(ConversionFormat.pdf);

    Navigator.pop(context); // close bottom sheet

    // Capture router before async gap to prevent context exceptions
    final router = GoRouter.of(context);
    router.go(AppRoutes.converter);
    notifier.startConversionFlow(() {
      router.go(AppRoutes.conversionSuccess);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Title and Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Convert to PDF',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. Rename TextField row
              Row(
                children: [
                  const Icon(Icons.edit_outlined, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _renameController,
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                          onPressed: () => _renameController.clear(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Password Checkbox row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        'Password',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Checkbox(
                    value: _isPasswordEnabled,
                    activeColor: AppColorScheme.primaryBlueStart,
                    onChanged: (val) {
                      setState(() {
                        _isPasswordEnabled = val ?? false;
                      });
                    },
                  ),
                ],
              ),
              
              // Password input box (appears when checked)
              if (_isPasswordEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 36, bottom: 8),
                  child: TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'Enter PDF Password',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                  ),
                ),

              // 3. White Margins row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.crop_free_outlined, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        'White Margins',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Checkbox(
                    value: _isWhiteMarginsEnabled,
                    activeColor: AppColorScheme.primaryBlueStart,
                    onChanged: (val) {
                      setState(() {
                        _isWhiteMarginsEnabled = val ?? false;
                      });
                    },
                  ),
                ],
              ),
              const Divider(height: 24),

              // 4. Compression Settings row
              _buildSelectionRow(
                icon: Icons.compress_outlined,
                title: 'Compression Settings',
                subtext: _selectedCompression,
                onTap: () {
                  _showCompressionDialog(
                    currentValue: _selectedCompression,
                    onSelected: (val) {
                      setState(() => _selectedCompression = val);
                    },
                  );
                },
              ),

              // 5. PDF Page Size row
              _buildSelectionRow(
                icon: Icons.description_outlined,
                title: 'PDF Page Size',
                subtext: _selectedPageSize,
                onTap: () {
                  _showPageSizeDialog(
                    currentValue: _selectedPageSize,
                    onSelected: (val) {
                      setState(() => _selectedPageSize = val);
                    },
                  );
                },
              ),

              // 6. Orientation row
              _buildSelectionRow(
                icon: Icons.stay_current_portrait_rounded,
                title: 'Orientation',
                subtext: _selectedOrientation,
                onTap: () {
                  _showSelectionDialog(
                    title: 'Orientation',
                    options: const ['Auto', 'Portrait', 'Landscape'],
                    currentValue: _selectedOrientation,
                    onSelected: (val) {
                      setState(() => _selectedOrientation = val);
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Outline Preview & Solid Convert CTA buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColorScheme.primaryBlueStart, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isPreparingPreview ? null : _previewPdf,
                      child: _isPreparingPreview
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'PREVIEW',
                              style: TextStyle(
                                color: AppColorScheme.primaryBlueStart,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorScheme.primaryBlueStart,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _convertPdf,
                      child: const Text(
                        'CONVERT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // List Row Helper
  Widget _buildSelectionRow({
    required IconData icon,
    required String title,
    required String subtext,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtext,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
