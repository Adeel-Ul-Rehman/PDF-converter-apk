import 'package:equatable/equatable.dart';

/// Domain entity for the consolidated settings model used throughout the app.
class SettingsEntity extends Equatable {
  const SettingsEntity({
    this.themeMode = 'light',
    this.language = 'en',
    this.outputFolder = '',
    this.defaultImageQuality = 85,
    this.compressionLevel = 6,
    this.defaultPdfQuality = 90,
    this.generateUniqueFilename = true,
    this.overwriteExistingFiles = false,
    this.deleteTempFilesAutomatically = true,
    this.autoCleanupCache = true,
    this.enableAnimations = true,
    this.enableHapticFeedback = true,
    this.enableNotifications = true,
    this.developerMode = false,
    this.enableDebugLogs = false,
    this.futureAiIntegrationEnabled = false,
    this.futureOcrEnabled = false,
    this.futureCloudSyncEnabled = false,
    this.futureBackupEnabled = false,
    this.saveToGallery = false,
    this.clearTempOnExit = true,
    this.reduceMotion = false,
    this.largeText = false,
    this.keepMetadata = true,
    this.defaultOutputFormat = 'pdf',
    this.showConversionNotifications = true,
    this.defaultSortOrder = 'newest',
    this.defaultHistoryFilter = 'all',
  });

  final String themeMode;
  final String language;
  final String outputFolder;
  final int defaultImageQuality;
  final int compressionLevel;
  final int defaultPdfQuality;
  final bool generateUniqueFilename;
  final bool overwriteExistingFiles;
  final bool deleteTempFilesAutomatically;
  final bool autoCleanupCache;
  final bool enableAnimations;
  final bool enableHapticFeedback;
  final bool enableNotifications;
  final bool developerMode;
  final bool enableDebugLogs;
  final bool futureAiIntegrationEnabled;
  final bool futureOcrEnabled;
  final bool futureCloudSyncEnabled;
  final bool futureBackupEnabled;

  // Compatibility fields retained for the existing storage/history workflow.
  final bool saveToGallery;
  final bool clearTempOnExit;
  final bool reduceMotion;
  final bool largeText;
  final bool keepMetadata;
  final String defaultOutputFormat;
  final bool showConversionNotifications;
  final String defaultSortOrder;
  final String defaultHistoryFilter;

  SettingsEntity copyWith({
    String? themeMode,
    String? language,
    String? outputFolder,
    int? defaultImageQuality,
    int? compressionLevel,
    int? defaultPdfQuality,
    bool? generateUniqueFilename,
    bool? overwriteExistingFiles,
    bool? deleteTempFilesAutomatically,
    bool? autoCleanupCache,
    bool? enableAnimations,
    bool? enableHapticFeedback,
    bool? enableNotifications,
    bool? developerMode,
    bool? enableDebugLogs,
    bool? futureAiIntegrationEnabled,
    bool? futureOcrEnabled,
    bool? futureCloudSyncEnabled,
    bool? futureBackupEnabled,
    bool? saveToGallery,
    bool? clearTempOnExit,
    bool? reduceMotion,
    bool? largeText,
    bool? keepMetadata,
    String? defaultOutputFormat,
    bool? showConversionNotifications,
    String? defaultSortOrder,
    String? defaultHistoryFilter,
  }) => SettingsEntity(
    themeMode: themeMode ?? this.themeMode,
    language: language ?? this.language,
    outputFolder: outputFolder ?? this.outputFolder,
    defaultImageQuality: defaultImageQuality ?? this.defaultImageQuality,
    compressionLevel: compressionLevel ?? this.compressionLevel,
    defaultPdfQuality: defaultPdfQuality ?? this.defaultPdfQuality,
    generateUniqueFilename:
        generateUniqueFilename ?? this.generateUniqueFilename,
    overwriteExistingFiles:
        overwriteExistingFiles ?? this.overwriteExistingFiles,
    deleteTempFilesAutomatically:
        deleteTempFilesAutomatically ?? this.deleteTempFilesAutomatically,
    autoCleanupCache: autoCleanupCache ?? this.autoCleanupCache,
    enableAnimations: enableAnimations ?? this.enableAnimations,
    enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
    enableNotifications: enableNotifications ?? this.enableNotifications,
    developerMode: developerMode ?? this.developerMode,
    enableDebugLogs: enableDebugLogs ?? this.enableDebugLogs,
    futureAiIntegrationEnabled:
        futureAiIntegrationEnabled ?? this.futureAiIntegrationEnabled,
    futureOcrEnabled: futureOcrEnabled ?? this.futureOcrEnabled,
    futureCloudSyncEnabled:
        futureCloudSyncEnabled ?? this.futureCloudSyncEnabled,
    futureBackupEnabled: futureBackupEnabled ?? this.futureBackupEnabled,
    saveToGallery: saveToGallery ?? this.saveToGallery,
    clearTempOnExit: clearTempOnExit ?? this.clearTempOnExit,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    largeText: largeText ?? this.largeText,
    keepMetadata: keepMetadata ?? this.keepMetadata,
    defaultOutputFormat: defaultOutputFormat ?? this.defaultOutputFormat,
    showConversionNotifications:
        showConversionNotifications ?? this.showConversionNotifications,
    defaultSortOrder: defaultSortOrder ?? this.defaultSortOrder,
    defaultHistoryFilter: defaultHistoryFilter ?? this.defaultHistoryFilter,
  );

  @override
  List<Object?> get props => [
    themeMode,
    language,
    outputFolder,
    defaultImageQuality,
    compressionLevel,
    defaultPdfQuality,
    generateUniqueFilename,
    overwriteExistingFiles,
    deleteTempFilesAutomatically,
    autoCleanupCache,
    enableAnimations,
    enableHapticFeedback,
    enableNotifications,
    developerMode,
    enableDebugLogs,
    futureAiIntegrationEnabled,
    futureOcrEnabled,
    futureCloudSyncEnabled,
    futureBackupEnabled,
    saveToGallery,
    clearTempOnExit,
    reduceMotion,
    largeText,
    keepMetadata,
    defaultOutputFormat,
    showConversionNotifications,
    defaultSortOrder,
    defaultHistoryFilter,
  ];
}

/// Canonical defaults for the settings entity.
abstract final class SettingsEntityDefaults {
  static const SettingsEntity instance = SettingsEntity();
}
