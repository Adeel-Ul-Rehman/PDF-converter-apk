import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';

// FIXED: Clean Modern All Tools Page featuring Convert & Tools categories
class AllToolsPage extends ConsumerWidget {
  const AllToolsPage({super.key});

  void _showComingSoonSnackBar(BuildContext context, String featureName) {
    AppPopups.showSnackBar(
      context: context,
      message: '$featureName is coming soon in a future update!',
    );
  }

  // Active File Picker helper for Doodle, Add Text, Signature, Lock PDF, Unlock Password
  Future<void> _handleActiveFeature(
    BuildContext context,
    WidgetRef ref,
    String routeName, {
    List<String> allowedExtensions = const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
  }) async {
    final notifier = ref.read(converterNotifierProvider.notifier);
    await notifier.selectFile(allowedExtensions: allowedExtensions);

    final state = ref.read(converterNotifierProvider);
    if (state.selectedFilePath != null && context.mounted) {
      if (routeName == AppRoutes.pdfViewer) {
        context.push(
          '${AppRoutes.pdfViewer}?path=${Uri.encodeComponent(state.selectedFilePath!)}',
        );
      } else {
        context.push(routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorScheme.backgroundDark : AppColorScheme.backgroundLight;
    final textPrimaryColor = isDark ? AppColorScheme.textPrimaryDark : AppColorScheme.textPrimaryLight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textPrimaryColor, size: 22),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          title: Text(
            'All Features',
            style: TextStyle(
              color: textPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── CATEGORY 1: CONVERT ────────────────────────────────────────
                _buildCategoryHeader('CONVERT'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.45,
                  children: [
                    _buildToolCard(
                      context: context,
                      icon: Icons.image_outlined,
                      title: 'Image to PDF',
                      subtitle: 'Active • Convert images',
                      color: AppColorScheme.primaryBlueStart,
                      isActive: true,
                      onTap: () => context.push(AppRoutes.imageSelection),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.description_outlined,
                      title: 'Docx to PDF',
                      subtitle: 'Coming soon',
                      color: Colors.grey.shade600,
                      isActive: false,
                      onTap: () => _showComingSoonSnackBar(context, 'Docx to PDF'),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.slideshow_rounded,
                      title: 'PPT to PDF',
                      subtitle: 'Coming soon',
                      color: Colors.grey.shade600,
                      isActive: false,
                      onTap: () => _showComingSoonSnackBar(context, 'PPT to PDF'),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.photo_library_outlined,
                      title: 'PDF to JPG',
                      subtitle: 'Coming soon',
                      color: Colors.grey.shade600,
                      isActive: false,
                      onTap: () => _showComingSoonSnackBar(context, 'PDF to JPG'),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.edit_note_rounded,
                      title: 'PDF to Word',
                      subtitle: 'Coming soon',
                      color: Colors.grey.shade600,
                      isActive: false,
                      onTap: () => _showComingSoonSnackBar(context, 'PDF to Word'),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.present_to_all_rounded,
                      title: 'PDF to PPT',
                      subtitle: 'Coming soon',
                      color: Colors.grey.shade600,
                      isActive: false,
                      onTap: () => _showComingSoonSnackBar(context, 'PDF to PPT'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── CATEGORY 2: EDIT & TOOLS ──────────────────────────────────
                _buildCategoryHeader('EDIT & TOOLS'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.45,
                  children: [
                    _buildToolCard(
                      context: context,
                      icon: Icons.compress_rounded,
                      title: 'Compress PDF',
                      subtitle: 'Active • Reduce size',
                      color: AppColorScheme.primaryBlueStart,
                      isActive: true,
                      onTap: () => context.push(AppRoutes.compressPdf),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.camera_alt_rounded,
                      title: 'Smart Scan',
                      subtitle: 'Active • Camera scan',
                      color: AppColorScheme.primaryBlueStart,
                      isActive: true,
                      onTap: () => context.push(AppRoutes.smartScan),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.brush_rounded,
                      title: 'Doodle',
                      subtitle: 'Active • Annotate PDF',
                      color: AppColorScheme.primaryBlueStart,
                      isActive: true,
                      onTap: () => _handleActiveFeature(
                        context,
                        ref,
                        AppRoutes.doodle,
                      ),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.text_fields_rounded,
                      title: 'Add Text',
                      subtitle: 'Active • Add text box',
                      color: AppColorScheme.primaryBlueStart,
                      isActive: true,
                      onTap: () => _handleActiveFeature(
                        context,
                        ref,
                        AppRoutes.textEditor,
                      ),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.draw_rounded,
                      title: 'Signature',
                      subtitle: 'Active • Sign PDF',
                      color: AppColorScheme.primaryBlueStart,
                      isActive: true,
                      onTap: () => _handleActiveFeature(
                        context,
                        ref,
                        AppRoutes.signatureEditor,
                      ),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.lock_outline_rounded,
                      title: 'Lock PDF',
                      subtitle: 'Active • Password lock',
                      color: AppColorScheme.primaryBlueStart,
                      isActive: true,
                      onTap: () => _handleActiveFeature(
                        context,
                        ref,
                        AppRoutes.pdfViewer,
                        allowedExtensions: ['pdf'],
                      ),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.lock_open_rounded,
                      title: 'Unlock Password',
                      subtitle: 'Active • Decrypt PDF',
                      color: AppColorScheme.primaryBlueStart,
                      isActive: true,
                      onTap: () => _handleActiveFeature(
                        context,
                        ref,
                        AppRoutes.pdfViewer,
                        allowedExtensions: ['pdf'],
                      ),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.merge_type_rounded,
                      title: 'Merge PDF',
                      subtitle: 'Coming soon',
                      color: Colors.grey.shade600,
                      isActive: false,
                      onTap: () => _showComingSoonSnackBar(context, 'Merge PDF'),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.compress_rounded,
                      title: 'Compress',
                      subtitle: 'Coming soon',
                      color: Colors.grey.shade600,
                      isActive: false,
                      onTap: () => _showComingSoonSnackBar(context, 'Compress'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColorScheme.cardDark : AppColorScheme.cardLight;
    final titleColor = isDark ? AppColorScheme.textPrimaryDark : AppColorScheme.textPrimaryLight;

    return RepaintBoundary(
      child: Card(
        color: cardBgColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isActive ? color.withAlpha(80) : (isDark ? AppColorScheme.borderDark : AppColorScheme.borderLight),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(isDark ? 0.2 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 22,
                      ),
                    ),
                    if (!isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2E3445) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Soon',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFA0A5B5) : Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive ? color : (isDark ? const Color(0xFFA0A5B5) : Colors.grey),
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
