import 'package:flutter/material.dart';

import 'package:flux_convert/core/core.dart';

class AspectRatioOption {
  const AspectRatioOption({
    required this.label,
    required this.ratio,
    required this.icon,
  });

  final String label;
  final double? ratio; // null for Free crop
  final IconData icon;

  static const List<AspectRatioOption> presets = [
    AspectRatioOption(label: 'Free', ratio: null, icon: Icons.crop_free_rounded),
    AspectRatioOption(label: '1:1', ratio: 1.0, icon: Icons.crop_square_rounded),
    AspectRatioOption(label: '4:3', ratio: 4 / 3, icon: Icons.crop_5_4_rounded),
    AspectRatioOption(label: '16:9', ratio: 16 / 9, icon: Icons.crop_16_9_rounded),
    AspectRatioOption(label: '3:2', ratio: 3 / 2, icon: Icons.crop_3_2_rounded),
    AspectRatioOption(label: '2:3', ratio: 2 / 3, icon: Icons.crop_portrait_rounded),
    AspectRatioOption(label: '3:4', ratio: 3 / 4, icon: Icons.crop_portrait_rounded),
  ];
}

// FIXED: High-Contrast Aspect Ratio selection bar widget with visible Custom Chip
class AspectRatioSelector extends StatelessWidget {
  const AspectRatioSelector({
    required this.selectedRatio,
    required this.onRatioSelected,
    super.key,
  });

  final double? selectedRatio;
  final ValueChanged<double?> onRatioSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AspectRatioOption.presets.length + 1, // +1 for Custom button
        itemBuilder: (context, index) {
          if (index < AspectRatioOption.presets.length) {
            final option = AspectRatioOption.presets[index];
            final isSelected = (option.ratio == null && selectedRatio == null) ||
                (option.ratio != null &&
                    selectedRatio != null &&
                    (option.ratio! - selectedRatio!).abs() < 0.01);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      option.icon,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(option.label),
                  ],
                ),
                selected: isSelected,
                selectedColor: AppColorScheme.primaryBlueStart,
                backgroundColor: const Color(0xFF2A2F3D),
                side: BorderSide(
                  color: isSelected ? AppColorScheme.primaryBlueStart : const Color(0xFF3E4558),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (_) => onRatioSelected(option.ratio),
              ),
            );
          }

          // Custom Aspect Ratio Option
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: const Color(0xFF2A2F3D),
              side: const BorderSide(color: AppColorScheme.primaryBlueStart),
              avatar: const Icon(Icons.edit_note_rounded, size: 18, color: AppColorScheme.primaryBlueStart),
              label: const Text(
                'Custom',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              onPressed: () => _showCustomRatioDialog(context),
            ),
          );
        },
      ),
    );
  }

  void _showCustomRatioDialog(BuildContext context) {
    final widthController = TextEditingController();
    final heightController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Custom Aspect Ratio'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widthController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Width',
                  hintText: 'e.g. 5',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: TextField(
                controller: heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Height',
                  hintText: 'e.g. 4',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryBlueStart,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final w = double.tryParse(widthController.text.trim());
              final h = double.tryParse(heightController.text.trim());
              if (w != null && h != null && w > 0 && h > 0) {
                onRatioSelected(w / h);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
