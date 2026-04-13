import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/races/providers/race_provider.dart';

class RaceCreateScreen extends ConsumerStatefulWidget {
  const RaceCreateScreen({super.key});

  @override
  ConsumerState<RaceCreateScreen> createState() => _RaceCreateScreenState();
}

class _RaceCreateScreenState extends ConsumerState<RaceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _distance = '10K';
  DateTime? _raceDate;
  int _goalHours = 0;
  int _goalMinutes = 0;

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
    final picked = await showDatePicker(
      context: context,
      initialDate: _raceDate ?? DateTime.now().add(const Duration(days: 60)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.warmBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _raceDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_raceDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a race date')),
      );
      return;
    }

    final dateStr =
        '${_raceDate!.year}-${_raceDate!.month.toString().padLeft(2, '0')}-${_raceDate!.day.toString().padLeft(2, '0')}';

    await ref.read(raceActionsProvider.notifier).createRace(
      name: _nameController.text.trim(),
      distance: _distance,
      raceDate: dateStr,
      goalTimeSeconds: _goalTimeSeconds(),
    );

    if (mounted) {
      context.go('/races');
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(raceActionsProvider);
    final isLoading = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Race'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/races'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Race Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 24),

              // Name
              Text(
                'Race Name',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Amsterdam Marathon 2026',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a race name' : null,
              ),
              const SizedBox(height: 20),

              // Distance
              Text(
                'Distance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _distance,
                decoration: const InputDecoration(),
                items: _distanceOptions.map((d) {
                  return DropdownMenuItem(
                    value: d,
                    child: Text(_distanceLabels[d] ?? d),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _distance = v);
                },
              ),
              const SizedBox(height: 20),

              // Race date
              Text(
                'Race Date',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.lightTan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _raceDate != null
                              ? '${_raceDate!.day}/${_raceDate!.month}/${_raceDate!.year}'
                              : 'Select date',
                          style: TextStyle(
                            color: _raceDate != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: AppColors.warmBrown, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Goal time
              Text(
                'Goal Time (optional)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _goalHours,
                      decoration: const InputDecoration(
                        hintText: 'Hours',
                      ),
                      items: List.generate(13, (i) {
                        return DropdownMenuItem(
                          value: i,
                          child: Text('$i h'),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) setState(() => _goalHours = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _goalMinutes,
                      decoration: const InputDecoration(
                        hintText: 'Minutes',
                      ),
                      items: List.generate(60, (i) {
                        return DropdownMenuItem(
                          value: i,
                          child: Text('$i min'),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) setState(() => _goalMinutes = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Race'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
