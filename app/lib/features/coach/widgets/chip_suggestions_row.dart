import 'package:flutter/material.dart';
import 'package:app/core/theme/app_theme.dart';

class ChipSuggestionsRow extends StatefulWidget {
  final List<Map<String, dynamic>> chips;
  final void Function(String label, String value) onTap;

  const ChipSuggestionsRow({
    super.key,
    required this.chips,
    required this.onTap,
  });

  @override
  State<ChipSuggestionsRow> createState() => _ChipSuggestionsRowState();
}

class _ChipSuggestionsRowState extends State<ChipSuggestionsRow> {
  String? _selectedValue;

  @override
  Widget build(BuildContext context) {
    final locked = _selectedValue != null;
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          ...widget.chips.map((c) {
            final label = (c['label'] as String?) ?? '';
            final value = (c['value'] as String?) ?? label;
            final isSelected = _selectedValue == value;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: locked
                  ? null
                  : () {
                      setState(() => _selectedValue = value);
                      widget.onTap(label, value);
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.secondary : AppColors.border,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: locked && !isSelected
                        ? AppColors.textSecondary
                        : Colors.black,
                  ),
                ),
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightTan,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'or type your own',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
