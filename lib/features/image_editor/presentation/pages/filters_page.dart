import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flux_convert/features/image_editor/domain/usecases/apply_filter_use_case.dart';

// IMPROVED: Professional Filters Page with real-time GPU previews & custom controls (Layer 5 Rewrite)
class FiltersPage extends StatefulWidget {
  const FiltersPage({
    required this.imageFile,
    this.initialParams,
    super.key,
  });

  final File imageFile;
  final FilterParams? initialParams;

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage>
    with SingleTickerProviderStateMixin {
  late final ApplyFilterUseCase _useCase;
  late FilterParams _params;

  bool _isComparing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _useCase = ApplyFilterUseCase();
    _params = widget.initialParams ?? const FilterParams();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeFilter = _isComparing
        ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
        : _useCase.buildColorFilter(_params);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Image Filters & Adjustments',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Hold/Tap to Compare Original Button
          GestureDetector(
            onTapDown: (_) => setState(() => _isComparing = true),
            onTapUp: (_) => setState(() => _isComparing = false),
            onTapCancel: () => setState(() => _isComparing = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: _isComparing ? Colors.amber : Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.compare_rounded,
                    size: 16,
                    color: _isComparing ? Colors.black : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isComparing ? 'Original' : 'Compare',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isComparing ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, _params),
            child: const Text('Save'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Main Preview Viewport
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColorFiltered(
                    colorFilter: activeFilter,
                    child: Image.file(
                      widget.imageFile,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Control Panel Bottom Sheet
          DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Presets'),
                    Tab(text: 'Adjustments'),
                  ],
                ),

                SizedBox(
                  height: 190,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Presets & Intensity
                      _buildPresetsTab(context),

                      // Tab 2: Custom Sliders
                      _buildAdjustmentsTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsTab(BuildContext context) {
    return Column(
      children: [
        // Intensity Slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Text('Intensity:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _params.intensity,
                  onChanged: (val) => setState(() => _params = _params.copyWith(intensity: val)),
                ),
              ),
              Text(
                '${(_params.intensity * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),

        // Horizontal Preset Cards Bar
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: FilterParams.presetNames.length,
            itemBuilder: (context, index) {
              final preset = FilterParams.presetNames[index];
              final isSelected = _params.presetName == preset;

              final sampleFilter = _useCase.buildColorFilter(
                FilterParams(presetName: preset),
              );

              return GestureDetector(
                onTap: () => setState(() => _params = _params.copyWith(presetName: preset)),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12, bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: ColorFiltered(
                            colorFilter: sampleFilter,
                            child: Image.file(
                              widget.imageFile,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preset,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustmentsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          _buildSliderRow(
            label: 'Brightness',
            value: _params.brightness,
            min: -100,
            max: 100,
            onChanged: (v) => setState(() => _params = _params.copyWith(brightness: v)),
          ),
          _buildSliderRow(
            label: 'Contrast',
            value: _params.contrast,
            min: 0,
            max: 200,
            onChanged: (v) => setState(() => _params = _params.copyWith(contrast: v)),
          ),
          _buildSliderRow(
            label: 'Saturation',
            value: _params.saturation,
            min: 0,
            max: 200,
            onChanged: (v) => setState(() => _params = _params.copyWith(saturation: v)),
          ),
          _buildSliderRow(
            label: 'Sharpness',
            value: _params.sharpness,
            min: 0,
            max: 100,
            onChanged: (v) => setState(() => _params = _params.copyWith(sharpness: v)),
          ),
          _buildSliderRow(
            label: 'Hue',
            value: _params.hue,
            min: 0,
            max: 360,
            onChanged: (v) => setState(() => _params = _params.copyWith(hue: v)),
          ),
          _buildSliderRow(
            label: 'Blur',
            value: _params.blur,
            min: 0,
            max: 100,
            onChanged: (v) => setState(() => _params = _params.copyWith(blur: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${value.round()}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
