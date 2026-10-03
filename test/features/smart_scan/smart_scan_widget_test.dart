import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/smart_scan/data/scan_enhancement_service.dart';
import 'package:flux_convert/features/smart_scan/presentation/controllers/scan_session_notifier.dart';
import 'package:flux_convert/features/smart_scan/presentation/pages/smart_scan_page_manager_page.dart';
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
    tempDir = await Directory.systemTemp.createTemp('widget_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  testWidgets('SmartScanPageManagerPage shows empty state when session has no pages', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanSessionProvider.overrideWith(
            (ref) => ScanSessionNotifier(
              enhancementService: FakeScanEnhancementService(),
              directoryManager: FakeDirectoryManager(tempDir.path),
              ref: ref,
            ),
          ),
        ],
        child: const MaterialApp(
          home: SmartScanPageManagerPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No Pages in Scan Session'), findsOneWidget);
    expect(find.text('Add Page'), findsOneWidget);
  });

  testWidgets('SmartScanPageManagerPage shows page tools and thumbnail strip when session has pages', (WidgetTester tester) async {
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
        child: const MaterialApp(
          home: SmartScanPageManagerPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Document Review'), findsOneWidget);
    expect(find.text('Rotate'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);
    expect(find.text('Create PDF (1)'), findsOneWidget);
  });
}
