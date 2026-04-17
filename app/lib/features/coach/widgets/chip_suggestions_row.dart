import 'package:flutter/material.dart';
import 'package:app/core/theme/app_theme.dart';

class ChipSuggestionsRow extends StatelessWidget {
  final List<Map<String, dynamic>> chips;
  final void Function(String label, String value) onTap;

  const ChipSuggestionsRow({
    super.key,
    required this.chips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: chips.map((c) {
          final label = (c['label'] as String?) ?? '';
          final value = (c['value'] as String?) ?? label;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(label, value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
