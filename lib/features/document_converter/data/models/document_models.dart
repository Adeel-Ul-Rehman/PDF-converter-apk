/// ─────────────────────────────────────────────────────────────────────────────
/// Document Info & Result Models
///
/// Data models translating SQLite/JSON values into usable entity structures.
/// ─────────────────────────────────────────────────────────────────────────────
library;

/// Data model representing document metadata records in storage.
class DocumentInfoModel {
  const DocumentInfoModel({
    required this.filePath,
    required this.formatName,
    required this.sizeBytes,
    required this.modifiedTimeEpoch, this.pageCount,
    this.author,
  });

  factory DocumentInfoModel.fromJson(Map<String, dynamic> json) =>
      DocumentInfoModel(
        filePath: json['filePath'] as String,
        formatName: json['formatName'] as String,
        sizeBytes: json['sizeBytes'] as int,
        pageCount: json['pageCount'] as int?,
        author: json['author'] as String?,
        modifiedTimeEpoch: json['modifiedTimeEpoch'] as int,
      );

  final String filePath;
  final String formatName;
  final int sizeBytes;
  final int? pageCount;
  final String? author;
  final int modifiedTimeEpoch;

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'formatName': formatName,
        'sizeBytes': sizeBytes,
        'pageCount': pageCount,
        'author': author,
        'modifiedTimeEpoch': modifiedTimeEpoch,
      };
}

/// Data model representing resulting files metadata outputs.
class DocumentResultModel {
  const DocumentResultModel({
    required this.outputPath,
    required this.fileSizeBytes,
    required this.durationMs,
    required this.isSuccess,
    this.errorMsg,
  });

  factory DocumentResultModel.fromJson(Map<String, dynamic> json) =>
      DocumentResultModel(
        outputPath: json['outputPath'] as String,
        fileSizeBytes: json['fileSizeBytes'] as int,
        durationMs: json['durationMs'] as int,
        isSuccess: json['isSuccess'] as bool,
        errorMsg: json['errorMsg'] as String?,
      );

  final String outputPath;
  final int fileSizeBytes;
  final int durationMs;
  final bool isSuccess;
  final String? errorMsg;

  Map<String, dynamic> toJson() => {
        'outputPath': outputPath,
        'fileSizeBytes': fileSizeBytes,
        'durationMs': durationMs,
        'isSuccess': isSuccess,
        'errorMsg': errorMsg,
      };
}

/// Data model representing statistics records (pages, duration metrics).
class DocumentStatisticsModel {
  const DocumentStatisticsModel({
    required this.pagesConverted,
    required this.totalBytesProcessed,
    required this.averageConversionTimeMs,
  });

  factory DocumentStatisticsModel.fromJson(Map<String, dynamic> json) =>
      DocumentStatisticsModel(
        pagesConverted: json['pagesConverted'] as int,
        totalBytesProcessed: json['totalBytesProcessed'] as int,
        averageConversionTimeMs: json['averageConversionTimeMs'] as int,
      );

  final int pagesConverted;
  final int totalBytesProcessed;
  final int averageConversionTimeMs;

  Map<String, dynamic> toJson() => {
        'pagesConverted': pagesConverted,
        'totalBytesProcessed': totalBytesProcessed,
        'averageConversionTimeMs': averageConversionTimeMs,
      };
}
