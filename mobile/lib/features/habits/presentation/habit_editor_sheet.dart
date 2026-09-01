import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/habits/application/habits_controller.dart';
import 'package:luqa/features/habits/data/habits_repository.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_schedule.dart';
import 'package:luqa/features/habits/presentation/habit_formatters.dart';
import 'package:luqa/features/habits/presentation/habit_icons.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_glyph.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_pickers.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';

/// Making a habit, or changing one.
///
/// [habit] null means a new one. Returns true once the device has recorded the
/// change, which is immediately.
Future<bool?> showHabitEditorSheet(BuildContext context, {Habit? habit}) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _HabitEditorSheet(habit: habit),
    ),
  );
}

class _HabitEditorSheet extends ConsumerStatefulWidget {
  const _HabitEditorSheet({required this.habit});

  final Habit? habit;

  @override
  ConsumerState<_HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends ConsumerState<_HabitEditorSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.habit?.name ?? '',
  );

  late String _icon = widget.habit?.icon ?? defaultHabitIcon;
  late int _colorValue = widget.habit?.colorValue ?? defaultHabitColorValue;
  late HabitGoalType _goalType = widget.habit?.goalType ?? HabitGoalType.task;
  late HabitGoalPeriod _goalPeriod =
      widget.habit?.goalPeriod ?? HabitGoalPeriod.day;
  late int _targetCount = widget.habit?.targetCount ?? 3;
  late int _targetMinutes = ((widget.habit?.targetSeconds ?? 1800) / 60).round();
  late String? _categoryId = widget.habit?.categoryId;
  late HabitScheduleType _scheduleType =
      widget.habit?.scheduleType ?? HabitScheduleType.daily;
  late List<int> _weekdays = [...?widget.habit?.weekdays];
  late int _weekInterval = widget.habit?.weekInterval ?? 1;
  late int _intervalDays = widget.habit?.intervalDays ?? 2;
  late bool _intervalFromLastDone = widget.habit?.intervalFromLastDone ?? false;
  late int _timesPerPeriod = widget.habit?.timesPerPeriod ?? 3;

  bool _saving = false;

  bool get _isEdit => widget.habit != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// The habit as it would be, for the preview at the top of the sheet.
  Habit get _preview => Habit(
    id: widget.habit?.id ?? 'preview',
    name: _name.text.trim(),
    icon: _icon,
    colorValue: _colorValue,
    order: widget.habit?.order ?? 0,
    goalType: _goalType,
    goalPeriod: _goalPeriod,
    targetCount: _targetCount,
    targetSeconds: _targetMinutes * 60,
    categoryId: _categoryId,
    scheduleType: _scheduleType,
    weekdays: _weekdays,
    weekInterval: _weekInterval,
    intervalDays: _intervalDays,
    intervalFromLastDone: _intervalFromLastDone,
    timesPerPeriod: _timesPerPeriod,
    anchorDate: widget.habit?.anchorDate,
    dates: widget.habit?.dates ?? const [],
    excludedDates: widget.habit?.excludedDates ?? const [],
    archived: false,
    createdAt: widget.habit?.createdAt ?? DateTime.now(),
  );

  bool get _canSave {
    if (_name.text.trim().isEmpty) return false;
    // A weekly habit with no days chosen would never come round again, which
    // is not a habit anyone means to make.
    if (_scheduleType == HabitScheduleType.weekdays && _weekdays.isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final controller = ref.read(habitsControllerProvider.notifier);
    final existing = widget.habit;
    final preview = _preview;

    if (existing == null) {
      final created = await controller.createHabit(
        HabitDraft(
          name: preview.name,
          icon: preview.icon,
          colorValue: preview.colorValue,
          goalType: preview.goalType,
          goalPeriod: preview.goalPeriod,
          targetCount: preview.targetCount,
          targetSeconds: preview.targetSeconds,
          categoryId: preview.categoryId,
          scheduleType: preview.scheduleType,
          weekdays: preview.weekdays,
          weekInterval: preview.weekInterval,
          intervalDays: preview.intervalDays,
          intervalFromLastDone: preview.intervalFromLastDone,
          timesPerPeriod: preview.timesPerPeriod,
          anchorDate: preview.anchorDate,
          dates: preview.dates,
          excludedDates: preview.excludedDates,
        ),
      );
      if (!mounted) return;
      if (created == null) {
        setState(() => _saving = false);
        return;
      }
      Navigator.of(context).pop(true);
      return;
    }

    await controller.saveHabit(
      existing.copyWith(
        name: preview.name,
        icon: () => preview.icon,
        colorValue: preview.colorValue,
        goalType: preview.goalType,
        // A period target and a category link only mean anything on a duration
        // goal; switching away from one takes both with it rather than leaving
        // settings nothing reads.
        goalPeriod: _goalType == HabitGoalType.time
            ? preview.goalPeriod
            : HabitGoalPeriod.day,
        targetCount: preview.targetCount,
        targetSeconds: preview.targetSeconds,
        categoryId: () =>
            _goalType == HabitGoalType.time ? preview.categoryId : null,
        scheduleType: preview.scheduleType,
        weekdays: preview.weekdays,
        weekInterval: preview.weekInterval,
        intervalDays: preview.intervalDays,
        intervalFromLastDone: preview.intervalFromLastDone,
        timesPerPeriod: preview.timesPerPeriod,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _archive() async {
    final habit = widget.habit;
    if (habit == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Archive ${habit.name}?'),
        content: const Text(
          'It stops appearing on Today. Everything you have already logged '
          'against it is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(habitsControllerProvider.notifier).archiveHabit(habit.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekStartsOn = ref.watch(habitsControllerProvider).weekStartsOn;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          LuqaSpacing.lg,
          0,
          LuqaSpacing.lg,
          LuqaSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HabitGlyph(habit: _preview),
                const SizedBox(width: LuqaSpacing.md),
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit habit' : 'New habit',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (_isEdit)
                  IconButton(
                    key: const ValueKey('habit-archive'),
                    tooltip: 'Archive habit',
                    onPressed: _archive,
                    icon: const Icon(Icons.archive_outlined, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: LuqaSpacing.lg),
            TextField(
              key: const ValueKey('habit-name'),
              controller: _name,
              autofocus: !_isEdit,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Read, stretch, no phone after 22:00',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: LuqaSpacing.xl),
            const FieldLabel('Goal'),
            const SizedBox(height: LuqaSpacing.sm),
            HabitSegmented<HabitGoalType>(
              values: HabitGoalType.values,
              selected: _goalType,
              labelOf: (value) => switch (value) {
                HabitGoalType.task => 'Done',
                HabitGoalType.count => 'Count',
                HabitGoalType.time => 'Time',
              },
              onChanged: (value) => setState(() => _goalType = value),
            ),
            ..._goalFields(),

            const SizedBox(height: LuqaSpacing.xl),
            const FieldLabel('Repeats'),
            const SizedBox(height: LuqaSpacing.sm),
            HabitSegmented<HabitScheduleType>(
              values: const [
                HabitScheduleType.daily,
                HabitScheduleType.weekdays,
                HabitScheduleType.interval,
                HabitScheduleType.timesPerWeek,
              ],
              selected: _visibleSchedule,
              labelOf: (value) => switch (value) {
                HabitScheduleType.daily => 'Daily',
                HabitScheduleType.weekdays => 'Days',
                HabitScheduleType.interval => 'Every N',
                _ => 'Quota',
              },
              onChanged: (value) => setState(() => _scheduleType = value),
            ),
            ..._scheduleFields(weekStartsOn),

            const SizedBox(height: LuqaSpacing.lg),
            Text(
              scheduleSummary(_preview),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: LuqaSpacing.xl),
            const FieldLabel('Looks like'),
            const SizedBox(height: LuqaSpacing.sm),
            HabitAppearancePicker(
              icon: _icon,
              colorValue: _colorValue,
              onIconChanged: (value) => setState(() => _icon = value),
              onColorChanged: (value) => setState(() => _colorValue = value),
            ),

            const SizedBox(height: LuqaSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('habit-save'),
                onPressed: _canSave && !_saving ? _save : null,
                child: Text(_isEdit ? 'Save habit' : 'Add habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The quota schedules share one segment; which period it means is chosen
  /// underneath rather than by adding three more buttons to a row of four.
  HabitScheduleType get _visibleSchedule =>
      _scheduleType.isPeriodQuota ? HabitScheduleType.timesPerWeek : _scheduleType;

  List<Widget> _goalFields() {
    switch (_goalType) {
      case HabitGoalType.task:
        return const [];

      case HabitGoalType.count:
        return [
          const SizedBox(height: LuqaSpacing.md),
          HabitStepper(
            value: _targetCount,
            label: '$_targetCount× a day',
            max: 1000,
            onChanged: (value) => setState(() => _targetCount = value),
          ),
        ];

      case HabitGoalType.time:
        return [
          const SizedBox(height: LuqaSpacing.md),
          HabitStepper(
            value: _targetMinutes,
            label: habitDuration(_targetMinutes * 60),
            min: 5,
            max: 24 * 60,
            step: 5,
            onChanged: (value) => setState(() => _targetMinutes = value),
          ),
          const SizedBox(height: LuqaSpacing.md),
          HabitSegmented<HabitGoalPeriod>(
            values: HabitGoalPeriod.values,
            selected: _goalPeriod,
            labelOf: (value) => switch (value) {
              HabitGoalPeriod.day => 'Per day',
              HabitGoalPeriod.week => 'Per week',
              HabitGoalPeriod.month => 'Per month',
            },
            onChanged: (value) => setState(() => _goalPeriod = value),
          ),
          const SizedBox(height: LuqaSpacing.lg),
          const FieldLabel('Counts time tracked on'),
          const SizedBox(height: LuqaSpacing.sm),
          _CategoryLink(
            categoryId: _categoryId,
            onChanged: (value) => setState(() => _categoryId = value),
          ),
        ];
    }
  }

  List<Widget> _scheduleFields(int weekStartsOn) {
    switch (_scheduleType) {
      case HabitScheduleType.daily:
      case HabitScheduleType.dates:
        return const [];

      case HabitScheduleType.weekdays:
        return [
          const SizedBox(height: LuqaSpacing.md),
          WeekdayPicker(
            selected: _weekdays,
            weekStartsOn: weekStartsOn,
            onChanged: (value) => setState(() => _weekdays = value),
          ),
          const SizedBox(height: LuqaSpacing.md),
          HabitStepper(
            value: _weekInterval,
            label: _weekInterval == 1
                ? 'Every week'
                : 'Every $_weekInterval weeks',
            max: 12,
            onChanged: (value) => setState(() => _weekInterval = value),
          ),
        ];

      case HabitScheduleType.interval:
        return [
          const SizedBox(height: LuqaSpacing.md),
          HabitStepper(
            value: _intervalDays,
            label: _intervalDays == 1
                ? 'Every day'
                : 'Every $_intervalDays days',
            max: 365,
            onChanged: (value) => setState(() => _intervalDays = value),
          ),
          // Only a real choice once there is a gap to count: "every day" means
          // the same thing whichever end it is counted from.
          if (_intervalDays > 1) ...[
            const SizedBox(height: LuqaSpacing.md),
            HabitSegmented<bool>(
              values: const [false, true],
              selected: _intervalFromLastDone,
              labelOf: (rolling) =>
                  rolling ? 'From the last time' : 'Fixed days',
              onChanged: (value) =>
                  setState(() => _intervalFromLastDone = value),
            ),
            const SizedBox(height: LuqaSpacing.sm),
            _Hint(
              _intervalFromLastDone
                  ? 'Due again $_intervalDays days after each time you do it. '
                        'Miss one and the whole cycle shifts along.'
                  : 'Every $_intervalDays days from the start date, whether '
                        'or not you kept up.',
            ),
          ],
        ];

      case HabitScheduleType.timesPerWeek:
      case HabitScheduleType.timesPerMonth:
      case HabitScheduleType.timesPerYear:
        return [
          const SizedBox(height: LuqaSpacing.md),
          HabitSegmented<HabitScheduleType>(
            values: const [
              HabitScheduleType.timesPerWeek,
              HabitScheduleType.timesPerMonth,
              HabitScheduleType.timesPerYear,
            ],
            selected: _scheduleType,
            labelOf: (value) => switch (value) {
              HabitScheduleType.timesPerMonth => 'A month',
              HabitScheduleType.timesPerYear => 'A year',
              _ => 'A week',
            },
            onChanged: (value) => setState(() => _scheduleType = value),
          ),
          const SizedBox(height: LuqaSpacing.md),
          HabitStepper(
            value: _timesPerPeriod,
            label: '$_timesPerPeriod× ${switch (_scheduleType) {
              HabitScheduleType.timesPerMonth => 'a month',
              HabitScheduleType.timesPerYear => 'a year',
              _ => 'a week',
            }}',
            max: 366,
            onChanged: (value) => setState(() => _timesPerPeriod = value),
          ),
        ];
    }
  }
}

/// A sentence explaining what the choice above it will do.
class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 12,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Which tracking category a duration habit reads its progress from.
///
/// Optional on purpose: a habit with no link keeps its own timer, and one with
/// a link has no timer of its own at all — the time tracked on that category
/// *is* the progress, so the two can never disagree.
class _CategoryLink extends ConsumerWidget {
  const _CategoryLink({required this.categoryId, required this.onChanged});

  final String? categoryId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(timelineControllerProvider).categories;

    return Wrap(
      spacing: LuqaSpacing.sm,
      runSpacing: LuqaSpacing.sm,
      children: [
        _CategoryChip(
          label: 'Its own timer',
          colorValue: null,
          selected: categoryId == null,
          onTap: () => onChanged(null),
        ),
        for (final category in categories)
          _CategoryChip(
            label: category.name,
            colorValue: category.colorValue,
            selected: category.id == categoryId,
            onTap: () => onChanged(category.id),
          ),
        if (categories.isEmpty)
          Text(
            'Categories you track time against will show up here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.colorValue,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? colorValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuqaRadii.control),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: LuqaSpacing.md),
          decoration: BoxDecoration(
            color: selected ? palette.raised : Colors.transparent,
            border: Border.all(
              color: selected ? theme.colorScheme.primary : palette.border,
            ),
            borderRadius: BorderRadius.circular(LuqaRadii.control),
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (colorValue != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(colorValue!),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: LuqaSpacing.sm),
                ],
                Text(label, style: theme.textTheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
