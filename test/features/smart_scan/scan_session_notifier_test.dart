import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/smart_scan/data/scan_enhancement_service.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/scanned_page.dart';
import 'package:flux_convert/features/smart_scan/presentation/controllers/scan_session_notifier.dart';
import 'package:flux_convert/features/storage/data/services/directory_manager.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_path_config.dart';

class FakeScanEnhancementService extends ScanEnhancementService {
  @override
  Future<String> processImageInIsolate(ScanEnhancementParams params) async {
    // Return output path immediately for test speed
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
  late ProviderContainer container;
  late ScanSessionNotifier notifier;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scan_test_');

    container = ProviderContainer(
      overrides: [
        scanSessionProvider.overrideWith(
          (ref) => ScanSessionNotifier(
            enhancementService: FakeScanEnhancementService(),
            directoryManager: FakeDirectoryManager(tempDir.path),
            ref: ref,
          ),
        ),
      ],
    );

    notifier = container.read(scanSessionProvider.notifier);
  });

  tearDown(() async {
    container.dispose();
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('ScanSessionNotifier Tests', () {
    test('initial state is empty session', () {
      final state = container.read(scanSessionProvider);
      expect(state.pages, isEmpty);
      expect(state.hasPages, isFalse);
      expect(state.pageCount, equals(0));
    });

    test('addPage adds page to session and sets active index', () async {
      final sampleImg = File('${tempDir.path}/sample.jpg');
      sampleImg.writeAsStringSync('test sample image');

      final result = await notifier.addPage(sampleImg.path);

      final state = container.read(scanSessionProvider);
      expect(state.hasPages, isTrue);
      expect(state.pageCount, equals(1));
      expect(state.activePageIndex, equals(0));
      expect(result, isNotNull);
    });

    test('removePageAt removes page and updates state', () async {
      final img1 = File('${tempDir.path}/img1.jpg')..writeAsStringSync('1');
      final img2 = File('${tempDir.path}/img2.jpg')..writeAsStringSync('2');

      await notifier.addPage(img1.path);
      await notifier.addPage(img2.path);

      expect(container.read(scanSessionProvider).pageCount, equals(2));

      notifier.removePageAt(0);

      final state = container.read(scanSessionProvider);
      expect(state.pageCount, equals(1));
      expect(state.activePageIndex, equals(0));
    });

    test('reorderPages rearranges pages deterministically', () async {
      final img1 = File('${tempDir.path}/img1.jpg')..writeAsStringSync('1');
      final img2 = File('${tempDir.path}/img2.jpg')..writeAsStringSync('2');
      final img3 = File('${tempDir.path}/img3.jpg')..writeAsStringSync('3');

      await notifier.addPage(img1.path);
      await notifier.addPage(img2.path);
      await notifier.addPage(img3.path);

      final initialPages = container.read(scanSessionProvider).pages;
      final page1Id = initialPages[0].id;
      final page2Id = initialPages[1].id;

      // Reorder index 0 -> 2
      notifier.reorderPages(0, 2);

      final reordered = container.read(scanSessionProvider).pages;
      expect(reordered[0].id, equals(page2Id));
      expect(reordered[1].id, equals(page1Id));
    });

    test('rotatePageAt updates page rotation by 90 degrees', () async {
      final img1 = File('${tempDir.path}/img1.jpg')..writeAsStringSync('1');
      await notifier.addPage(img1.path);

      await notifier.rotatePageAt(0);

      final page = container.read(scanSessionProvider).pages.first;
      expect(page.rotation, equals(90));
    });

    test('updateEnhancement updates color mode', () async {
      final img1 = File('${tempDir.path}/img1.jpg')..writeAsStringSync('1');
      await notifier.addPage(img1.path);

      await notifier.updateEnhancement(0, ScanEnhancementMode.document);

      final page = container.read(scanSessionProvider).pages.first;
      expect(page.enhancementMode, equals(ScanEnhancementMode.document));
    });

    test('clearSession clears all pages', () async {
      final img1 = File('${tempDir.path}/img1.jpg')..writeAsStringSync('1');
      await notifier.addPage(img1.path);

      notifier.clearSession(deleteFiles: true);

      final state = container.read(scanSessionProvider);
      expect(state.hasPages, isFalse);
      expect(state.pageCount, equals(0));
    });
  });
}
