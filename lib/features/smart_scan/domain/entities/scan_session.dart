import 'package:equatable/equatable.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/scanned_page.dart';

/// Immutable state model representing a multi-page Smart Scan session.
class ScanSession extends Equatable {
  const ScanSession({
    required this.sessionId,
    this.pages = const [],
    this.activePageIndex = 0,
    this.isProcessing = false,
    this.errorMessage,
  });

  final String sessionId;
  final List<ScannedPage> pages;
  final int activePageIndex;
  final bool isProcessing;
  final String? errorMessage;

  bool get hasPages => pages.isNotEmpty;
  int get pageCount => pages.length;

  ScannedPage? get activePage {
    if (pages.isEmpty || activePageIndex < 0 || activePageIndex >= pages.length) {
      return null;
    }
    return pages[activePageIndex];
  }

  ScanSession copyWith({
    String? sessionId,
    List<ScannedPage>? pages,
    int? activePageIndex,
    bool? isProcessing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ScanSession(
      sessionId: sessionId ?? this.sessionId,
      pages: pages ?? this.pages,
      activePageIndex: activePageIndex ?? this.activePageIndex,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        pages,
        activePageIndex,
        isProcessing,
        errorMessage,
      ];
}
