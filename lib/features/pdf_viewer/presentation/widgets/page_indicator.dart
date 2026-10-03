import 'package:flutter/material.dart';

// IMPROVED: Floating Google Drive style page indicator capsule
/// Floating pill displaying current page number out of total pages (e.g. "3 / 42").
/// Tapping it opens the quick page jump dialog.
class PdfPageIndicator extends StatelessWidget {
  const PdfPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onTap,
    this.isVisible = true,
    super.key,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onTap;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible || totalPages <= 0) return const SizedBox.shrink();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isVisible ? 1.0 : 0.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '$currentPage / $totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
