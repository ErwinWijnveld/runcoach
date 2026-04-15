import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/races/providers/race_provider.dart';

class RaceCreateScreen extends ConsumerStatefulWidget {
  const RaceCreateScreen({super.key});

  @override
  ConsumerState<RaceCreateScreen> createState() => _RaceCreateScreenState();
}

class _RaceCreateScreenState extends ConsumerState<RaceCreateScreen> {
  final _nameController = TextEditingController();
  String _distance = '10K';
  DateTime? _raceDate;
  int _goalHours = 0;
  int _goalMinutes = 0;
  String? _error;

  static const _distanceOptions = [
    '5K',
    '10K',
    'half_marathon',
    'marathon',
    'ultra',
    'custom',
  ];

  static const _distanceLabels = {
    '5K': '5K',
    '10K': '10K',
    'half_marathon': 'Half Marathon',
    'marathon': 'Marathon',
    'ultra': 'Ultra Marathon',
    'custom': 'Custom',
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int? _goalTimeSeconds() {
    final total = _goalHours * 3600 + _goalMinutes * 60;
    return total > 0 ? total : null;
  }

  Future<void> _pickDate() async {
    DateTime temp = _raceDate ?? DateTime.now().add(const Duration(days: 60));
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: AppColors.cream,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: temp,
                  minimumDate: DateTime.now(),
                  maximumDate: DateTime.now().add(const Duration(days: 730)),
                  onDateTimeChanged: (d) => temp = d,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    setState(() => _raceDate = temp);
  }

  Future<void> _pickDistance() async {
    int current = _distanceOptions.indexOf(_distance);
    if (current < 0) current = 0;
    await _showPicker(
      itemCount: _distanceOptions.length,
      initialItem: current,
      itemBuilder: (index) =>
          _distanceLabels[_distanceOptions[index]] ?? _distanceOptions[index],
      onSelected: (index) => setState(() => _distance = _distanceOptions[index]),
    );
  }

  Future<void> _pickHours() async {
    await _showPicker(
      itemCount: 13,
      initialItem: _goalHours,
      itemBuilder: (i) => '$i h',
      onSelected: (i) => setState(() => _goalHours = i),
    );
  }

  Future<void> _pickMinutes() async {
    await _showPicker(
      itemCount: 60,
      initialItem: _goalMinutes,
      itemBuilder: (i) => '$i min',
      onSelected: (i) => setState(() => _goalMinutes = i),
    );
  }

  Future<void> _showPicker({
    required int itemCount,
    required int initialItem,
    required String Function(int) itemBuilder,
    required ValueChanged<int> onSelected,
  }) {
    int temp = initialItem;
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: AppColors.cream,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      onPressed: () {
                        onSelected(temp);
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  magnification: 1.15,
                  squeeze: 1.1,
                  useMagnifier: true,
                  itemExtent: 32,
                  scrollController:
                      FixedExtentScrollController(initialItem: initialItem),
                  onSelectedItemChanged: (index) => temp = index,
                  children: List.generate(
                    itemCount,
                    (index) => Center(child: Text(itemBuilder(index))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a race name');
      return;
    }
    if (_raceDate == null) {
      setState(() => _error = 'Please select a race date');
      return;
    }
    setState(() => _error = null);

    final dateStr =
        '${_raceDate!.year}-${_raceDate!.month.toString().padLeft(2, '0')}-${_raceDate!.day.toString().padLeft(2, '0')}';

    await ref.read(raceActionsProvider.notifier).createRace(
          name: name,
          distance: _distance,
          raceDate: dateStr,
          goalTimeSeconds: _goalTimeSeconds(),
        );

    if (mounted) context.go('/races');
  }

  String _formatDate() {
    final d = _raceDate;
    if (d == null) return 'Select date';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatGoal() {
    if (_goalHours == 0 && _goalMinutes == 0) return 'None';
    return '${_goalHours}h ${_goalMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(raceActionsProvider);
    final isLoading = actionState.isLoading;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.cream.withValues(alpha: 0.92),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/races'),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.warmBrown,
          ),
        ),
        middle: const Text('New Race'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Race Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 24),

              const _FieldLabel('Race Name'),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'e.g. Amsterdam Marathon 2026',
                style: const TextStyle(fontSize: 16),
                placeholderStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightTan,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              const SizedBox(height: 20),

              const _FieldLabel('Distance'),
              const SizedBox(height: 8),
              _SelectorField(
                value: _distanceLabels[_distance] ?? _distance,
                onTap: _pickDistance,
              ),
              const SizedBox(height: 20),

              const _FieldLabel('Race Date'),
              const SizedBox(height: 8),
              _SelectorField(
                value: _formatDate(),
                trailingIcon: CupertinoIcons.calendar,
                onTap: _pickDate,
                placeholder: _raceDate == null,
              ),
              const SizedBox(height: 20),

              const _FieldLabel('Goal Time (optional)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SelectorField(
                      value: '$_goalHours h',
                      onTap: _pickHours,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SelectorField(
                      value: '$_goalMinutes min',
                      onTap: _pickMinutes,
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              AppFilledButton(
                label: 'Create Race',
                loading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              if (_goalHours != 0 || _goalMinutes != 0)
                Center(
                  child: Text(
                    'Goal: ${_formatGoal()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SelectorField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  final IconData? trailingIcon;
  final bool placeholder;
  const _SelectorField({
    required this.value,
    required this.onTap,
    this.trailingIcon,
    this.placeholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.lightTan,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: placeholder
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              trailingIcon ?? CupertinoIcons.chevron_down,
              color: AppColors.warmBrown,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
