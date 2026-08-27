import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/today/application/today_controller.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa/features/today/presentation/category_picker_sheet.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';

Future<bool> showLogTimeSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) =>
        const FractionallySizedBox(heightFactor: 0.88, child: LogTimeSheet()),
  );
  return result ?? false;
}

class LogTimeSheet extends ConsumerStatefulWidget {
  const LogTimeSheet({super.key});

  @override
  ConsumerState<LogTimeSheet> createState() => _LogTimeSheetState();
}

class _LogTimeSheetState extends ConsumerState<LogTimeSheet> {
  late final TextEditingController _descriptionController;
  late DateTime _day;
  late TimeOfDay _start;
  late TimeOfDay _end;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController()..addListener(_redraw);
    final state = ref.read(todayControllerProvider);
    _day = state.day;
    final range = _inferRange(
      state.entries,
      state.day,
      ref.read(currentTimeProvider),
    );
    _start = TimeOfDay.fromDateTime(range.$1);
    _end = TimeOfDay.fromDateTime(range.$2);
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _descriptionController
      ..removeListener(_redraw)
      ..dispose();
    super.dispose();
  }

  (DateTime, DateTime) _inferRange(
    List<TimeEntry> entries,
    DateTime day,
    DateTime now,
  ) {
    final end = DateTime(day.year, day.month, day.day, now.hour, now.minute);
    final snappedEnd = _snap(end);
    final completed = [...entries]..sort((a, b) => a.end.compareTo(b.end));
    final latestEnd = completed.isEmpty ? null : completed.last.end;
    final gap = latestEnd == null ? null : snappedEnd.difference(latestEnd);
    final plausibleGap =
        gap != null &&
        !gap.isNegative &&
        gap > Duration.zero &&
        gap <= const Duration(hours: 3);
    final start = plausibleGap
        ? latestEnd!
        : snappedEnd.subtract(const Duration(minutes: 30));
    return (start, snappedEnd);
  }

  DateTime _snap(DateTime value) {
    final minute = (value.minute / 5).round() * 5;
    final base = DateTime(value.year, value.month, value.day, value.hour);
    return base.add(Duration(minutes: minute));
  }

  DateTime _dateFor(TimeOfDay value) =>
      DateTime(_day.year, _day.month, _day.day, value.hour, value.minute);

  Duration get _duration => _dateFor(_end).difference(_dateFor(_start));

  Category? _selectedCategory(List<Category> categories) {
    for (final category in categories) {
      if (category.id == _categoryId) return category;
    }
    return null;
  }

  Future<void> _pickCategory() async {
    final selection = await showCategoryPickerSheet(
      context,
      selectedId: _categoryId,
    );
    if (!mounted || selection == null) return;
    setState(() => _categoryId = selection.categoryId);
  }

  Future<void> _pickTime({required bool start}) async {
    final current = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: start ? 'Choose start time' : 'Choose end time',
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _applyRecent(RecentActivity recent) {
    setState(() {
      _descriptionController.text = recent.description;
      _descriptionController.selection = TextSelection.collapsed(
        offset: recent.description.length,
      );
      _categoryId = recent.categoryId;
    });
  }

  Future<void> _save() async {
    if (_duration.isNegative || _duration == Duration.zero) return;
    final saved = await ref
        .read(todayControllerProvider.notifier)
        .addEntry(
          NewTimeEntry(
            description: _descriptionController.text.trim(),
            categoryId: _categoryId,
            start: _dateFor(_start),
            end: _dateFor(_end),
          ),
        );
    if (!mounted || !saved) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayControllerProvider);
    final theme = Theme.of(context);
    final category = _selectedCategory(state.categories);
    final validRange = !_duration.isNegative && _duration != Duration.zero;
    final untitled =
        _descriptionController.text.trim().isEmpty && _categoryId == null;
    final showCounter = _descriptionController.text.length >= 450;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: LuqaMotion.state,
      curve: LuqaMotion.curve,
      padding: EdgeInsets.only(bottom: math.max(0, viewInsets.bottom)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Log time', style: theme.textTheme.titleLarge),
                      const SizedBox(height: LuqaSpacing.xs),
                      Text(
                        'Today · ${fullDate(_day)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: state.isSaving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                TextField(
                  key: const ValueKey('description-field'),
                  controller: _descriptionController,
                  maxLength: 500,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'What did you do?',
                    hintText: 'Describe the activity',
                    counterText: showCounter
                        ? '${_descriptionController.text.length}/500'
                        : '',
                  ),
                ),
                const SizedBox(height: LuqaSpacing.md),
                _CategoryField(category: category, onTap: _pickCategory),
                const SizedBox(height: LuqaSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        label: 'Start',
                        value: _start,
                        onTap: () => _pickTime(start: true),
                      ),
                    ),
                    const SizedBox(width: LuqaSpacing.md),
                    Expanded(
                      child: _TimeField(
                        label: 'End',
                        value: _end,
                        onTap: () => _pickTime(start: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LuqaSpacing.sm),
                AnimatedSwitcher(
                  duration: LuqaMotion.state,
                  child: validRange
                      ? Center(
                          key: const ValueKey('duration'),
                          child: Text(
                            compactDuration(_duration),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        )
                      : Text(
                          'End must be after Start.',
                          key: const ValueKey('time-error'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                ),
                const SizedBox(height: LuqaSpacing.xl),
                Text('Recent', style: theme.textTheme.labelLarge),
                const SizedBox(height: LuqaSpacing.xs),
                for (final recent in state.recentActivities)
                  _RecentActivityRow(
                    recent: recent,
                    category: _selectedFor(recent, state.categories),
                    onTap: () => _applyRecent(recent),
                  ),
                if (state.error != null) ...[
                  const SizedBox(height: LuqaSpacing.md),
                  Text(
                    state.error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('add-entry-button'),
                onPressed: validRange && !state.isSaving ? _save : null,
                child: Text(
                  state.isSaving
                      ? 'Adding…'
                      : untitled
                      ? 'Add untitled entry'
                      : 'Add entry',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Category? _selectedFor(RecentActivity recent, List<Category> categories) {
    for (final category in categories) {
      if (category.id == recent.categoryId) return category;
    }
    return null;
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.category, required this.onTap});

  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: category == null
          ? 'Choose category'
          : 'Category ${category!.name}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Category'),
          child: Row(
            children: [
              if (category != null) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(category!.colorValue),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 12),
                ),
                const SizedBox(width: LuqaSpacing.md),
              ] else ...[
                Icon(
                  Icons.label_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: LuqaSpacing.md),
              ],
              Expanded(child: Text(category?.name ?? 'No category')),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label ${value.format(context)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(
            value.format(context),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({
    required this.recent,
    required this.category,
    required this.onTap,
  });

  final RecentActivity recent;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      minTileHeight: 52,
      contentPadding: EdgeInsets.zero,
      shape: const Border(bottom: BorderSide(width: 0)),
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: category == null
              ? theme.colorScheme.onSurfaceVariant
              : Color(category!.colorValue),
          shape: BoxShape.circle,
        ),
        child: const SizedBox.square(dimension: 10),
      ),
      title: Text(recent.description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (category != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                category!.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(width: LuqaSpacing.xs),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );
  }
}
