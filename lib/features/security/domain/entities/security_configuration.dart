import 'package:equatable/equatable.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SecurityConfiguration — Configurable security policies for the application.
///
/// Encapsulates all security parameters like file size limits, allowed extensions,
/// path permissions, and task limits.
/// ─────────────────────────────────────────────────────────────────────────────
class SecurityConfiguration extends Equatable {
  const SecurityConfiguration({
    this.maxFileSizeBytes = 100 * 1024 * 1024, // 100 MB
    this.allowedExtensions = const {
      'pdf', 'docx', 'doc', 'txt', 'rtf', 'html', 'png', 'jpg', 'jpeg', 'webp',
      'bmp', 'gif', 'tiff', 'svg', 'heic',
    },
    this.allowedDirectories = const {}, // Will be populated dynamically at runtime
    this.temporaryLifetime = const Duration(hours: 1),
    this.cacheLifetime = const Duration(days: 7),
    this.maxConcurrentTasks = 3,
  });

  /// Maximum allowed file size in bytes.
  final int maxFileSizeBytes;

  /// Lowercase allowed file extensions without leading dot.
  final Set<String> allowedExtensions;

  /// Absolute paths of application-managed folders we are permitted to access.
  final Set<String> allowedDirectories;

  /// Lifetime before temporary files are purged.
  final Duration temporaryLifetime;

  /// Lifetime before cache items are deleted.
  final Duration cacheLifetime;

  /// Maximum concurrent conversion processes.
  final int maxConcurrentTasks;

  /// Creates a copy of this configuration with custom properties.
  SecurityConfiguration copyWith({
    int? maxFileSizeBytes,
    Set<String>? allowedExtensions,
    Set<String>? allowedDirectories,
    Duration? temporaryLifetime,
    Duration? cacheLifetime,
    int? maxConcurrentTasks,
  }) =>
      SecurityConfiguration(
        maxFileSizeBytes: maxFileSizeBytes ?? this.maxFileSizeBytes,
        allowedExtensions: allowedExtensions ?? this.allowedExtensions,
        allowedDirectories: allowedDirectories ?? this.allowedDirectories,
        temporaryLifetime: temporaryLifetime ?? this.temporaryLifetime,
        cacheLifetime: cacheLifetime ?? this.cacheLifetime,
        maxConcurrentTasks: maxConcurrentTasks ?? this.maxConcurrentTasks,
      );

  @override
  List<Object?> get props => [
        maxFileSizeBytes,
        allowedExtensions,
        allowedDirectories,
        temporaryLifetime,
        cacheLifetime,
        maxConcurrentTasks,
      ];
}
