import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_response.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentConversionService
///
/// Service coordinating background isolate executors for TXT ⇄ PDF and HTML ⇄ PDF.
/// ─────────────────────────────────────────────────────────────────────────────
class DocumentConversionService {
  DocumentConversionService();

  final Map<String, Isolate> _runningIsolates = {};
  final Map<String, ReceivePort> _runningReceivePorts = {};

  /// Runs background isolate conversion routines.
  Future<Result<DocumentConversionResponse>> executeIsolateConversion({
    required String taskId,
    required void Function(Map<String, dynamic>) entryPoint,
    required Map<String, dynamic> baseArgs,
    required void Function(double progress) onProgress,
  }) async {
    final receivePort = ReceivePort();
    final progressPort = ReceivePort();
    _runningReceivePorts[taskId] = receivePort;

    final args = Map<String, dynamic>.from(baseArgs)
      ..['replyPort'] = receivePort.sendPort
      ..['progressPort'] = progressPort.sendPort;

    try {
      final isolate = await Isolate.spawn(entryPoint, args);
      _runningIsolates[taskId] = isolate;

      final progressSub = progressPort.listen((message) {
        if (message is double) {
          onProgress(message);
        }
      });

      final completer = Completer<Result<DocumentConversionResponse>>();

      receivePort.listen((message) {
        progressSub.cancel();
        progressPort.close();
        _cleanupTask(taskId);

        if (message is Map<String, dynamic>) {
          final res = DocumentConversionResponse(
            outputPath: message['outputPath'] as String,
            fileSizeBytes: message['fileSizeBytes'] as int,
            duration: Duration(milliseconds: message['durationMs'] as int),
          );
          completer.complete(Success(res));
        } else if (message is Exception) {
          completer.complete(
            FailureResult(
              ConversionFailure(
                message: message.toString().replaceAll('Exception: ', ''),
                technicalMessage: 'Isolate error during document parsing.',
              ),
            ),
          );
        } else {
          completer.complete(
            const FailureResult(
              ConversionFailure(message: 'Unknown document processing response.'),
            ),
          );
        }
      });

      return await completer.future;
    } catch (e, stack) {
      receivePort.close();
      progressPort.close();
      _cleanupTask(taskId);
      return FailureResult(
        ConversionFailure(
          message: 'Failed to spawn background document parser isolate.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  void _cleanupTask(String taskId) {
    _runningIsolates.remove(taskId)?.kill();
    _runningReceivePorts.remove(taskId)?.close();
  }

  /// Cancels an active isolate.
  Future<void> cancelTask(String taskId) async {
    _cleanupTask(taskId);
    AppLogger.info('DocumentConversionService: Force terminated background worker for $taskId');
  }

  // ── Isolate Entry Point: TXT to PDF ────────────────────────────────────────
  static Future<void> isolateTxtToPdf(Map<String, dynamic> args) async {
    final progressPort = args['progressPort'] as SendPort?;
    final replyPort = args['replyPort'] as SendPort;
    final inputPath = args['inputPath'] as String;
    final outputPath = args['outputPath'] as String;
    final keepMetadata = args['keepMetadata'] as bool;

    final stopwatch = Stopwatch()..start();

    try {
      final sourceFile = File(inputPath);
      final txtContent = await sourceFile.readAsString();

      if (progressPort != null) progressPort.send(0.2);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final lines = txtContent.split('\n');
      final pdfBuffer = StringBuffer();
      
      // Write standard plain PDF format tree structures (offline creation)
      pdfBuffer.write('%PDF-1.4\n');
      pdfBuffer.write('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
      pdfBuffer.write('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');
      pdfBuffer.write('3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R >>\nendobj\n');

      if (progressPort != null) progressPort.send(0.5);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Draw text streams objects inside the PDF pages contents catalog
      final textStream = StringBuffer();
      textStream.write('BT\n/F1 12 Tf\n50 800 Td\n15 TL\n');
      
      for (final line in lines) {
        // Basic escaping for text strings inside parentheses
        final escapedLine = line.replaceAll('(', r'\(').replaceAll(')', r'\)');
        textStream.write('($escapedLine) Tj T*\n');
      }
      textStream.write('ET\n');

      final streamLength = textStream.length;
      pdfBuffer.write('4 0 obj\n<< /Length $streamLength >>\nstream\n$textStream\nendstream\nendobj\n');

      if (keepMetadata) {
        pdfBuffer.write('5 0 obj\n<< /Title (FluxConvert Document) /Creator (FluxConvert Offline Engine) >>\nendobj\n');
      }

      pdfBuffer.write('%%EOF\n');

      final targetFile = File(outputPath);
      await targetFile.writeAsString(pdfBuffer.toString());

      if (progressPort != null) progressPort.send(1.0);
      stopwatch.stop();

      replyPort.send({
        'outputPath': outputPath,
        'fileSizeBytes': targetFile.lengthSync(),
        'durationMs': stopwatch.elapsedMilliseconds,
      });
    } catch (e) {
      replyPort.send(Exception('TXT to PDF conversion failed: $e'));
    }
  }

  // ── Isolate Entry Point: PDF to TXT ────────────────────────────────────────
  static Future<void> isolatePdfToTxt(Map<String, dynamic> args) async {
    final progressPort = args['progressPort'] as SendPort?;
    final replyPort = args['replyPort'] as SendPort;
    final inputPath = args['inputPath'] as String;
    final outputPath = args['outputPath'] as String;

    final stopwatch = Stopwatch()..start();

    try {
      final sourceFile = File(inputPath);
      final pdfContent = await sourceFile.readAsString();

      if (progressPort != null) progressPort.send(0.2);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Extract plain text string streams using basic regex (offline decoding)
      final textMatches = RegExp(r'\((.*?)\)\s*Tj').allMatches(pdfContent);
      final extractedText = StringBuffer();

      if (progressPort != null) progressPort.send(0.5);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      for (final match in textMatches) {
        final rawText = match.group(1) ?? '';
        // Unescape PDF string parameters
        final cleanText = rawText.replaceAll(r'\(', '(').replaceAll(r'\)', ')');
        extractedText.writeln(cleanText);
      }

      final targetFile = File(outputPath);
      await targetFile.writeAsString(extractedText.toString());

      if (progressPort != null) progressPort.send(1.0);
      stopwatch.stop();

      replyPort.send({
        'outputPath': outputPath,
        'fileSizeBytes': targetFile.lengthSync(),
        'durationMs': stopwatch.elapsedMilliseconds,
      });
    } catch (e) {
      replyPort.send(Exception('PDF to TXT extraction failed: $e'));
    }
  }
}
