import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/smart_scan/data/scan_enhancement_service.dart';
import 'package:flux_convert/features/smart_scan/presentation/controllers/scan_session_notifier.dart';
import 'package:flux_convert/features/smart_scan/presentation/pages/smart_scan_review_page.dart';
import 'package:flux_convert/features/storage/data/services/directory_manager.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_path_config.dart';

class FakeScanEnhancementService extends ScanEnhancementService {
  @override
  Future<String> processImageInIsolate(ScanEnhancementParams params) async {
    final file = File(params.outputPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    file.writeAsStringSync('dummy content');
    return params.outputPath;
  }
}

class FakeDirectoryManager extends DirectoryManager {
  FakeDirectoryManager(this.basePath);
  final String basePath;

  @override
  Future<StoragePathConfig> ensureAll() async {
    return StoragePathConfig(
      rootPath: basePath,
      convertedDocumentsPath: '$basePath/docs',
      convertedImagesPath: '$basePath/imgs',
      tempPath: '$basePath/temp',
      cachePath: '$basePath/cache',
      logsPath: '$basePath/logs',
      exportsPath: '$basePath/exports',
      historyPath: '$basePath/history',
      thumbnailsPath: '$basePath/thumbs',
      scansTempPath: '$basePath/scans',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    try {
      AppLogger.init();
    } catch (_) {}
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('review_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  Widget buildSubject(WidgetRef ref) {
    return const MaterialApp(
      home: SmartScanReviewPage(),
    );
  }

  testWidgets('SmartScanReviewPage renders title, page count and output options', (WidgetTester tester) async {
    final sampleImg = File('${tempDir.path}/page1.jpg')..writeAsStringSync('dummy content');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanSessionProvider.overrideWith(
            (ref) {
              final notifier = ScanSessionNotifier(
                enhancementService: FakeScanEnhancementService(),
                directoryManager: FakeDirectoryManager(tempDir.path),
                ref: ref,
              );
              notifier.addPage(sampleImg.path);
              return notifier;
            },
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) => buildSubject(ref),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Compile PDF Document'), findsOneWidget);
    expect(find.text('PDF Output Settings'), findsOneWidget);
    expect(find.text('PDF Page Size'), findsOneWidget);
    expect(find.text('Create PDF Document'), findsOneWidget);
    expect(find.text('Continue Editing Pages'), findsOneWidget);
  });
}
