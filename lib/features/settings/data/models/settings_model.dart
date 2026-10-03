import 'package:flux_convert/features/settings/domain/entities/settings_entity.dart';

/// Persistence model for settings stored in SharedPreferences.
class SettingsModel {
  const SettingsModel({
    required this.themeMode,
    required this.language,
    required this.outputFolder,
    required this.defaultImageQuality,
    required this.compressionLevel,
    required this.defaultPdfQuality,
    required this.generateUniqueFilename,
    required this.overwriteExistingFiles,
    required this.deleteTempFilesAutomatically,
    required this.autoCleanupCache,
    required this.enableAnimations,
    required this.enableHapticFeedback,
    required this.enableNotifications,
    required this.developerMode,
    required this.enableDebugLogs,
    required this.futureAiIntegrationEnabled,
    required this.futureOcrEnabled,
    required this.futureCloudSyncEnabled,
    required this.futureBackupEnabled,
    required this.saveToGallery,
    required this.clearTempOnExit,
    required this.reduceMotion,
    required this.largeText,
    required this.keepMetadata,
    required this.defaultOutputFormat,
    required this.showConversionNotifications,
    required this.defaultSortOrder,
    required this.defaultHistoryFilter,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) => SettingsModel(
    themeMode: json['themeMode'] as String? ?? 'light',
    language: json['language'] as String? ?? 'en',
    outputFolder: json['outputFolder'] as String? ?? '',
    defaultImageQuality: json['defaultImageQuality'] as int? ?? 85,
    compressionLevel: json['compressionLevel'] as int? ?? 6,
    defaultPdfQuality: json['defaultPdfQuality'] as int? ?? 90,
    generateUniqueFilename: json['generateUniqueFilename'] as bool? ?? true,
    overwriteExistingFiles: json['overwriteExistingFiles'] as bool? ?? false,
    deleteTempFilesAutomatically:
        json['deleteTempFilesAutomatically'] as bool? ?? true,
    autoCleanupCache: json['autoCleanupCache'] as bool? ?? true,
    enableAnimations: json['enableAnimations'] as bool? ?? true,
    enableHapticFeedback: json['enableHapticFeedback'] as bool? ?? true,
    enableNotifications: json['enableNotifications'] as bool? ?? true,
    developerMode: json['developerMode'] as bool? ?? false,
    enableDebugLogs: json['enableDebugLogs'] as bool? ?? false,
    futureAiIntegrationEnabled:
        json['futureAiIntegrationEnabled'] as bool? ?? false,
    futureOcrEnabled: json['futureOcrEnabled'] as bool? ?? false,
    futureCloudSyncEnabled: json['futureCloudSyncEnabled'] as bool? ?? false,
    futureBackupEnabled: json['futureBackupEnabled'] as bool? ?? false,
    saveToGallery: json['saveToGallery'] as bool? ?? false,
    clearTempOnExit: json['clearTempOnExit'] as bool? ?? true,
    reduceMotion: json['reduceMotion'] as bool? ?? false,
    largeText: json['largeText'] as bool? ?? false,
    keepMetadata: json['keepMetadata'] as bool? ?? true,
    defaultOutputFormat: json['defaultOutputFormat'] as String? ?? 'pdf',
    showConversionNotifications:
        json['showConversionNotifications'] as bool? ?? true,
    defaultSortOrder: json['defaultSortOrder'] as String? ?? 'newest',
    defaultHistoryFilter: json['defaultHistoryFilter'] as String? ?? 'all',
  );

  factory SettingsModel.fromDomain(SettingsEntity entity) => SettingsModel(
    themeMode: entity.themeMode,
    language: entity.language,
    outputFolder: entity.outputFolder,
    defaultImageQuality: entity.defaultImageQuality,
    compressionLevel: entity.compressionLevel,
    defaultPdfQuality: entity.defaultPdfQuality,
    generateUniqueFilename: entity.generateUniqueFilename,
    overwriteExistingFiles: entity.overwriteExistingFiles,
    deleteTempFilesAutomatically: entity.deleteTempFilesAutomatically,
    autoCleanupCache: entity.autoCleanupCache,
    enableAnimations: entity.enableAnimations,
    enableHapticFeedback: entity.enableHapticFeedback,
    enableNotifications: entity.enableNotifications,
    developerMode: entity.developerMode,
    enableDebugLogs: entity.enableDebugLogs,
    futureAiIntegrationEnabled: entity.futureAiIntegrationEnabled,
    futureOcrEnabled: entity.futureOcrEnabled,
    futureCloudSyncEnabled: entity.futureCloudSyncEnabled,
    futureBackupEnabled: entity.futureBackupEnabled,
    saveToGallery: entity.saveToGallery,
    clearTempOnExit: entity.clearTempOnExit,
    reduceMotion: entity.reduceMotion,
    largeText: entity.largeText,
    keepMetadata: entity.keepMetadata,
    defaultOutputFormat: entity.defaultOutputFormat,
    showConversionNotifications: entity.showConversionNotifications,
    defaultSortOrder: entity.defaultSortOrder,
    defaultHistoryFilter: entity.defaultHistoryFilter,
  );

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
  final bool saveToGallery;
  final bool clearTempOnExit;
  final bool reduceMotion;
  final bool largeText;
  final bool keepMetadata;
  final String defaultOutputFormat;
  final bool showConversionNotifications;
  final String defaultSortOrder;
  final String defaultHistoryFilter;

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode,
    'language': language,
    'outputFolder': outputFolder,
    'defaultImageQuality': defaultImageQuality,
    'compressionLevel': compressionLevel,
    'defaultPdfQuality': defaultPdfQuality,
    'generateUniqueFilename': generateUniqueFilename,
    'overwriteExistingFiles': overwriteExistingFiles,
    'deleteTempFilesAutomatically': deleteTempFilesAutomatically,
    'autoCleanupCache': autoCleanupCache,
    'enableAnimations': enableAnimations,
    'enableHapticFeedback': enableHapticFeedback,
    'enableNotifications': enableNotifications,
    'developerMode': developerMode,
    'enableDebugLogs': enableDebugLogs,
    'futureAiIntegrationEnabled': futureAiIntegrationEnabled,
    'futureOcrEnabled': futureOcrEnabled,
    'futureCloudSyncEnabled': futureCloudSyncEnabled,
    'futureBackupEnabled': futureBackupEnabled,
    'saveToGallery': saveToGallery,
    'clearTempOnExit': clearTempOnExit,
    'reduceMotion': reduceMotion,
    'largeText': largeText,
    'keepMetadata': keepMetadata,
    'defaultOutputFormat': defaultOutputFormat,
    'showConversionNotifications': showConversionNotifications,
    'defaultSortOrder': defaultSortOrder,
    'defaultHistoryFilter': defaultHistoryFilter,
  };

  SettingsEntity toDomain() => SettingsEntity(
    themeMode: themeMode,
    language: language,
    outputFolder: outputFolder,
    defaultImageQuality: defaultImageQuality,
    compressionLevel: compressionLevel,
    defaultPdfQuality: defaultPdfQuality,
    generateUniqueFilename: generateUniqueFilename,
    overwriteExistingFiles: overwriteExistingFiles,
    deleteTempFilesAutomatically: deleteTempFilesAutomatically,
    autoCleanupCache: autoCleanupCache,
    enableAnimations: enableAnimations,
    enableHapticFeedback: enableHapticFeedback,
    enableNotifications: enableNotifications,
    developerMode: developerMode,
    enableDebugLogs: enableDebugLogs,
    futureAiIntegrationEnabled: futureAiIntegrationEnabled,
    futureOcrEnabled: futureOcrEnabled,
    futureCloudSyncEnabled: futureCloudSyncEnabled,
    futureBackupEnabled: futureBackupEnabled,
    saveToGallery: saveToGallery,
    clearTempOnExit: clearTempOnExit,
    reduceMotion: reduceMotion,
    largeText: largeText,
    keepMetadata: keepMetadata,
    defaultOutputFormat: defaultOutputFormat,
    showConversionNotifications: showConversionNotifications,
    defaultSortOrder: defaultSortOrder,
    defaultHistoryFilter: defaultHistoryFilter,
  );
}
