import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/application/workout_controller.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

class WorkoutSetRow extends StatefulWidget {
  const WorkoutSetRow({
    required this.index,
    required this.set,
    required this.reference,
    required this.onChanged,
    required this.onRemove,
    required this.canRemove,
    super.key,
  });

  final int index;
  final WorkoutSetDraft set;
  final GymSet? reference;
  final void Function({String? weight, String? reps}) onChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  State<WorkoutSetRow> createState() => _WorkoutSetRowState();
}

class _WorkoutSetRowState extends State<WorkoutSetRow> {
  late final TextEditingController _weight = TextEditingController(
    text: widget.set.weight,
  );
  late final TextEditingController _reps = TextEditingController(
    text: widget.set.reps,
  );

  @override
  void didUpdateWidget(covariant WorkoutSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(_weight, widget.set.weight);
    _sync(_reps, widget.set.reps);
  }

  void _sync(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference = widget.reference;
    final inputStyle = theme.textTheme.bodyLarge?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w600,
    );
    return Semantics(
      label: 'Set ${widget.index + 1}',
      container: true,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${widget.index + 1}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: TextField(
                key: ValueKey('weight-${widget.index}'),
                controller: _weight,
                style: inputStyle,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: reference?.weight == null
                      ? '—'
                      : formatGymNumber(reference!.weight!),
                  semanticCounterText: 'Weight in kilograms',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: LuqaSpacing.md,
                    vertical: LuqaSpacing.md,
                  ),
                ),
                onChanged: (value) => widget.onChanged(weight: value),
              ),
            ),
            const SizedBox(width: LuqaSpacing.sm),
            Expanded(
              child: TextField(
                key: ValueKey('reps-${widget.index}'),
                controller: _reps,
                style: inputStyle,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: reference?.reps?.toString() ?? '—',
                  semanticCounterText: 'Repetitions',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: LuqaSpacing.md,
                    vertical: LuqaSpacing.md,
                  ),
                ),
                onChanged: (value) => widget.onChanged(reps: value),
              ),
            ),
            SizedBox(
              width: 48,
              child: IconButton(
                tooltip: 'Remove set ${widget.index + 1}',
                onPressed: widget.canRemove ? widget.onRemove : null,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
