import 'package:flutter/material.dart';
import 'package:flux_convert/core/core.dart';

// FIXED: Clean PDF viewer bottom toolbar featuring ONLY Doodle, Add Text, & Signature
class PdfToolbar extends StatelessWidget {
  const PdfToolbar({
    required this.onOpenDoodle,
    required this.onOpenTextEditor,
    required this.onOpenSignatureEditor,
    super.key,
  });

  final VoidCallback onOpenDoodle;
  final VoidCallback onOpenTextEditor;
  final VoidCallback onOpenSignatureEditor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onOpenDoodle,
                icon: const Icon(Icons.brush_outlined, size: 18),
                label: const Text(
                  'Doodle',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorScheme.primaryBlueStart,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onOpenTextEditor,
                icon: const Icon(Icons.text_fields_rounded, size: 18),
                label: const Text(
                  'Add Text',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorScheme.primaryBlueStart,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onOpenSignatureEditor,
                icon: const Icon(Icons.gesture_rounded, size: 18),
                label: const Text(
                  'Signature',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorScheme.primaryBlueStart,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
