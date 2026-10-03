import 'package:flutter/material.dart';

import 'package:flux_convert/core/constants/app_border_radius.dart';
import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/constants/app_icons.dart';
import 'package:flux_convert/core/theme/app_colors.dart';
import 'package:flux_convert/core/theme/app_text_styles.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// InputField — Styled Text Input Container
/// ─────────────────────────────────────────────────────────────────────────────
class InputField extends StatefulWidget {
  const InputField({
    required this.hintText,
    this.controller,
    this.labelText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.onChanged,
    this.validator,
    super.key,
  });

  final String hintText;
  final TextEditingController? controller;
  final String? labelText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(widget.labelText!, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
          AppDimensions.h6,
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          onChanged: widget.onChanged,
          validator: widget.validator,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, size: 20) : null,
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: _isFocused
                ? AppColorScheme.background
                : AppColorScheme.surface,
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppBorderRadius.radiusMd,
              borderSide: BorderSide(color: AppColorScheme.primaryBlueStart, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.radiusMd,
              borderSide: BorderSide(
                color: hasError ? AppColorScheme.danger : AppColorScheme.border,
                width: 1.2,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          AppDimensions.h4,
          Text(widget.errorText!, style: AppTextStyles.error),
        ],
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SearchBox — Unified Text Search Container
/// ─────────────────────────────────────────────────────────────────────────────
class SearchBox extends StatelessWidget {
  const SearchBox({
    required this.hintText,
    this.controller,
    this.onChanged,
    super.key,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => InputField(
      hintText: hintText,
      controller: controller,
      onChanged: onChanged,
      prefixIcon: AppIcons.search,
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// DropdownField — Reusable Selection Menu
/// ─────────────────────────────────────────────────────────────────────────────
class DropdownField<T> extends StatelessWidget {
  const DropdownField({
    required this.items,
    required this.onChanged,
    required this.hintText,
    this.value,
    this.labelText,
    super.key,
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hintText;
  final T? value;
  final String? labelText;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(labelText!, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
          AppDimensions.h6,
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(AppIcons.dropdown),
          style: AppTextStyles.body,
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColorScheme.surface,
          ),
        ),
      ],
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// FormatSelector — Selection Bar for Converted Types
/// ─────────────────────────────────────────────────────────────────────────────
class FormatSelector extends StatelessWidget {
  const FormatSelector({
    required this.formats,
    required this.selectedFormat,
    required this.onSelected,
    super.key,
  });

  final List<String> formats;
  final String? selectedFormat;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: formats.map((format) {
          final isSelected = selectedFormat == format;
          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.s8),
            child: ChoiceChip(
              label: Text(format.toUpperCase()),
              selected: isSelected,
              onSelected: (_) => onSelected(format),
              selectedColor: AppColorScheme.primaryBlueStart,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColorScheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: AppBorderRadius.radiusFull,
              ),
            ),
          );
        }).toList(),
      ),
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// UploadArea — Drag & Drop Visual zone mockup
/// ─────────────────────────────────────────────────────────────────────────────
class UploadArea extends StatelessWidget {
  const UploadArea({
    required this.onTap,
    this.isDragging = false,
    super.key,
  });

  final VoidCallback onTap;
  final bool isDragging;

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: isDragging ? AppColorScheme.primaryBlueStart.withAlpha(15) : AppColorScheme.surface,
        borderRadius: AppBorderRadius.radiusLg,
        border: Border.all(
          color: isDragging ? AppColorScheme.primaryBlueStart : AppColorScheme.border,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.s12),
                decoration: BoxDecoration(
                  color: AppColorScheme.primaryBlueStart.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.upload, size: 36, color: AppColorScheme.primaryBlueStart),
              ),
              AppDimensions.h12,
              Text(
                'Tap to Upload File',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              AppDimensions.h4,
              Text(
                'Max upload size limit: 100 MB',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
}
