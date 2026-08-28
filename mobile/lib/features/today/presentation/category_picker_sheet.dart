import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';

class CategorySelection {
  const CategorySelection(this.categoryId);

  final String? categoryId;
}

Future<CategorySelection?> showCategoryPickerSheet(
  BuildContext context, {
  required String? selectedId,
}) {
  return showModalBottomSheet<CategorySelection>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.76,
      child: _CategoryPickerSheet(selectedId: selectedId),
    ),
  );
}

class _CategoryPickerSheet extends ConsumerStatefulWidget {
  const _CategoryPickerSheet({required this.selectedId});

  final String? selectedId;

  @override
  ConsumerState<_CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<_CategoryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _creating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_creating || _query.trim().isEmpty) return;
    setState(() => _creating = true);
    final category = await ref
        .read(timelineControllerProvider.notifier)
        .addCategory(_query);
    if (!mounted) return;
    setState(() => _creating = false);
    if (category != null) {
      Navigator.of(context).pop(CategorySelection(category.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineControllerProvider);
    final theme = Theme.of(context);
    final normalized = _query.trim().toLowerCase();
    final filtered = state.categories
        .where((category) => category.name.toLowerCase().contains(normalized))
        .toList(growable: false);
    final exact = state.categories.any(
      (category) => category.name.toLowerCase() == normalized,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Choose category',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Search or create',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => setState(() => _query = value),
            onSubmitted: (_) {
              if (!exact) _create();
            },
          ),
        ),
        const SizedBox(height: LuqaSpacing.md),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: [
              _CategoryRow(
                label: 'No category',
                icon: Icons.label_off_outlined,
                selected: widget.selectedId == null,
                onTap: () =>
                    Navigator.of(context).pop(const CategorySelection(null)),
              ),
              for (final category in filtered)
                _CategoryRow(
                  label: category.name,
                  color: Color(category.colorValue),
                  selected: widget.selectedId == category.id,
                  onTap: () =>
                      Navigator.of(context).pop(CategorySelection(category.id)),
                ),
              if (normalized.isNotEmpty && !exact)
                _CategoryRow(
                  label: _creating ? 'Creating…' : 'Create “${_query.trim()}”',
                  icon: Icons.add_rounded,
                  color: theme.colorScheme.primary,
                  selected: false,
                  onTap: _creating ? null : _create,
                ),
              if (filtered.isEmpty && normalized.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No categories yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      minTileHeight: 56,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuqaRadii.control),
      ),
      leading: icon != null
          ? Icon(icon, color: color ?? theme.colorScheme.onSurfaceVariant)
          : DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 12),
            ),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
