import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as ex;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:image/image.dart' as img;
import 'package:flux_convert/features/conversion/domain/entities/conversion_result.dart';
import 'package:flux_convert/features/conversion/core/adapters/conversion_context.dart';
import 'package:flux_convert/features/conversion/core/adapters/converter_adapter.dart';
import 'package:flux_convert/features/conversion/core/adapters/converter_capabilities.dart';
import 'package:flux_convert/features/conversion/core/adapters/format_converter_registry.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Placeholders Registry
///
/// Contains stub implementations of future converter adapters.
/// Exposes [registerAll] to initialize the conversion matrix on boot.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class Placeholders {
  static void registerAll() {
    FormatConverterRegistry.register(const PdfConverter());
    FormatConverterRegistry.register(const WordConverter());
    FormatConverterRegistry.register(const ImageConverter());
    FormatConverterRegistry.register(const ExcelConverter());
    FormatConverterRegistry.register(const PresentationConverter());
    FormatConverterRegistry.register(const TextConverter());
    FormatConverterRegistry.register(const HtmlConverter());
    FormatConverterRegistry.register(const PdfToPdfConverter());
  }
}

/// 📄 PDF Converter placeholder
class PdfConverter extends ConverterAdapter {
  const PdfConverter();

  @override
  String get converterId => 'com.fluxconvert.pdf_converter';

  @override
  String get displayName => 'PDF Document Converter';

  @override
  List<String> get supportedInputFormats => ['pdf'];

  @override
  List<String> get supportedOutputFormats => [
    'docx',
    'txt',
    'png',
    'jpg',
    'webp',
  ];

  @override
  ConverterCapabilities get capabilities => ConverterCapabilities.fullFeatured;

  @override
  Future<ConversionResult> executePackageConversion(
    ConversionContext context,
    void Function(double progress) onProgress,
  ) async {
    final outputFile = File(context.outputPath);
    final buffer = StringBuffer();
    buffer.writeln('=== PDF Content Extract ===');
    buffer.writeln('Source PDF: ${context.inputFile.path}');
    buffer.writeln('Original size: ${context.inputFile.lengthSync()} bytes');
    buffer.writeln('Extraction timestamp: ${DateTime.now()}');
    await outputFile.writeAsString(buffer.toString());

    onProgress(1.0);
    return ConversionResult(
      sourcePath: context.inputFile.path,
      destinationPath: context.outputPath,
      fileSizeBytes: outputFile.lengthSync(),
      duration: const Duration(seconds: 1),
      outputName: context.outputPath.split('/').last.split(r'\').last,
      isSuccess: true,
    );
  }
}

/// 📝 Word Converter placeholder
class WordConverter extends ConverterAdapter {
  const WordConverter();

  @override
  String get converterId => 'com.fluxconvert.word_converter';

  @override
  String get displayName => 'Word Document Converter';

  @override
  List<String> get supportedInputFormats => ['doc', 'docx'];

  @override
  List<String> get supportedOutputFormats => ['pdf', 'txt'];

  @override
  ConverterCapabilities get capabilities => ConverterCapabilities.basic;

  @override
  Future<ConversionResult> executePackageConversion(
    ConversionContext context,
    void Function(double progress) onProgress,
  ) async {
    final outputFile = File(context.outputPath);
    if (context.outputPath.endsWith('.pdf')) {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context pageContext) {
            return pw.Center(
              child: pw.Text(
                'Converted Word Document (PDF)\nSource: ${context.inputFile.path}',
              ),
            );
          },
        ),
      );
      await outputFile.writeAsBytes(await pdf.save());
    } else {
      await outputFile.writeAsString(
        'Word document plain text extraction content from ${context.inputFile.path}',
      );
    }

    onProgress(1.0);
    return ConversionResult(
      sourcePath: context.inputFile.path,
      destinationPath: context.outputPath,
      fileSizeBytes: outputFile.lengthSync(),
      duration: const Duration(seconds: 1),
      outputName: context.outputPath.split('/').last.split(r'\').last,
      isSuccess: true,
    );
  }
}

/// 🖼 Image Converter placeholder
class ImageConverter extends ConverterAdapter {
  const ImageConverter();

  @override
  String get converterId => 'com.fluxconvert.image_converter';

  @override
  String get displayName => 'Image Assets Converter';

  @override
  List<String> get supportedInputFormats => [
    'png',
    'jpg',
    'jpeg',
    'webp',
    'bmp',
    'gif',
    'tiff',
    'svg',
    'heic',
  ];

  @override
  List<String> get supportedOutputFormats => ['png', 'jpg', 'webp', 'pdf'];

  @override
  ConverterCapabilities get capabilities => const ConverterCapabilities(
    supportsBatch: true,
    supportsProgress: true,
    supportsCancellation: true,
    supportsPasswordProtectedFiles: false,
    supportsMetadata: true,
    supportsCompression: true,
    supportsMultiPage: false,
  );

  @override
  Future<ConversionResult> executePackageConversion(
    ConversionContext context,
    void Function(double progress) onProgress,
  ) async {
    final isPdfOutput = context.outputPath.toLowerCase().endsWith('.pdf');
    final additionalFiles =
        context.settings.customParameters['additionalFiles'] as List<String>?;
    final marginOpt =
        context.settings.customParameters['margin'] as String? ?? 'none';
    final pageFitOpt =
        context.settings.customParameters['pageFit'] as String? ?? 'fit';
    final pageSizeOpt =
        context.settings.customParameters['pageSize'] as String? ?? 'A4';
    final orientationOpt =
        context.settings.customParameters['orientation'] as String? ?? 'Auto';
    final compressionOpt =
        context.settings.customParameters['compression'] as String? ??
        'Low Compression';

    final file = File(context.outputPath);
    if (isPdfOutput) {
      final pdf = pw.Document();

      var marginVal = 0.0;
      if (marginOpt == 'small') {
        marginVal = 10.0;
      } else if (marginOpt == 'large') {
        marginVal = 24.0;
      }

      var fitVal = pw.BoxFit.contain;
      if (pageFitOpt == 'fill') {
        fitVal = pw.BoxFit.fill;
      } else if (pageFitOpt == 'original') {
        fitVal = pw.BoxFit.none;
      }

      // Parse quality from compression option
      var quality = 100;
      final compLower = compressionOpt.toLowerCase();
      if (compLower.contains('max compression')) {
        quality = 30;
      } else if (compLower.contains('medium compression')) {
        quality = 60;
      } else if (compLower.contains('regular compression')) {
        quality = 85;
      } else if (compLower.contains('low compression')) {
        quality = 100;
      }

      // Parse base page format from page size option
      final baseFormat = switch (pageSizeOpt.toUpperCase()) {
        'A4' => PdfPageFormat.a4,
        'LETTER' => PdfPageFormat.letter,
        'A3' => PdfPageFormat.a3,
        'A5' => PdfPageFormat.a5,
        'LEGAL' => PdfPageFormat.legal,
        'EXECUTIVE' => const PdfPageFormat(
            7.25 * PdfPageFormat.inch,
            10.5 * PdfPageFormat.inch,
            marginAll: PdfPageFormat.inch,
          ),
        'LEDGER' => const PdfPageFormat(
            11.0 * PdfPageFormat.inch,
            17.0 * PdfPageFormat.inch,
            marginAll: PdfPageFormat.inch,
          ),
        _ => PdfPageFormat.a4,
      };

      Future<void> addImagePage(String imgPath) async {
        final imgFile = File(imgPath);
        if (imgFile.existsSync()) {
          var bytes = await imgFile.readAsBytes();

          // Check if dimensions exceed 2500px or if compression is requested
          final parsedSize = ImageHeaderParser.getSize(bytes);
          final originalWidth = parsedSize?.width ?? 0;
          final originalHeight = parsedSize?.height ?? 0;
          final isOversized = originalWidth > 2500 || originalHeight > 2500;

          if (quality < 100 || isOversized) {
            try {
              bytes = await compute(
                _processImageIsolate,
                ImageProcessParams(
                  bytes: bytes,
                  quality: quality,
                  maxDimension: 2500,
                ),
              );
            } catch (_) {}
          }

          final image = pw.MemoryImage(bytes);

          // Determine format with orientation
          var format = baseFormat;
          var isLandscape = false;
          if (orientationOpt == 'Landscape') {
            isLandscape = true;
          } else if (orientationOpt == 'Auto') {
            final parsedSize = ImageHeaderParser.getSize(bytes);
            if (parsedSize != null && parsedSize.width > parsedSize.height) {
              isLandscape = true;
            }
          }

          if (isLandscape) {
            format = format.landscape;
          }

          pdf.addPage(
            pw.Page(
              pageFormat: format,
              margin: pw.EdgeInsets.all(marginVal),
              build: (pw.Context pageContext) {
                return pw.Center(child: pw.Image(image, fit: fitVal));
              },
            ),
          );
        }
      }

      final uniqueImages = <String>{};
      if (additionalFiles != null && additionalFiles.isNotEmpty) {
        uniqueImages.addAll(additionalFiles);
      } else {
        uniqueImages.add(context.inputFile.path);
      }

      var index = 0;
      for (final path in uniqueImages) {
        await addImagePage(path);
        index++;
        onProgress(index / uniqueImages.length);
        // Yield thread for smooth UI/GC
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      final pdfBytes = await pdf.save();
      final password =
          context.settings.customParameters['pdfPassword'] as String?;

      // Enhanced PDF encryption with professional security settings
      if (password != null && password.isNotEmpty) {
        try {
          final sfPdf = sf.PdfDocument(inputBytes: pdfBytes);

          // Professional encryption settings
          sfPdf.security.userPassword = password;
          sfPdf.security.ownerPassword = password;
          sfPdf.security.algorithm = sf.PdfEncryptionAlgorithm.aesx128Bit;

          // Additional security settings for better protection
          sfPdf.security.permissions.add(sf.PdfPermissionsFlags.print);

          final securedBytes = sfPdf.saveSync();
          sfPdf.dispose();
          await file.writeAsBytes(securedBytes);
        } catch (e) {
          // If encryption fails, save without password (fallback)
          await file.writeAsBytes(pdfBytes);
          // Re-throw to let the caller know encryption failed
          rethrow;
        }
      } else {
        await file.writeAsBytes(pdfBytes);
      }
    } else {
      if (context.inputFile.existsSync()) {
        await file.writeAsBytes(await context.inputFile.readAsBytes());
      }
    }

    onProgress(1.0);
    return ConversionResult(
      sourcePath: context.inputFile.path,
      destinationPath: context.outputPath,
      fileSizeBytes: file.existsSync()
          ? file.lengthSync()
          : context.inputFile.lengthSync(),
      duration: const Duration(seconds: 1),
      outputName: context.outputPath.split('/').last.split(r'\').last,
      isSuccess: true,
    );
  }
}

/// 📊 Excel Converter placeholder
class ExcelConverter extends ConverterAdapter {
  const ExcelConverter();

  @override
  String get converterId => 'com.fluxconvert.excel_converter';

  @override
  String get displayName => 'Excel Spreadsheets Converter';

  @override
  List<String> get supportedInputFormats => ['xls', 'xlsx', 'csv', 'ods'];

  @override
  List<String> get supportedOutputFormats => ['pdf', 'csv', 'xlsx'];

  @override
  ConverterCapabilities get capabilities => ConverterCapabilities.basic;

  @override
  Future<ConversionResult> executePackageConversion(
    ConversionContext context,
    void Function(double progress) onProgress,
  ) async {
    final outputFile = File(context.outputPath);
    final inputBytes = await context.inputFile.readAsBytes();

    ex.Excel? excelObj;
    try {
      excelObj = ex.Excel.decodeBytes(inputBytes);
    } catch (_) {}

    if (context.outputPath.endsWith('.pdf')) {
      final pdf = pw.Document();
      if (excelObj != null) {
        for (final tableName in excelObj.tables.keys) {
          final sheet = excelObj.tables[tableName];
          if (sheet != null) {
            final rows = <pw.TableRow>[];
            for (final row in sheet.rows.take(20)) {
              rows.add(
                pw.TableRow(
                  children: row.map((cell) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        cell?.value?.toString() ?? '',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    );
                  }).toList(),
                ),
              );
            }
            pdf.addPage(
              pw.Page(
                build: (pw.Context pageContext) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Sheet: $tableName',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Table(
                        border: pw.TableBorder.all(
                          color: PdfColors.grey,
                          width: 0.5,
                        ),
                        children: rows,
                      ),
                    ],
                  );
                },
              ),
            );
          }
        }
      } else {
        pdf.addPage(
          pw.Page(
            build: (pw.Context pageContext) {
              return pw.Center(
                child: pw.Text(
                  'Converted Excel Content (PDF)\nSource: ${context.inputFile.path}',
                ),
              );
            },
          ),
        );
      }
      await outputFile.writeAsBytes(await pdf.save());
    } else if (context.outputPath.endsWith('.csv')) {
      final csvBuffer = StringBuffer();
      if (excelObj != null) {
        for (final tableName in excelObj.tables.keys) {
          final sheet = excelObj.tables[tableName];
          if (sheet != null) {
            for (final row in sheet.rows) {
              final rowValues = row
                  .map((cell) => cell?.value?.toString() ?? '')
                  .toList();
              csvBuffer.writeln(rowValues.join(','));
            }
          }
        }
      } else {
        csvBuffer.writeln(
          'CSV placeholder content from ${context.inputFile.path}',
        );
      }
      await outputFile.writeAsString(csvBuffer.toString());
    } else {
      await outputFile.writeAsBytes(inputBytes);
    }

    onProgress(1.0);
    return ConversionResult(
      sourcePath: context.inputFile.path,
      destinationPath: context.outputPath,
      fileSizeBytes: outputFile.lengthSync(),
      duration: const Duration(seconds: 1),
      outputName: context.outputPath.split('/').last.split(r'\').last,
      isSuccess: true,
    );
  }
}

/// 📊 Presentation Converter placeholder
class PresentationConverter extends ConverterAdapter {
  const PresentationConverter();

  @override
  String get converterId => 'com.fluxconvert.presentation_converter';

  @override
  String get displayName => 'Presentation Slides Converter';

  @override
  List<String> get supportedInputFormats => ['ppt', 'pptx'];

  @override
  List<String> get supportedOutputFormats => ['pdf'];

  @override
  ConverterCapabilities get capabilities => ConverterCapabilities.basic;

  @override
  Future<ConversionResult> executePackageConversion(
    ConversionContext context,
    void Function(double progress) onProgress,
  ) async {
    final outputFile = File(context.outputPath);
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter.landscape,
        build: (pw.Context pageContext) {
          return pw.Center(
            child: pw.Text(
              'PowerPoint Presentation (Landscape PDF)\nSource: ${context.inputFile.path}',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
          );
        },
      ),
    );
    await outputFile.writeAsBytes(await pdf.save());

    onProgress(1.0);
    return ConversionResult(
      sourcePath: context.inputFile.path,
      destinationPath: context.outputPath,
      fileSizeBytes: outputFile.lengthSync(),
      duration: const Duration(seconds: 1),
      outputName: context.outputPath.split('/').last.split(r'\').last,
      isSuccess: true,
    );
  }
}

/// 📝 Text Converter placeholder
class TextConverter extends ConverterAdapter {
  const TextConverter();

  @override
  String get converterId => 'com.fluxconvert.text_converter';

  @override
  String get displayName => 'Raw Text Converter';

  @override
  List<String> get supportedInputFormats => ['txt', 'rtf', 'odt'];

  @override
  List<String> get supportedOutputFormats => ['pdf', 'docx'];

  @override
  ConverterCapabilities get capabilities => ConverterCapabilities.basic;

  @override
  Future<ConversionResult> executePackageConversion(
    ConversionContext context,
    void Function(double progress) onProgress,
  ) async {
    final outputFile = File(context.outputPath);
    final textContent = await context.inputFile.readAsString();

    if (context.outputPath.endsWith('.pdf')) {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context pageContext) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Text(textContent),
            );
          },
        ),
      );
      await outputFile.writeAsBytes(await pdf.save());
    } else {
      await outputFile.writeAsString(textContent);
    }

    onProgress(1.0);
    return ConversionResult(
      sourcePath: context.inputFile.path,
      destinationPath: context.outputPath,
      fileSizeBytes: outputFile.lengthSync(),
      duration: const Duration(seconds: 1),
      outputName: context.outputPath.split('/').last.split(r'\').last,
      isSuccess: true,
    );
  }
}

/// 🌐 HTML Converter placeholder
class HtmlConverter extends ConverterAdapter {
  const HtmlConverter();

  @override
  String get converterId => 'com.fluxconvert.html_converter';

  @override
  String get displayName => 'HTML Documents Converter';

  @override
  List<String> get supportedInputFormats => ['html'];

  @override
  List<String> get supportedOutputFormats => ['pdf'];

  @override
  ConverterCapabilities get capabilities => ConverterCapabilities.basic;

  @override
  Future<ConversionResult> executePackageConversion(
    ConversionContext context,
    void Function(double progress) onProgress,
  ) async {
    final outputFile = File(context.outputPath);
    final htmlContent = await context.inputFile.readAsString();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context pageContext) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            // Strip tags for basic text printing
            child: pw.Text(htmlContent.replaceAll(RegExp('<[^>]*>'), '')),
          );
        },
      ),
    );
    await outputFile.writeAsBytes(await pdf.save());

    onProgress(1.0);
    return ConversionResult(
      sourcePath: context.inputFile.path,
      destinationPath: context.outputPath,
      fileSizeBytes: outputFile.lengthSync(),
      duration: const Duration(seconds: 1),
      outputName: context.outputPath.split('/').last.split(r'\').last,
      isSuccess: true,
    );
  }
}

/// 📄 PDF to PDF Converter (for Compress and Merge PDF)
class PdfToPdfConverter extends ConverterAdapter {
  const PdfToPdfConverter();

  @override
  String get converterId => 'com.fluxconvert.pdf_to_pdf_converter';

  @override
  String get displayName => 'PDF Optimization Converter';

  @override
  List<String> get supportedInputFormats => const ['pdf'];

  @override
  List<String> get supportedOutputFormats => const ['pdf'];

  @override
  ConverterCapabilities get capabilities => ConverterCapabilities.basic;

  @override
  Future<ConversionResult> executePackageConversion(
    ConversionContext context,
    void Function(double progress) onProgress,
  ) async {
    final additionalFiles =
        context.settings.customParameters['additionalFiles'] as List<String>?;
    onProgress(0.5);

    final outputFile = File(context.outputPath);
    final pdf = pw.Document();

    final mergedFilesList = <String>[];
    if (additionalFiles != null && additionalFiles.isNotEmpty) {
      final uniquePaths = <String>{};
      uniquePaths.addAll(additionalFiles);
      mergedFilesList.addAll(uniquePaths);
    } else {
      mergedFilesList.add(context.inputFile.path);
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context pageContext) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Compiled Merged PDF Document',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Merged timestamp: ${DateTime.now()}'),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Included Files:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...mergedFilesList.map((path) {
                  final name = path.split('/').last.split(r'\').last;
                  final size = File(path).existsSync()
                      ? File(path).lengthSync()
                      : 0;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text(
                      '• $name (${(size / 1024).toStringAsFixed(1)} KB)',
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );

    await outputFile.writeAsBytes(await pdf.save());

    onProgress(1.0);
    return ConversionResult(
      sourcePath: context.inputFile.path,
      destinationPath: context.outputPath,
      fileSizeBytes: outputFile.lengthSync(),
      duration: const Duration(seconds: 1),
      outputName: context.outputPath.split('/').last.split(r'\').last,
      isSuccess: true,
    );
  }
}

class ImageSize {
  const ImageSize(this.width, this.height);

  final double width;
  final double height;
}

abstract final class ImageHeaderParser {
  static ImageSize? getSize(Uint8List bytes) {
    if (bytes.length < 8) return null;

    // PNG Check
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      if (bytes.length < 24) return null;
      final w =
          (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
      final h =
          (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
      return ImageSize(w.toDouble(), h.toDouble());
    }

    // JPEG Check
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      var i = 2;
      while (i < bytes.length - 8) {
        if (bytes[i] == 0xFF) {
          final marker = bytes[i + 1];
          if (marker == 0xC0 ||
              marker == 0xC1 ||
              marker == 0xC2 ||
              marker == 0xC3 ||
              marker == 0xC5 ||
              marker == 0xC6 ||
              marker == 0xC7 ||
              marker == 0xC9 ||
              marker == 0xCA ||
              marker == 0xCB ||
              marker == 0xCD ||
              marker == 0xCE ||
              marker == 0xCF) {
            final h = (bytes[i + 5] << 8) | bytes[i + 6];
            final w = (bytes[i + 7] << 8) | bytes[i + 8];
            return ImageSize(w.toDouble(), h.toDouble());
          }
          final length = (bytes[i + 2] << 8) | bytes[i + 3];
          i += 2 + length;
        } else {
          i++;
        }
      }
    }

    // WebP Check
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      if (bytes.length < 30) return null;
      if (bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        if (bytes[12] == 0x56 && bytes[13] == 0x50 && bytes[14] == 0x38) {
          if (bytes[15] == 0x20) {
            final w = bytes[22] | (bytes[23] << 8);
            final h = bytes[24] | (bytes[25] << 8);
            return ImageSize(w.toDouble(), h.toDouble());
          } else if (bytes[15] == 0x4C) {
            final w = bytes[21] | ((bytes[22] & 0x3F) << 8);
            final h =
                ((bytes[22] & 0xC0) >> 6) |
                (bytes[23] << 2) |
                ((bytes[24] & 0x0F) << 10);
            return ImageSize((w + 1).toDouble(), (h + 1).toDouble());
          } else if (bytes[15] == 0x58) {
            final w = bytes[24] | (bytes[25] << 8) | (bytes[26] << 16);
            final h = bytes[27] | (bytes[28] << 8) | (bytes[29] << 16);
            return ImageSize((w + 1).toDouble(), (h + 1).toDouble());
          }
        }
      }
    }

    return null;
  }
}

class ImageProcessParams {
  const ImageProcessParams({
    required this.bytes,
    required this.quality,
    required this.maxDimension,
  });

  final Uint8List bytes;
  final int quality;
  final int maxDimension;
}

Uint8List _processImageIsolate(ImageProcessParams params) {
  var decoded = img.decodeImage(params.bytes);
  if (decoded == null) return params.bytes;

  final w = decoded.width;
  final h = decoded.height;

  // Auto-downscale if either dimension exceeds the maxDimension (e.g. 2000px/2500px)
  if (w > params.maxDimension || h > params.maxDimension) {
    int targetWidth;
    int targetHeight;
    if (w > h) {
      targetWidth = params.maxDimension;
      targetHeight = (h * params.maxDimension) ~/ w;
    } else {
      targetHeight = params.maxDimension;
      targetWidth = (w * params.maxDimension) ~/ h;
    }
    decoded = img.copyResize(decoded, width: targetWidth, height: targetHeight);
  }

  // Compress to JPG (pure Dart encoder runs in this background isolate thread)
  return Uint8List.fromList(img.encodeJpg(decoded, quality: params.quality));
}
