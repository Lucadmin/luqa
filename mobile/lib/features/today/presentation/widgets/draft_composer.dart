import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';

/// Docked below the timeline while a block is being composed. A sheet would
/// cover the very thing being edited, so the controls sit under the grid and
/// leave the block in view the whole time.
class DraftComposer extends ConsumerStatefulWidget {
  const DraftComposer({
    required this.draft,
    required this.categories,
    required this.recents,
    required this.saving,
    required this.error,
    required this.onEditTimes,
    required this.onDelete,
    super.key,
  });

  final TimelineDraft draft;
  final List<Category> categories;
  final List<RecentActivity> recents;
  final bool saving;
  final String? error;
  final VoidCallback onEditTimes;

  /// Only offered while an existing entry is being reshaped.
  final VoidCallback? onDelete;

  @override
  ConsumerState<DraftComposer> createState() => _DraftComposerState();
}

class _DraftComposerState extends ConsumerState<DraftComposer> {
  late final TextEditingController _description = TextEditingController(
    text: widget.draft.description,
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_redraw);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_redraw)
      ..dispose();
    _description.dispose();
    super.dispose();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  TimelineController get _controller =>
      ref.read(timelineControllerProvider.notifier);

  void _apply(RecentActivity recent) {
    _description.value = TextEditingValue(
      text: recent.description,
      selection: TextSelection.collapsed(offset: recent.description.length),
    );
    _controller
      ..describeDraft(recent.description)
      ..categoriseDraft(recent.categoryId);
    _focus.unfocus();
  }

  Future<void> _save() async {
    _focus.unfocus();
    await _controller.commitDraft();
  }

  /// While the field is focused, offer what was logged before. Matching by
  /// substring keeps a two-letter prefix useful.
  List<RecentActivity> get _suggestions {
    if (!_focus.hasFocus) return const [];
    final query = _description.text.trim().toLowerCase();
    return widget.recents
        .where(
          (recent) =>
              query.isEmpty ||
              (recent.description.toLowerCase().contains(query) &&
                  recent.description.toLowerCase() != query),
        )
        .take(3)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final draft = widget.draft;
    final suggestions = _suggestions;

    return Material(
      color: palette.workingSurface,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final recent in suggestions)
                  _SuggestionRow(
                    recent: recent,
                    category: _categoryFor(recent.categoryId),
                    onTap: () => _apply(recent),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label:
                            'Change times. Currently ${clock(draft.start)} '
                            'to ${clock(draft.end)}',
                        child: InkWell(
                          onTap: widget.onEditTimes,
                          borderRadius: BorderRadius.circular(
                            LuqaRadii.compact,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${clock(draft.start)} – '
                                    '${clock(draft.end)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: LuqaSpacing.sm),
                                Flexible(
                                  child: Text(
                                    compactDuration(draft.duration),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                ),
                                const SizedBox(width: LuqaSpacing.xs),
                                Icon(
                                  Icons.expand_more_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.onDelete != null)
                      IconButton(
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.saving ? null : widget.onDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    IconButton(
                      tooltip: 'Discard',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.saving
                          ? null
                          : () => _controller.cancelDraft(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: LuqaSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('draft-description'),
                        controller: _description,
                        focusNode: _focus,
                        maxLength: 500,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'What did you do?',
                          counterText: '',
                          isDense: true,
                        ),
                        onChanged: _controller.describeDraft,
                        onSubmitted: (_) => _save(),
                      ),
                    ),
                    const SizedBox(width: LuqaSpacing.sm),
                    SizedBox.square(
                      dimension: 48,
                      child: IconButton.filled(
                        key: const ValueKey('save-draft-button'),
                        tooltip: draft.isNew ? 'Add entry' : 'Save changes',
                        onPressed: widget.saving ? null : _save,
                        icon: widget.saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LuqaSpacing.sm),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        label: 'No category',
                        selected: draft.categoryId == null,
                        onTap: () => _controller.categoriseDraft(null),
                      ),
                      for (final category in widget.categories)
                        _CategoryChip(
                          label: category.name,
                          color: Color(category.colorValue),
                          selected: draft.categoryId == category.id,
                          onTap: () => _controller.categoriseDraft(category.id),
                        ),
                    ],
                  ),
                ),
                if (widget.error != null) ...[
                  const SizedBox(height: LuqaSpacing.sm),
                  Text(
                    widget.error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Category? _categoryFor(String? id) {
    for (final category in widget.categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LuqaRadii.compact),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: LuqaSpacing.md),
            Expanded(
              child: Text(
                recent.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (category != null) ...[
              const SizedBox(width: LuqaSpacing.sm),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(category!.colorValue),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 8),
              ),
              const SizedBox(width: LuqaSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  category!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final tint = color ?? theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(right: LuqaSpacing.sm),
      child: Material(
        color: selected
            ? tint.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.24 : 0.14,
              )
            : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? tint.withValues(alpha: 0.75) : palette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (color != null) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: 8),
                  ),
                  const SizedBox(width: LuqaSpacing.sm),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
