import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/domain/usecases/import_images_use_case.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:flux_convert/features/pdf_viewer/presentation/widgets/open_with_dialog.dart';
import 'package:flux_convert/features/pdf_viewer/presentation/widgets/share_options.dart';

// IMPROVED: Enterprise Converter Dashboard — Layer 10 Rewrite
/// Supports single file conversion & fast background batch image import with
/// compute() thumbnail caching, progress tracking, and cancel options.
class ConverterPage extends ConsumerStatefulWidget {
  const ConverterPage({super.key});

  @override
  ConsumerState<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends ConsumerState<ConverterPage> {
  bool _wakelockEnabled = false;

  // Batch import state
  final ImportImagesUseCase _importUseCase = ImportImagesUseCase();
  bool _isBatchImporting = false;
  ImportProgress? _batchProgress;
  List<ImportedImage> _importedBatchImages = [];

  @override
  void dispose() {
    if (_wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }
    super.dispose();
  }

  Future<void> _startBatchImport() async {
    try {
      final pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (pickerResult == null || pickerResult.files.isEmpty) return;

      final validPaths = pickerResult.files
          .map((f) => f.path)
          .whereType<String>()
          .where((p) => File(p).existsSync())
          .toList();

      if (validPaths.isEmpty) return;

      setState(() {
        _isBatchImporting = true;
        _batchProgress = ImportProgress(
          processedCount: 0,
          totalCount: validPaths.length,
          currentFileName: 'Starting import...',
          progressFraction: 0.0,
        );
      });

      final result = await _importUseCase.executeBatchImport(
        filePaths: validPaths,
        onProgress: (p) {
          if (mounted) setState(() => _batchProgress = p);
        },
      );

      if (!mounted) return;

      setState(() {
        _isBatchImporting = false;
        _importedBatchImages = result.images;
      });

      if (!result.isCancelled && result.images.isNotEmpty) {
        final first = result.images.first;
        final notifier = ref.read(converterNotifierProvider.notifier);
        notifier.setFile(
          first.path,
          '${first.name} (+${result.images.length - 1} images)',
          result.images.fold<int>(0, (sum, img) => sum + img.sizeBytes),
          FileCategory.image,
          ConversionFormat.pdf,
        );

        AppPopups.showSnackBar(
          context: context,
          message: 'Imported ${result.images.length} images successfully!',
        );
      }
    } catch (e) {
      AppLogger.error('ConverterPage: Batch import failed', e);
      if (mounted) {
        setState(() => _isBatchImporting = false);
        AppPopups.showSnackBar(
          context: context,
          message: 'Batch import failed. Please try again.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(converterNotifierProvider);
    final notifier = ref.read(converterNotifierProvider.notifier);

    // Manage wakelock based on conversion state
    if (state.isConverting && !_wakelockEnabled) {
      WakelockPlus.enable();
      _wakelockEnabled = true;
    } else if (!state.isConverting && _wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }

    // Active Batch Import Progress View
    if (_isBatchImporting && _batchProgress != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.s20),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.drive_folder_upload_rounded, color: Colors.purple, size: 48),
                ),
                AppDimensions.h24,
                const Text(
                  'Fast Batch Importing Images',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                AppDimensions.h8,
                Text(
                  'Processing ${_batchProgress!.processedCount} of ${_batchProgress!.totalCount} images...',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                AppDimensions.h4,
                Text(
                  _batchProgress!.currentFileName,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppDimensions.h32,
                LinearProgressIndicator(
                  value: _batchProgress!.progressFraction,
                  backgroundColor: Colors.purple.shade100,
                  color: Colors.purple,
                  minHeight: 8,
                ),
                AppDimensions.h40,
                CustomOutlinedButton(
                  onPressed: () {
                    _importUseCase.cancel();
                    setState(() => _isBatchImporting = false);
                  },
                  child: const Text('Cancel Import'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Simulated Conversion Progress Active Screen
    if (state.isConverting) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.s20),
                  decoration: BoxDecoration(
                    color: AppColorScheme.primaryBlueStart.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const CustomCircularProgress(),
                ),
                AppDimensions.h24,
                Text(
                  state.conversionStatusMessage ?? 'Converting File',
                  style: AppTextStyles.titleLarge,
                ),
                AppDimensions.h8,
                Text(
                  state.selectedFileName ?? 'File',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                AppDimensions.h32,
                PrimaryCard(
                  child: Column(
                    children: [
                      _buildStageRow(
                        'Preparing & reading document',
                        state.conversionPhase == ConversionPhase.preparing ||
                            state.conversionPhase == ConversionPhase.converting ||
                            state.conversionPhase == ConversionPhase.writing ||
                            state.conversionPhase == ConversionPhase.completed,
                        state.conversionPhase == ConversionPhase.preparing,
                      ),
                      const Divider(),
                      _buildStageRow(
                        'Converting formats',
                        state.conversionPhase == ConversionPhase.converting ||
                            state.conversionPhase == ConversionPhase.writing ||
                            state.conversionPhase == ConversionPhase.completed,
                        state.conversionPhase == ConversionPhase.converting,
                      ),
                      const Divider(),
                      _buildStageRow(
                        'Saving output',
                        state.conversionPhase == ConversionPhase.writing ||
                            state.conversionPhase == ConversionPhase.completed,
                        state.conversionPhase == ConversionPhase.writing,
                      ),
                    ],
                  ),
                ),
                AppDimensions.h32,
                AnimatedProgressIndicator(progress: state.conversionProgress),
                AppDimensions.h40,
                CustomOutlinedButton(
                  onPressed: notifier.clearSelection,
                  child: const Text('Cancel Conversion'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 48,
            leading: Padding(
              padding: const EdgeInsets.only(left: AppDimensions.s12),
              child: Image.asset(
                'assets/icons/app_icon.png',
                errorBuilder: (context, error, stackTrace) => const Icon(
                  AppIcons.convert,
                  color: AppColorScheme.primaryBlueStart,
                  size: 24,
                ),
              ),
            ),
            title: Text(
              AppStrings.appName,
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800),
            ),
            centerTitle: true,
            actions: [
              CustomIconButton(
                icon: AppIcons.history,
                onPressed: () => context.go(AppRoutes.history),
              ),
              CustomIconButton(
                icon: AppIcons.settings,
                onPressed: () => context.go(AppRoutes.settings),
              ),
              AppDimensions.w8,
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: AppDimensions.paddingScreenContent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _WelcomeHeader(),
              AppDimensions.h24,

              if (state.validationError != null) ...[
                _ValidationErrorCard(
                  errorMessage: state.validationError!,
                  onRetry: notifier.selectFile,
                ),
                AppDimensions.h20,
              ],

              // File Dropzone / Batch Import Selector Card
              if (state.selectedFilePath == null)
                _FileSelectionCard(
                  onPickFile: notifier.selectFile,
                  onBatchImportImages: _startBatchImport,
                )
              else ...[
                // Selected File or Batch Preview Section
                _SelectedFileCard(
                  fileName: state.selectedFileName ?? 'Selected File',
                  fileSize: state.selectedFileSize ?? 0,
                  inputFormat: state.selectedInputFormat,
                  importedBatchImages: _importedBatchImages,
                  onRemove: () {
                    setState(() => _importedBatchImages = []);
                    notifier.clearSelection();
                  },
                ),
                AppDimensions.h20,

                // Target Format Selection Grid
                const SectionHeader(
                  title: 'Select Output Format',
                ),
                AppDimensions.h12,
                _FormatSelectorGrid(
                  availableFormats: state.possibleOutputFormats,
                  selectedFormat: state.selectedOutputFormat,
                  onFormatSelected: notifier.selectOutputFormat,
                ),
                AppDimensions.h24,

                // PDF Custom Options
                if (state.selectedOutputFormat == ConversionFormat.pdf) ...[
                  const SectionHeader(
                    title: 'PDF Configuration',
                  ),
                  AppDimensions.h12,
                  PrimaryCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.s16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Compression Level',
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                              ),
                              DropdownButton<String>(
                                value: state.compressionOption,
                                items: const [
                                  DropdownMenuItem(value: 'Low Compression', child: Text('Low (Fast)')),
                                  DropdownMenuItem(value: 'Medium Compression', child: Text('Medium')),
                                  DropdownMenuItem(value: 'High Compression', child: Text('High (Small size)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    notifier.setCompressionOption(val);
                                  }
                                },
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Page Scale Fit',
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                              ),
                              DropdownButton<String>(
                                value: state.pageFitOption,
                                items: const [
                                  DropdownMenuItem(value: 'fit', child: Text('Fit Width')),
                                  DropdownMenuItem(value: 'height', child: Text('Fit Height')),
                                  DropdownMenuItem(value: 'original', child: Text('Original')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    notifier.setPageFitOption(val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppDimensions.h20,
                ],

                // Conversion Summary & Actions
                if (state.selectedOutputFormat != null) ...[
                  const SectionHeader(
                    title: 'Conversion Summary',
                  ),
                  AppDimensions.h12,
                  _SummaryCard(
                    fileName: state.selectedFileName ?? 'File',
                    sourceFormat: state.selectedInputFormat?.displayName ?? 'Unknown',
                    targetFormat: state.selectedOutputFormat!.displayName,
                    sizeBytes: state.selectedFileSize ?? 0,
                  ),
                  AppDimensions.h32,

                  GradientButton(
                    onPressed: () {
                      notifier.startConversionFlow(() {
                        AppPopups.showSnackBar(
                          context: context,
                          message: 'File conversion completed successfully!',
                        );
                      });
                    },
                    child: const Text('Convert File Now'),
                  ),
                  AppDimensions.h12,

                  Row(
                    children: [
                      Expanded(
                        child: CustomOutlinedButton(
                          onPressed: () {
                            if (state.selectedFilePath != null) {
                              ShareOptionsSheet.show(
                                context,
                                filePath: state.selectedFilePath!,
                                fileName: state.selectedFileName,
                              );
                            }
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share_outlined, size: 18),
                              SizedBox(width: 6),
                              Text('Share Options'),
                            ],
                          ),
                        ),
                      ),
                      AppDimensions.w12,
                      Expanded(
                        child: CustomOutlinedButton(
                          onPressed: () {
                            if (state.selectedFilePath != null) {
                              OpenWithDialog.show(
                                context,
                                filePath: state.selectedFilePath!,
                              );
                            }
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.open_in_new_rounded, size: 18),
                              SizedBox(width: 6),
                              Text('Open With'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageRow(String title, bool isDone, bool isActive) {
    Color color;
    IconData icon;

    if (isActive) {
      color = AppColorScheme.primaryBlueStart;
      icon = Icons.hourglass_top_rounded;
    } else if (isDone) {
      color = AppColorScheme.success;
      icon = AppIcons.check;
    } else {
      color = AppColorScheme.disabled;
      icon = Icons.radio_button_off_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.s8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          AppDimensions.w12,
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              color: isActive ? AppColorScheme.primaryBlueStart : AppColorScheme.textPrimary,
              fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-components
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('FluxConvert ', style: AppTextStyles.headline.copyWith(fontSize: 22)),
            Text('⚡', style: AppTextStyles.headline.copyWith(fontSize: 22)),
          ],
        ),
        AppDimensions.h4,
        Text(
          'Fast, Secure & Offline File Converter',
          style: AppTextStyles.body.copyWith(color: AppColorScheme.textSecondary),
        ),
      ],
    );
}

class _ValidationErrorCard extends StatelessWidget {
  const _ValidationErrorCard({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColorScheme.danger.withAlpha(20),
        borderRadius: AppBorderRadius.radiusLg,
        border: Border.all(color: AppColorScheme.danger.withAlpha(80), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.error, color: AppColorScheme.danger, size: 20),
              AppDimensions.w8,
              Text(
                'Selection Failed',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColorScheme.danger,
                ),
              ),
            ],
          ),
          AppDimensions.h8,
          Text(
            errorMessage,
            style: AppTextStyles.caption.copyWith(color: AppColorScheme.textPrimary),
          ),
          AppDimensions.h12,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Try Another File'),
            ),
          ),
        ],
      ),
    );
}

class _FileSelectionCard extends StatelessWidget {
  const _FileSelectionCard({
    required this.onPickFile,
    required this.onBatchImportImages,
  });

  final VoidCallback onPickFile;
  final VoidCallback onBatchImportImages;

  @override
  Widget build(BuildContext context) => Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.radiusLg,
        side: BorderSide(color: AppColorScheme.border.withAlpha(100)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.s24,
          horizontal: AppDimensions.s16,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.s16),
              decoration: BoxDecoration(
                color: AppColorScheme.primaryBlueStart.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.upload,
                color: AppColorScheme.primaryBlueStart,
                size: 32,
              ),
            ),
            AppDimensions.h16,
            Text(
              'Select Files to Convert',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            AppDimensions.h8,
            Text(
              'Supports PDF, PNG, JPG, WEBP, DOCX, XLSX, TXT',
              style: AppTextStyles.caption.copyWith(color: AppColorScheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            AppDimensions.h20,
            Row(
              children: [
                Expanded(
                  child: CustomOutlinedButton(
                    onPressed: onPickFile,
                    child: const Text('Single File'),
                  ),
                ),
                AppDimensions.w12,
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.collections_rounded, size: 18),
                    label: const Text('Batch Import'),
                    onPressed: onBatchImportImages,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
}

class _SelectedFileCard extends StatelessWidget {
  const _SelectedFileCard({
    required this.fileName,
    required this.fileSize,
    required this.inputFormat,
    required this.importedBatchImages,
    required this.onRemove,
  });

  final String fileName;
  final int fileSize;
  final ConversionFormat? inputFormat;
  final List<ImportedImage> importedBatchImages;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => PrimaryCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.s12),
                  decoration: BoxDecoration(
                    color: AppColorScheme.primaryBlueStart.withAlpha(20),
                    borderRadius: AppBorderRadius.radiusMd,
                  ),
                  child: Icon(
                    inputFormat == ConversionFormat.pdf
                        ? AppIcons.document
                        : AppIcons.image,
                    color: AppColorScheme.primaryBlueStart,
                    size: 28,
                  ),
                ),
                AppDimensions.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppDimensions.h4,
                      Text(
                        '${FileSizeUtils.format(fileSize)} • ${inputFormat?.displayName ?? 'Format'}',
                        style: AppTextStyles.caption.copyWith(color: AppColorScheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                CustomIconButton(
                  icon: AppIcons.close,
                  onPressed: onRemove,
                ),
              ],
            ),

            // Batch Thumbnail Strip Preview
            if (importedBatchImages.isNotEmpty) ...[
              AppDimensions.h12,
              const Divider(),
              AppDimensions.h8,
              SizedBox(
                height: 64,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: importedBatchImages.length,
                  itemBuilder: (context, index) {
                    final item = importedBatchImages[index];
                    final hasThumb = item.thumbnailPath != null && File(item.thumbnailPath!).existsSync();

                    return Container(
                      width: 56,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasThumb
                            ? Image.file(
                                File(item.thumbnailPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => ColoredBox(
                                  color: Colors.purple.shade50,
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                                    ),
                                  ),
                                ),
                              )
                            : ColoredBox(
                                color: Colors.purple.shade50,
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
}

class _FormatSelectorGrid extends StatelessWidget {
  const _FormatSelectorGrid({
    required this.availableFormats,
    required this.selectedFormat,
    required this.onFormatSelected,
  });

  final List<ConversionFormat> availableFormats;
  final ConversionFormat? selectedFormat;
  final ValueChanged<ConversionFormat> onFormatSelected;

  @override
  Widget build(BuildContext context) => GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: AppDimensions.s12,
        mainAxisSpacing: AppDimensions.s12,
      ),
      itemCount: availableFormats.length,
      itemBuilder: (context, index) {
        final format = availableFormats[index];
        final isSelected = selectedFormat == format;

        return InkWell(
          onTap: () => onFormatSelected(format),
          borderRadius: AppBorderRadius.radiusMd,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColorScheme.primaryBlueStart.withAlpha(30)
                  : Theme.of(context).cardColor,
              borderRadius: AppBorderRadius.radiusMd,
              border: Border.all(
                color: isSelected
                    ? AppColorScheme.primaryBlueStart
                    : AppColorScheme.border.withAlpha(80),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Center(
              child: Text(
                format.displayName,
                style: AppTextStyles.body.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppColorScheme.primaryBlueStart
                      : AppColorScheme.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.fileName,
    required this.sourceFormat,
    required this.targetFormat,
    required this.sizeBytes,
  });

  final String fileName;
  final String sourceFormat;
  final String targetFormat;
  final int sizeBytes;

  @override
  Widget build(BuildContext context) => PrimaryCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.s16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Input File', style: AppTextStyles.caption),
                Text(fileName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Conversion Flow', style: AppTextStyles.caption),
                Text('$sourceFormat  ➔  $targetFormat', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Estimated Size', style: AppTextStyles.caption),
                Text(FileSizeUtils.format(sizeBytes), style: AppTextStyles.body),
              ],
            ),
          ],
        ),
      ),
    );
}
