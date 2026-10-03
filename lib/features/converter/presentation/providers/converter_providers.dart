import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/data/datasources/converter_local_datasource.dart';
import 'package:flux_convert/features/converter/data/repositories/converter_repository_impl.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/domain/repositories/converter_repository.dart';
import 'package:flux_convert/features/converter/domain/usecases/get_supported_formats_usecase.dart';
import 'package:flux_convert/features/notifications/presentation/notification_controller.dart';
import 'package:flux_convert/features/conversion/core/adapters/conversion_context.dart';
import 'package:flux_convert/features/conversion/core/adapters/conversion_settings.dart';
import 'package:flux_convert/features/conversion/core/adapters/format_converter_resolver.dart';
import 'package:flux_convert/features/conversion/core/engine/conversion_storage_manager.dart';
import 'package:flux_convert/features/history/domain/entities/conversion_history.dart';
import 'package:flux_convert/features/history/presentation/providers/history_providers.dart';
import 'package:flux_convert/features/conversion/core/adapters/format_converter_registry.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

/// Provides [ConverterLocalDataSource].
final converterLocalDataSourceProvider = Provider<ConverterLocalDataSource>(
  (ref) => const ConverterLocalDataSourceImpl(),
);

/// Provides [ConverterRepository].
final converterRepositoryProvider = Provider<ConverterRepository>(
  (ref) => ConverterRepositoryImpl(ref.watch(converterLocalDataSourceProvider)),
);

/// Provides [GetSupportedFormatsUseCase].
final getSupportedFormatsUseCaseProvider = Provider<GetSupportedFormatsUseCase>(
  (ref) => GetSupportedFormatsUseCase(ref.watch(converterRepositoryProvider)),
);

/// Stages of conversion progress for UI visualization.
enum ConversionPhase {
  preparing,
  reading,
  converting,
  writing,
  completed;

  String get displayName => switch (this) {
        ConversionPhase.preparing => 'Preparing file...',
        ConversionPhase.reading => 'Reading contents...',
        ConversionPhase.converting => 'Converting formats...',
        ConversionPhase.writing => 'Saving output...',
        ConversionPhase.completed => 'Completed successfully',
      };
}

/// State holder for the active converter page.
class ConverterState {
  const ConverterState({
    required this.supportedFormats,
    required this.selectedInputFormat,
    required this.selectedOutputFormat,
    required this.isLoading,
    this.selectedFilePath,
    this.selectedFileName,
    this.selectedFileSize,
    this.selectedFileLastModified,
    this.selectedFileCategory,
    this.possibleOutputFormats = const [],
    this.validationError,
    this.isConverting = false,
    this.conversionPhase,
    this.conversionProgress = 0.0,
    this.conversionStatusMessage,
    this.additionalSelectedFilePaths = const [],
    this.additionalSelectedFileNames = const [],
    this.marginOption = 'none',
    this.pageFitOption = 'fit',
    this.pdfPassword,
    this.pageSizeOption = 'A4',
    this.orientationOption = 'Auto',
    this.compressionOption = 'Low Compression',
    this.completedDestinationPath,
  });

  final List<ConversionFormat> supportedFormats;
  final ConversionFormat? selectedInputFormat;
  final ConversionFormat? selectedOutputFormat;
  final bool isLoading;

  // Selected File details
  final String? selectedFilePath;
  final String? selectedFileName;
  final int? selectedFileSize;
  final DateTime? selectedFileLastModified;
  final FileCategory? selectedFileCategory;

  // Filtered Output formats
  final List<ConversionFormat> possibleOutputFormats;
  final String? validationError;

  // Conversion progress state
  final bool isConverting;
  final ConversionPhase? conversionPhase;
  final double conversionProgress;
  final String? conversionStatusMessage;

  // Additional selected files for batch / merge
  final List<String> additionalSelectedFilePaths;
  final List<String> additionalSelectedFileNames;

  final String marginOption;
  final String pageFitOption;
  final String? pdfPassword;
  final String pageSizeOption;
  final String orientationOption;
  final String compressionOption;
  final String? completedDestinationPath;

  bool get hasValidSelection =>
      selectedFilePath != null &&
      validationError == null &&
      selectedOutputFormat != null;

  ConverterState copyWith({
    List<ConversionFormat>? supportedFormats,
    ConversionFormat? selectedInputFormat,
    ConversionFormat? selectedOutputFormat,
    bool? isLoading,
    String? selectedFilePath,
    String? selectedFileName,
    int? selectedFileSize,
    DateTime? selectedFileLastModified,
    FileCategory? selectedFileCategory,
    List<ConversionFormat>? possibleOutputFormats,
    String? validationError,
    bool? isConverting,
    ConversionPhase? conversionPhase,
    double? conversionProgress,
    String? conversionStatusMessage,
    List<String>? additionalSelectedFilePaths,
    List<String>? additionalSelectedFileNames,
    String? marginOption,
    String? pageFitOption,
    String? pdfPassword,
    String? pageSizeOption,
    String? orientationOption,
    String? compressionOption,
    String? completedDestinationPath,
    bool clearFile = false,
  }) => ConverterState(
      supportedFormats: supportedFormats ?? this.supportedFormats,
      selectedInputFormat: clearFile ? null : (selectedInputFormat ?? this.selectedInputFormat),
      selectedOutputFormat: clearFile ? null : (selectedOutputFormat ?? this.selectedOutputFormat),
      isLoading: isLoading ?? this.isLoading,
      selectedFilePath: clearFile ? null : (selectedFilePath ?? this.selectedFilePath),
      selectedFileName: clearFile ? null : (selectedFileName ?? this.selectedFileName),
      selectedFileSize: clearFile ? null : (selectedFileSize ?? this.selectedFileSize),
      selectedFileLastModified: clearFile ? null : (selectedFileLastModified ?? this.selectedFileLastModified),
      selectedFileCategory: clearFile ? null : (selectedFileCategory ?? this.selectedFileCategory),
      possibleOutputFormats: clearFile ? const [] : (possibleOutputFormats ?? this.possibleOutputFormats),
      validationError: clearFile ? null : (validationError ?? this.validationError),
      isConverting: isConverting ?? this.isConverting,
      conversionPhase: isConverting == false ? null : (conversionPhase ?? this.conversionPhase),
      conversionProgress: isConverting == false ? 0.0 : (conversionProgress ?? this.conversionProgress),
      conversionStatusMessage: isConverting == false ? null : (conversionStatusMessage ?? this.conversionStatusMessage),
      additionalSelectedFilePaths: clearFile ? const [] : (additionalSelectedFilePaths ?? this.additionalSelectedFilePaths),
      additionalSelectedFileNames: clearFile ? const [] : (additionalSelectedFileNames ?? this.additionalSelectedFileNames),
      marginOption: clearFile ? 'none' : (marginOption ?? this.marginOption),
      pageFitOption: clearFile ? 'fit' : (pageFitOption ?? this.pageFitOption),
      pdfPassword: clearFile ? null : (pdfPassword ?? this.pdfPassword),
      pageSizeOption: clearFile ? 'A4' : (pageSizeOption ?? this.pageSizeOption),
      orientationOption: clearFile ? 'Auto' : (orientationOption ?? this.orientationOption),
      compressionOption: clearFile ? 'Low Compression' : (compressionOption ?? this.compressionOption),
      completedDestinationPath: clearFile ? null : (completedDestinationPath ?? this.completedDestinationPath),
    );
}

/// Controller to drive File selection, Validation, and Conversion progress flow.
class ConverterNotifier extends StateNotifier<ConverterState> {
  ConverterNotifier(this._getSupportedFormatsUseCase, this._ref)
      : _notificationController = NotificationController(),
        super(const ConverterState(
          supportedFormats: [],
          selectedInputFormat: null,
          selectedOutputFormat: null,
          isLoading: false,
        )) {
    _notificationController.requestPermission();
    unawaited(loadSupportedFormats());
  }

  final GetSupportedFormatsUseCase _getSupportedFormatsUseCase;
  final NotificationController _notificationController;
  final Ref _ref;
  Timer? _conversionTimer;

  Future<void> loadSupportedFormats() async {
    state = state.copyWith(isLoading: true);
    final result = await _getSupportedFormatsUseCase();
    if (result.isSuccess) {
      state = state.copyWith(
        supportedFormats: result.value,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Triggers the system file picker and validates files.
  Future<void> selectFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
    bool allowMultiple = false,
  }) async {
    try {
      final pickerResult = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : type,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );

      if (pickerResult == null || pickerResult.files.isEmpty) {
        // User cancelled selection
        return;
      }

      final files = pickerResult.files;
      final firstFile = files.first;
      final path = firstFile.path;
      if (path == null) {
        state = state.copyWith(validationError: 'File path unavailable.');
        return;
      }

      final ioFile = File(path);
      if (!ioFile.existsSync()) {
        state = state.copyWith(validationError: 'Selected file could not be found.');
        return;
      }

      // ── 1. Check extension compatibility ──────────────────────────────────
      final extension = firstFile.extension?.toLowerCase() ?? path.split('.').last.toLowerCase();
      if (!AppFileConstants.allSupportedExtensions.contains(extension)) {
        state = state.copyWith(
          validationError: 'Format not supported. Please select another file.',
        );
        return;
      }

      // Sum up sizes and build list
      var totalSize = 0;
      final allPaths = <String>[];
      final allNames = <String>[];

      for (final f in files) {
        if (f.path != null) {
          final fFile = File(f.path!);
          if (fFile.existsSync()) {
            allPaths.add(f.path!);
            allNames.add(f.name);
            totalSize += f.size;
          }
        }
      }

      if (allPaths.isEmpty) {
        state = state.copyWith(validationError: 'No valid files selected.');
        return;
      }

      // ── 2. Check maximum size limit (100 MB) ──────────────────────────────
      if (totalSize > AppFileConstants.maxFileSizeBytes) {
        state = state.copyWith(
          validationError: 'Total size exceeds the limit of 100 MB.',
        );
        return;
      }

      // ── 3. Check readability ──────────────────────────────────────────────
      try {
        await ioFile.open();
      } catch (_) {
        state = state.copyWith(
          validationError: 'Selected file is corrupted or unreadable.',
        );
        return;
      }

      // File is valid, populate states
      final category = FileTypeDetector.detectCategory(allPaths.first);
      final inputFormat = _mapExtensionToFormat(extension);
      final displayName = allPaths.length > 1
          ? '${firstFile.name} and ${allPaths.length - 1} other files'
          : firstFile.name;

      state = state.copyWith(
        selectedFilePath: allPaths.first,
        selectedFileName: displayName,
        selectedFileSize: totalSize,
        selectedFileLastModified: ioFile.lastModifiedSync(),
        selectedFileCategory: category,
        selectedInputFormat: inputFormat,
        possibleOutputFormats: _filterOutputFormats(category, inputFormat),
        additionalSelectedFilePaths: allPaths,
        additionalSelectedFileNames: allNames,
      );
    } catch (e, stack) {
      AppLogger.error('File Picker encountered an error', e, stack);
      state = state.copyWith(
        validationError: 'An unexpected error occurred while picking file.',
      );
    }
  }

  /// Sets the selected file programmatically.
  void setFile(
    String path,
    String name,
    int size,
    FileCategory category,
    ConversionFormat inputFormat, {
    List<String> additionalPaths = const [],
    List<String> additionalNames = const [],
  }) {
    state = ConverterState(
      supportedFormats: state.supportedFormats,
      selectedInputFormat: inputFormat,
      selectedOutputFormat: null,
      isLoading: false,
      selectedFilePath: path,
      selectedFileName: name,
      selectedFileSize: size,
      selectedFileLastModified: File(path).existsSync() ? File(path).lastModifiedSync() : DateTime.now(),
      selectedFileCategory: category,
      possibleOutputFormats: _filterOutputFormats(category, inputFormat),
      additionalSelectedFilePaths: additionalPaths.isNotEmpty ? additionalPaths : [path],
      additionalSelectedFileNames: additionalNames.isNotEmpty ? additionalNames : [name],
    );
  }

  /// Programmatically sets the active file path for annotation tools.
  void setFilePathDirectly(String path) {
    final file = File(path);
    final name = path.split('/').last.split(r'\').last;
    final size = file.existsSync() ? file.lengthSync() : 0;
    final category = FileTypeDetector.detectCategory(path);
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final inputFormat = _mapExtensionToFormat(ext) ?? ConversionFormat.pdf;
    setFile(path, name, size, category, inputFormat);
  }

  void setMarginOption(String margin) {
    state = state.copyWith(marginOption: margin);
  }

  void setPageFitOption(String fit) {
    state = state.copyWith(pageFitOption: fit);
  }

  void setPdfPassword(String? password) {
    state = state.copyWith(pdfPassword: password);
  }

  void setPageSizeOption(String size) {
    state = state.copyWith(pageSizeOption: size);
  }

  void setOrientationOption(String orientation) {
    state = state.copyWith(orientationOption: orientation);
  }

  void setCompressionOption(String compression) {
    state = state.copyWith(compressionOption: compression);
  }

  void setCompletedDestinationPath(String? path) {
    state = state.copyWith(completedDestinationPath: path);
  }

  /// Cancels and clears the selected file.
  void clearSelection() {
    _conversionTimer?.cancel();
    state = state.copyWith(clearFile: true, isConverting: false);
  }

  /// Selects the target format from filtered choices.
  void selectOutputFormat(ConversionFormat format) {
    state = state.copyWith(selectedOutputFormat: format);
  }

  /// Triggers a real conversion pipeline run.
  Future<void> startConversionFlow(void Function() onComplete) async {
    if (!state.hasValidSelection || state.isConverting) return;

    state = state.copyWith(
      isConverting: true,
      conversionPhase: ConversionPhase.preparing,
      conversionProgress: 0.0,
    );

    try {
      final inputPath = state.selectedFilePath!;
      final sourceName = state.selectedFileName!;
      final baseName = sourceName.contains('.')
          ? sourceName.substring(0, sourceName.lastIndexOf('.'))
          : sourceName;
      final sourceExt = state.selectedInputFormat!.name.toLowerCase();
      final targetExt = state.selectedOutputFormat!.name.toLowerCase();

      // 1. Allocate output storage path
      final destPathResult = await ConversionStorageManager.getDestinationPath(
        baseName,
        targetExt,
      );

      if (destPathResult.isFailure) {
        state = state.copyWith(
          isConverting: false,
          validationError: destPathResult.failure.message,
        );
        return;
      }

      final destPath = destPathResult.value;

      // 2. Resolve converter adapter
      final resolverResult = FormatConverterResolver.resolve(sourceExt, targetExt);
      if (resolverResult.isFailure) {
        state = state.copyWith(
          isConverting: false,
          validationError: resolverResult.failure.message,
        );
        return;
      }

      final converter = resolverResult.value;
      final tempDir = await getTemporaryDirectory();

      final context = ConversionContext(
        inputFile: File(inputPath),
        outputPath: destPath,
        tempDirectory: tempDir,
        settings: ConversionSettings(
          customParameters: {
            'additionalFiles': state.additionalSelectedFilePaths,
            'margin': state.marginOption,
            'pageFit': state.pageFitOption,
            'pdfPassword': state.pdfPassword,
            'pageSize': state.pageSizeOption,
            'orientation': state.orientationOption,
            'compression': state.compressionOption,
          },
        ),
      );

      state = state.copyWith(
        conversionPhase: ConversionPhase.reading,
        conversionProgress: 0.15,
        conversionStatusMessage: 'Reading source files...',
      );
      _notificationController.updateProgress(15);

      // 3. Execute conversion
      final totalImages = 1 + state.additionalSelectedFilePaths.length;
      final isMultiPage = state.selectedFileCategory == FileCategory.image || totalImages > 1;

      final conversionResult = await converter.convert(context, (progress) {
        String msg;
        if (isMultiPage) {
          final currentPage = (progress * totalImages).round().clamp(1, totalImages);
          msg = 'Processing page $currentPage of $totalImages...';
        } else {
          msg = 'Converting document formats...';
        }

        state = state.copyWith(
          conversionPhase: ConversionPhase.converting,
          conversionProgress: 0.15 + (progress * 0.70),
          conversionStatusMessage: msg,
        );
        _notificationController.updateProgress((state.conversionProgress * 100).toInt());
      });

      state = state.copyWith(
        conversionPhase: ConversionPhase.writing,
        conversionProgress: 0.85,
        conversionStatusMessage: 'Saving compiled document...',
      );

      if (conversionResult.isSuccess) {
        final res = conversionResult.value;
        final conversionId = const Uuid().v4();

        // 4. Save to history
        final record = ConversionHistory(
          id: const Uuid().v4(),
          conversionId: conversionId,
          sourceFileName: sourceName,
          sourceFilePath: inputPath,
          destinationFileName: res.outputName,
          destinationFilePath: res.destinationPath,
          sourceFormat: sourceExt.toUpperCase(),
          destinationFormat: targetExt.toUpperCase(),
          originalFileSize: state.selectedFileSize!,
          convertedFileSize: res.fileSizeBytes,
          conversionDuration: res.duration,
          conversionStatus: 'completed',
          createdDate: DateTime.now(),
          completedDate: DateTime.now(),
        );

        await _ref.read(historyRepositoryProvider).saveConversion(record);
        // Reload history lists on dashboard
        await _ref.read(richHistoryNotifierProvider.notifier).loadAllHistory();
        await _ref.read(richHistoryNotifierProvider.notifier).refreshStats();

        state = state.copyWith(
          conversionPhase: ConversionPhase.completed,
          conversionProgress: 1.0,
          completedDestinationPath: res.destinationPath,
        );
        _notificationController.updateProgress(100);

        await _notificationController.showSuccess(
          title: 'Conversion Successful',
          body: '${res.outputName} saved to storage.',
        );
        state = state.copyWith(isConverting: false);
        onComplete();
      } else {
        await _notificationController.showFailure(
          title: 'Conversion Failed',
          body: conversionResult.failure.message,
        );
        state = state.copyWith(
          isConverting: false,
          validationError: conversionResult.failure.message,
        );
      }
    } catch (e) {
      await _notificationController.showFailure(
        title: 'Conversion Failed',
        body: e.toString(),
      );
      state = state.copyWith(
        isConverting: false,
        validationError: 'Conversion failed: $e',
      );
    }
  }

  // Helper mappings & filterings
  ConversionFormat? _mapExtensionToFormat(String ext) => ConversionFormat.values.firstWhere(
      (f) => f.name.toLowerCase() == ext.toLowerCase(),
      orElse: () => ConversionFormat.pdf,
    );

  List<ConversionFormat> _filterOutputFormats(FileCategory category, ConversionFormat? input) {
    if (input == null) return [];
    return ConversionFormat.values.where((format) {
      if (format == input) return false;
      final sourceExt = input.name.toLowerCase();
      final targetExt = format.name.toLowerCase();
      final converters = FormatConverterRegistry.findByMapping(sourceExt, targetExt);
      return converters.isNotEmpty;
    }).toList();
  }

  @override
  void dispose() {
    _conversionTimer?.cancel();
    super.dispose();
  }
}

/// Provides the [ConverterNotifier].
final converterNotifierProvider =
    StateNotifierProvider<ConverterNotifier, ConverterState>(
  (ref) => ConverterNotifier(ref.watch(getSupportedFormatsUseCaseProvider), ref),
);
