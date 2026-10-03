import 'package:flutter_test/flutter_test.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/scanned_page.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/scan_session.dart';

void main() {
  group('ScannedPage Entity Tests', () {
    test('default properties are assigned correctly', () {
      const page = ScannedPage(
        id: 'p1',
        originalPath: '/tmp/orig.jpg',
        processedPath: '/tmp/proc.jpg',
      );

      expect(page.id, equals('p1'));
      expect(page.originalPath, equals('/tmp/orig.jpg'));
      expect(page.processedPath, equals('/tmp/proc.jpg'));
      expect(page.rotation, equals(0));
      expect(page.enhancementMode, equals(ScanEnhancementMode.original));
      expect(page.brightness, equals(0.0));
      expect(page.contrast, equals(100.0));
      expect(page.processingStatus, equals(PageProcessingStatus.idle));
      expect(page.isProcessed, isFalse);
    });

    test('copyWith creates updated immutable copy', () {
      const page = ScannedPage(
        id: 'p1',
        originalPath: '/tmp/orig.jpg',
        processedPath: '/tmp/proc.jpg',
      );

      final updated = page.copyWith(
        rotation: 90,
        enhancementMode: ScanEnhancementMode.grayscale,
        processingStatus: PageProcessingStatus.completed,
      );

      expect(updated.id, equals('p1'));
      expect(updated.rotation, equals(90));
      expect(updated.enhancementMode, equals(ScanEnhancementMode.grayscale));
      expect(updated.processingStatus, equals(PageProcessingStatus.completed));
      expect(updated.isProcessed, isTrue);
      expect(page.rotation, equals(0)); // Original is unchanged
    });

    test('value equality props test', () {
      const p1 = ScannedPage(id: '1', originalPath: 'a', processedPath: 'b');
      const p2 = ScannedPage(id: '1', originalPath: 'a', processedPath: 'b');

      expect(p1, equals(p2));
    });
  });

  group('ScanSession Entity Tests', () {
    test('empty session properties are valid', () {
      const session = ScanSession(sessionId: 's1');

      expect(session.sessionId, equals('s1'));
      expect(session.pages, isEmpty);
      expect(session.hasPages, isFalse);
      expect(session.pageCount, equals(0));
      expect(session.activePage, isNull);
    });

    test('activePage returns currently selected page', () {
      const p1 = ScannedPage(id: '1', originalPath: 'a', processedPath: 'b');
      const p2 = ScannedPage(id: '2', originalPath: 'c', processedPath: 'd');
      const session = ScanSession(
        sessionId: 's1',
        pages: [p1, p2],
        activePageIndex: 1,
      );

      expect(session.hasPages, isTrue);
      expect(session.pageCount, equals(2));
      expect(session.activePage, equals(p2));
    });
  });
}
