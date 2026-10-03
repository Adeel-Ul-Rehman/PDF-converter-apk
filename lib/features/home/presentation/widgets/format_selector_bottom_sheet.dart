import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:flux_convert/features/conversion/core/adapters/format_converter_registry.dart';

class FormatSelectorBottomSheet extends ConsumerStatefulWidget {
  const FormatSelectorBottomSheet({super.key});

  @override
  ConsumerState<FormatSelectorBottomSheet> createState() => _FormatSelectorBottomSheetState();
}

class _FormatSelectorBottomSheetState extends ConsumerState<FormatSelectorBottomSheet> {
  // Available input format options
  final List<Map<String, dynamic>> _inputOptions = [
    {'label': 'PDF', 'format': ConversionFormat.pdf, 'extensions': ['pdf']},
    {'label': 'Image', 'format': ConversionFormat.png, 'extensions': ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif', 'tiff']},
    {'label': 'Word (DOCX)', 'format': ConversionFormat.docx, 'extensions': ['docx', 'doc']},
    {'label': 'Excel (XLSX)', 'format': ConversionFormat.xlsx, 'extensions': ['xlsx', 'xls', 'csv', 'ods']},
    {'label': 'Presentation (PPTX)', 'format': ConversionFormat.pptx, 'extensions': ['pptx', 'ppt']},
    {'label': 'Text (TXT)', 'format': ConversionFormat.txt, 'extensions': ['txt', 'rtf', 'odt']},
    {'label': 'HTML', 'format': ConversionFormat.html, 'extensions': ['html']},
  ];

  Map<String, dynamic>? _selectedInput;
  ConversionFormat? _selectedOutput;

  List<ConversionFormat> get _compatibleOutputs {
    if (_selectedInput == null) return [];
    
    final inputFormat = _selectedInput!['format'] as ConversionFormat;
    final sourceExt = inputFormat.name.toLowerCase();

    return ConversionFormat.values.where((format) {
      if (format == inputFormat) return false;
      final targetExt = format.name.toLowerCase();
      
      // Look up conversions in format converter registry
      final converters = FormatConverterRegistry.findByMapping(sourceExt, targetExt);
      return converters.isNotEmpty;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Default select PDF
    _selectedInput = _inputOptions.first;
  }

  Future<void> _handleConfirm() async {
    if (_selectedInput == null || _selectedOutput == null) {
      AppPopups.showSnackBar(
        context: context,
        message: 'Please choose both Input and Output formats.',
      );
      return;
    }

    final extensions = _selectedInput!['extensions'] as List<String>;
    final inputLabel = _selectedInput!['label'] as String;

    if (inputLabel == 'Image' && _selectedOutput == ConversionFormat.pdf) {
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        context.push(AppRoutes.imageSelection);
      }
      return;
    }

    final allowMultiple = (inputLabel == 'Image' && _selectedOutput == ConversionFormat.pdf) ||
                          (inputLabel == 'PDF' && _selectedOutput == ConversionFormat.pdf);

    final notifier = ref.read(converterNotifierProvider.notifier);

    // Trigger file selection with target extensions and multi-selection mode
    await notifier.selectFile(
      allowedExtensions: extensions,
      allowMultiple: allowMultiple,
    );

    final state = ref.read(converterNotifierProvider);
    if (state.selectedFilePath != null) {
      // Programmatically sync target output formats
      notifier.selectOutputFormat(_selectedOutput!);

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        context.go(AppRoutes.converter); // Jump to converter screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final outputs = _compatibleOutputs;

    // Reset output format choice if it is not in the new output list
    if (_selectedOutput != null && !outputs.contains(_selectedOutput)) {
      _selectedOutput = null;
    }

    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.bottomSheetTheme.backgroundColor ?? theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header indicator bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'New Conversion',
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),

              // Selection Layout Row
              Row(
                children: [
                  // Input Format Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'From Format',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, dynamic>>(
                              value: _selectedInput,
                              isExpanded: true,
                              items: _inputOptions.map((opt) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: opt,
                                  child: Text(
                                    opt['label'] as String,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedInput = val;
                                  _selectedOutput = null; // Reset output on change
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // To Arrow Indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),

                  // Output Format Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'To Format',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ConversionFormat>(
                              value: _selectedOutput,
                              isExpanded: true,
                              hint: const Text(
                                'Select',
                                style: TextStyle(fontSize: 14),
                              ),
                              items: outputs.map((fmt) {
                                return DropdownMenuItem<ConversionFormat>(
                                  value: fmt,
                                  child: Text(
                                    fmt.displayName,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedOutput = val;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Action Trigger Button
              ElevatedButton(
                onPressed: _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open_rounded),
                    SizedBox(width: 8),
                    Text(
                      'Choose File to Convert',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
