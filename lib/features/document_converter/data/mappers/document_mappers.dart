import 'package:flux_convert/features/document_converter/domain/entities/document_metadata.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_response.dart';
import 'package:flux_convert/features/document_converter/data/models/document_models.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentMappers
///
/// Converts Data Models to domain entities and vice-versa.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class DocumentMappers {
  /// Converts [DocumentInfoModel] to [DocumentMetadata] entity.
  static DocumentMetadata toMetadata(DocumentInfoModel model) {
    final fileName = model.filePath.split('/').last.split(r'\').last;
    final ext = fileName.split('.').last.toLowerCase();

    return DocumentMetadata(
      fileName: fileName,
      extension: ext,
      sizeBytes: model.sizeBytes,
      pageCount: model.pageCount,
      author: model.author,
      createdDate: DateTime.fromMillisecondsSinceEpoch(model.modifiedTimeEpoch),
      modifiedDate: DateTime.fromMillisecondsSinceEpoch(model.modifiedTimeEpoch),
    );
  }

  /// Converts [DocumentMetadata] to [DocumentInfoModel].
  static DocumentInfoModel fromMetadata(
    String filePath,
    DocumentMetadata metadata,
  ) => DocumentInfoModel(
      filePath: filePath,
      formatName: metadata.extension,
      sizeBytes: metadata.sizeBytes,
      pageCount: metadata.pageCount,
      author: metadata.author,
      modifiedTimeEpoch: metadata.modifiedDate.millisecondsSinceEpoch,
    );

  /// Converts [DocumentResultModel] to [DocumentConversionResponse] entity.
  static DocumentConversionResponse toResponse(DocumentResultModel model) => DocumentConversionResponse(
      outputPath: model.outputPath,
      fileSizeBytes: model.fileSizeBytes,
      duration: Duration(milliseconds: model.durationMs),
    );

  /// Converts [DocumentConversionResponse] to [DocumentResultModel].
  static DocumentResultModel fromResponse(
    DocumentConversionResponse response,
    bool isSuccess, [
    String? errorMsg,
  ]) => DocumentResultModel(
      outputPath: response.outputPath,
      fileSizeBytes: response.fileSizeBytes,
      durationMs: response.duration.inMilliseconds,
      isSuccess: isSuccess,
      errorMsg: errorMsg,
    );
}
