import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_convert/features/image_engine/data/repositories/image_conversion_repository_impl.dart';
import 'package:flux_convert/features/image_engine/domain/entities/image_task.dart';
import 'package:flux_convert/features/image_engine/domain/repositories/image_conversion_repository.dart';
import 'package:flux_convert/features/image_engine/services/image_conversion_service.dart';

/// Exposes the [ImageConversionRepository].
final imageConversionRepositoryProvider = Provider<ImageConversionRepository>(
  (ref) => ImageConversionRepositoryImpl(),
);

/// Exposes the [ImageConversionService].
final imageConversionServiceProvider = Provider<ImageConversionService>(
  (ref) => ImageConversionService(ref.watch(imageConversionRepositoryProvider)),
);

/// Operational states of the Image Engine.
enum ImageEngineStatus {
  idle,
  validating,
  preparing,
  processing,
  writing,
  completed,
  failed,
  cancelled;
}

/// State details holder.
class ImageEngineState {
  const ImageEngineState({
    required this.status,
    this.progress = 0.0,
    this.outputPath,
    this.errorMessage,
  });

  final ImageEngineStatus status;
  final double progress;
  final String? outputPath;
  final String? errorMessage;

  ImageEngineState copyWith({
    ImageEngineStatus? status,
    double? progress,
    String? outputPath,
    String? errorMessage,
  }) => ImageEngineState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
}

/// StateNotifier controlling image formatting operations.
class ImageEngineNotifier extends StateNotifier<ImageEngineState> {
  ImageEngineNotifier(this._service) : super(const ImageEngineState(status: ImageEngineStatus.idle));

  final ImageConversionService _service;

  /// Executes formatting task.
  Future<void> runImageTask(ImageTask task) async {
    // 1. Validation phase
    state = state.copyWith(status: ImageEngineStatus.validating);
    final validation = await _service.generateThumbnail(
      filePath: task.sourcePath,
      cacheDir: task.outputPath.substring(0, task.outputPath.lastIndexOf('/')),
    );

    if (validation.isFailure) {
      state = state.copyWith(
        status: ImageEngineStatus.failed,
        errorMessage: validation.failure.message,
      );
      return;
    }

    // 2. Preparing phase
    state = state.copyWith(status: ImageEngineStatus.preparing);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // 3. Processing phase
    state = state.copyWith(status: ImageEngineStatus.processing, progress: 0.0);

    final result = await _service.processImage(
      task: task,
      onProgress: (p) {
        state = state.copyWith(
          status: p >= 0.9 ? ImageEngineStatus.writing : ImageEngineStatus.processing,
          progress: p,
        );
      },
    );

    if (result.isSuccess) {
      state = state.copyWith(
        status: ImageEngineStatus.completed,
        outputPath: result.value,
      );
    } else {
      state = state.copyWith(
        status: ImageEngineStatus.failed,
        errorMessage: result.failure.message,
      );
    }
  }

  /// Cancels an active task.
  Future<void> cancelActiveTask(String taskId) async {
    await _service.cancelActiveTask(taskId);
    state = const ImageEngineState(status: ImageEngineStatus.cancelled);
  }

  /// Resets state.
  void reset() {
    state = const ImageEngineState(status: ImageEngineStatus.idle);
  }
}

/// Provides [ImageEngineNotifier] state notifier.
final imageEngineNotifierProvider =
    StateNotifierProvider<ImageEngineNotifier, ImageEngineState>((ref) => ImageEngineNotifier(ref.watch(imageConversionServiceProvider)));
