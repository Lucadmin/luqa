import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/application/people_names.dart';
import 'package:luqa/features/today/presentation/category_picker_sheet.dart';
import 'package:luqa/features/today/presentation/person_picker_sheet.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';

/// What the sheet hands back. `delete` is the only outcome that is not a save.
class EntryEdit {
  const EntryEdit({
    required this.description,
    required this.categoryId,
    required this.start,
    required this.end,
    this.personIds = const [],
    this.delete = false,
  });

  const EntryEdit.deleted()
    : description = '',
      categoryId = null,
      start = null,
      end = null,
      personIds = const [],
      delete = true;

  final String description;
  final String? categoryId;
  final DateTime? start;
  final DateTime? end;

  /// Who was there, complete. The write replaces the tags wholesale.
  final List<String> personIds;

  final bool delete;
}

Future<EntryEdit?> showEntryEditorSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String? categoryId,
  required DateTime start,
  required DateTime end,
  required bool canDelete,
  List<String> personIds = const [],
}) {
  return showModalBottomSheet<EntryEdit>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _EntryEditorSheet(
        title: title,
        description: description,
        categoryId: categoryId,
        start: start,
        end: end,
        canDelete: canDelete,
        personIds: personIds,
      ),
    ),
  );
}

class _EntryEditorSheet extends ConsumerStatefulWidget {
  const _EntryEditorSheet({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.start,
    required this.end,
    required this.canDelete,
    required this.personIds,
  });

  final String title;
  final String description;
  final String? categoryId;
  final DateTime start;
  final DateTime end;
  final bool canDelete;
  final List<String> personIds;

  @override
  ConsumerState<_EntryEditorSheet> createState() => _EntryEditorSheetState();
}

class _EntryEditorSheetState extends ConsumerState<_EntryEditorSheet> {
  late final TextEditingController _description = TextEditingController(
    text: widget.description,
  );
  late DateTime _start = widget.start;
  late DateTime _end = widget.end;
  late String? _categoryId = widget.categoryId;
  late List<String> _personIds = [...widget.personIds];

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Duration get _duration => _end.difference(_start);

  String _peopleLabel(WidgetRef ref) {
    if (_personIds.isEmpty) return 'Nobody tagged';
    return ref.read(personNamesProvider)(_personIds);
  }

  bool get _crossesMidnight => _end.day != _start.day;

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: isStart ? 'Start time' : 'End time',
    );
    if (!mounted || picked == null) return;

    setState(() {
      if (isStart) {
        final length = _duration;
        _start = DateTime(
          _start.year,
          _start.month,
          _start.day,
          picked.hour,
          picked.minute,
        );
        // Moving the start drags the block rather than stretching it, which
        // is what "I started later than I thought" almost always means.
        _end = _start.add(length);
      } else {
        var next = DateTime(
          _start.year,
          _start.month,
          _start.day,
          picked.hour,
          picked.minute,
        );
        // An end at or before the start reads as the small hours of the
        // following day, the way a late session actually runs.
        if (!next.isAfter(_start)) next = next.add(const Duration(days: 1));
        _end = next;
      }
    });
  }

  Future<void> _pickCategory() async {
    final selection = await showCategoryPickerSheet(
      context,
      selectedId: _categoryId,
    );
    if (!mounted || selection == null) return;
    setState(() => _categoryId = selection.categoryId);
  }

  Future<void> _pickPeople() async {
    final chosen = await showPersonPickerSheet(
      context,
      selectedIds: _personIds,
    );
    if (!mounted || chosen == null) return;
    setState(() => _personIds = chosen);
  }

  void _save() {
    Navigator.of(context).pop(
      EntryEdit(
        description: _description.text.trim(),
        categoryId: _categoryId,
        start: _start,
        end: _end,
        personIds: _personIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(timelineControllerProvider).categories;
    Category? selected;
    for (final category in categories) {
      if (category.id == _categoryId) selected = category;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: theme.textTheme.titleLarge),
                ),
                if (widget.canDelete)
                  IconButton(
                    tooltip: 'Delete entry',
                    onPressed: () =>
                        Navigator.of(context).pop(const EntryEdit.deleted()),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: LuqaSpacing.lg),
            TextField(
              key: const ValueKey('editor-description'),
              controller: _description,
              autofocus: widget.description.isEmpty,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'What did you do?',
                counterText: '',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: LuqaSpacing.md),
            _FieldRow(
              label: 'Category',
              value: selected?.name ?? 'No category',
              leading: selected == null
                  ? Icon(
                      Icons.label_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(selected.colorValue),
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 12),
                    ),
              onTap: _pickCategory,
            ),
            const SizedBox(height: LuqaSpacing.md),
            _FieldRow(
              key: const ValueKey('editor-people'),
              label: 'With',
              // Named rather than counted: "Mira, Jonas" is the thing being
              // recorded, and "2 people" would make the row a lookup.
              value: _peopleLabel(ref),
              leading: Icon(
                Icons.group_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onTap: _pickPeople,
            ),
            const SizedBox(height: LuqaSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _FieldRow(
                    label: 'Start',
                    value: clock(_start),
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: LuqaSpacing.md),
                Expanded(
                  child: _FieldRow(
                    label: 'End',
                    value: clock(_end),
                    hint: _crossesMidnight ? 'next day' : null,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: LuqaSpacing.md),
            Center(
              child: Text(
                compactDuration(_duration),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: LuqaSpacing.xl),
            FilledButton(
              key: const ValueKey('editor-save-button'),
              onPressed: _duration > Duration.zero ? _save : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.leading,
    this.hint,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? leading;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '$label $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: LuqaSpacing.md),
              ],
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (hint != null)
                Text(
                  hint!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
