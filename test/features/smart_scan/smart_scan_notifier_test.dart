import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flux_convert/core/permissions/permission_service.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/smart_scan_state.dart';
import 'package:flux_convert/features/smart_scan/presentation/controllers/smart_scan_notifier.dart';
import 'package:flux_convert/features/storage/data/services/directory_manager.dart';

class MockPermissionService extends Mock implements PermissionService {
  @override
  Future<PermissionStatus> requestCameraPermission() => super.noSuchMethod(
        Invocation.method(#requestCameraPermission, []),
        returnValue: Future.value(PermissionStatus.granted),
        returnValueForMissingStub: Future.value(PermissionStatus.granted),
      ) as Future<PermissionStatus>;

  @override
  Future<bool> isCameraGranted() => super.noSuchMethod(
        Invocation.method(#isCameraGranted, []),
        returnValue: Future.value(true),
        returnValueForMissingStub: Future.value(true),
      ) as Future<bool>;

  @override
  Future<bool> openAppSettingsPage() => super.noSuchMethod(
        Invocation.method(#openAppSettingsPage, []),
        returnValue: Future.value(true),
        returnValueForMissingStub: Future.value(true),
      ) as Future<bool>;
}

class MockDirectoryManager extends Mock implements DirectoryManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPermissionService mockPermissionService;
  late MockDirectoryManager mockDirectoryManager;

  setUp(() {
    mockPermissionService = MockPermissionService();
    mockDirectoryManager = MockDirectoryManager();
  });

  group('SmartScanNotifier Unit Tests', () {
    test('initial state is SmartScanStatus.initial', () {
      final notifier = SmartScanNotifier(
        permissionService: mockPermissionService,
        directoryManager: mockDirectoryManager,
      );

      expect(notifier.state.status, equals(SmartScanStatus.initial));
      expect(notifier.state.stagedImagePaths, isEmpty);
      notifier.dispose();
    });

    test('permission denied transition updates state', () async {
      when(mockPermissionService.requestCameraPermission())
          .thenAnswer((_) async => PermissionStatus.denied);

      final notifier = SmartScanNotifier(
        permissionService: mockPermissionService,
        directoryManager: mockDirectoryManager,
      );

      await notifier.initializeSession();

      expect(notifier.state.status, equals(SmartScanStatus.permissionDenied));
      notifier.dispose();
    });

    test('permission permanently denied transition updates state', () async {
      when(mockPermissionService.requestCameraPermission())
          .thenAnswer((_) async => PermissionStatus.permanentlyDenied);

      final notifier = SmartScanNotifier(
        permissionService: mockPermissionService,
        directoryManager: mockDirectoryManager,
      );

      await notifier.initializeSession();

      expect(
        notifier.state.status,
        equals(SmartScanStatus.permissionPermanentlyDenied),
      );
      notifier.dispose();
    });

    test('removeStagedPage removes path from list', () {
      final notifier = SmartScanNotifier(
        permissionService: mockPermissionService,
        directoryManager: mockDirectoryManager,
      );

      notifier.state = notifier.state.copyWith(
        stagedImagePaths: ['/tmp/path1.jpg', '/tmp/path2.jpg'],
      );

      expect(notifier.state.pageCount, equals(2));

      notifier.removeStagedPage(0);

      expect(notifier.state.pageCount, equals(1));
      expect(notifier.state.stagedImagePaths.first, equals('/tmp/path2.jpg'));
      notifier.dispose();
    });

    test('clearStagedPages empties list', () {
      final notifier = SmartScanNotifier(
        permissionService: mockPermissionService,
        directoryManager: mockDirectoryManager,
      );

      notifier.state = notifier.state.copyWith(
        stagedImagePaths: ['/tmp/path1.jpg', '/tmp/path2.jpg'],
      );

      notifier.clearStagedPages();

      expect(notifier.state.stagedImagePaths, isEmpty);
      notifier.dispose();
    });
  });
}
