import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/smart_scan_state.dart';

void main() {
  group('SmartScanState Tests', () {
    test('default state values are correct', () {
      const state = SmartScanState();
      expect(state.status, equals(SmartScanStatus.initial));
      expect(state.errorMessage, isNull);
      expect(state.flashMode, equals(FlashMode.off));
      expect(state.stagedImagePaths, isEmpty);
      expect(state.isCapturing, isFalse);
      expect(state.isCameraReady, isFalse);
      expect(state.hasStagedPages, isFalse);
      expect(state.pageCount, equals(0));
    });

    test('copyWith updates fields correctly', () {
      const state = SmartScanState();
      final updated = state.copyWith(
        status: SmartScanStatus.cameraReady,
        flashMode: FlashMode.always,
        stagedImagePaths: ['/tmp/scan1.jpg'],
        isCapturing: true,
      );

      expect(updated.status, equals(SmartScanStatus.cameraReady));
      expect(updated.flashMode, equals(FlashMode.always));
      expect(updated.stagedImagePaths, equals(['/tmp/scan1.jpg']));
      expect(updated.isCapturing, isTrue);
      expect(updated.isCameraReady, isTrue);
      expect(updated.hasStagedPages, isTrue);
      expect(updated.pageCount, equals(1));
    });

    test('copyWith clearError resets errorMessage', () {
      const state = SmartScanState(
        status: SmartScanStatus.cameraError,
        errorMessage: 'Camera error occurred',
      );

      final cleared = state.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('value equality props test', () {
      const state1 = SmartScanState(
        status: SmartScanStatus.cameraReady,
        stagedImagePaths: ['/path/1.jpg'],
      );
      const state2 = SmartScanState(
        status: SmartScanStatus.cameraReady,
        stagedImagePaths: ['/path/1.jpg'],
      );

      expect(state1, equals(state2));
    });
  });
}
