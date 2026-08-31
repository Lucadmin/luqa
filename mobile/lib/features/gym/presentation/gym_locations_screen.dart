import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/application/gym_overview_controller.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

class GymLocationsScreen extends ConsumerWidget {
  const GymLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gymOverviewControllerProvider);
    final controller = ref.read(gymOverviewControllerProvider.notifier);
    final locations = state.overview?.locations ?? const <GymLocation>[];
    final active = locations.where((item) => !item.archived).toList();
    final archived = locations.where((item) => item.archived).toList();

    Future<void> edit([GymLocation? location]) async {
      final draft = await showModalBottomSheet<_LocationDraft>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => _LocationEditor(location: location),
      );
      if (draft == null || !context.mounted) return;
      final saved = location == null
          ? await controller.createLocation(
              name: draft.name,
              code: draft.code,
              colorValue: draft.colorValue,
            )
          : await controller.updateLocation(
              id: location.id,
              name: draft.name,
              code: draft.code,
              colorValue: draft.colorValue,
            );
      if (!saved && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(gymOverviewControllerProvider).error ??
                  'Could not save gym.',
            ),
          ),
        );
      }
    }

    Future<void> setArchived(GymLocation location, bool archived) async {
      final saved = await controller.updateLocation(
        id: location.id,
        archived: archived,
      );
      if (!saved || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              archived
                  ? '${location.name} archived'
                  : '${location.name} restored',
            ),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => controller.updateLocation(
                id: location.id,
                archived: !archived,
              ),
            ),
          ),
        );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gyms')),
      body: state.isLoading && state.overview == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                LuqaSpacing.lg,
                LuqaSpacing.lg,
                LuqaSpacing.lg,
                96,
              ),
              children: [
                Text(
                  'Machine weights stay separate by gym. Changing a workout’s gym never changes its entered sets.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: LuqaSpacing.xxl),
                if (active.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: LuqaSpacing.xl,
                    ),
                    child: Text(
                      'No gyms yet.',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  )
                else
                  for (final location in active) ...[
                    _LocationRow(
                      location: location,
                      onTap: () => edit(location),
                      onArchive: () => setArchived(location, true),
                    ),
                    const Divider(),
                  ],
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: LuqaSpacing.section),
                  Text(
                    'Archived',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: LuqaSpacing.md),
                  for (final location in archived) ...[
                    _LocationRow(
                      location: location,
                      onTap: () => edit(location),
                      onArchive: () => setArchived(location, false),
                    ),
                    const Divider(),
                  ],
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(LuqaSpacing.lg),
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: () => edit(),
            child: const Text('Add gym'),
          ),
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.location,
    required this.onTap,
    required this.onArchive,
  });

  final GymLocation location;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Color(location.colorValue),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: LuqaSpacing.lg),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    location.code,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: '${location.name} options',
              onSelected: (_) => onArchive(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'archive',
                  child: Text(location.archived ? 'Restore' : 'Archive'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationDraft {
  const _LocationDraft({
    required this.name,
    required this.code,
    required this.colorValue,
  });

  final String name;
  final String code;
  final int colorValue;
}

class _LocationEditor extends StatefulWidget {
  const _LocationEditor({this.location});

  final GymLocation? location;

  @override
  State<_LocationEditor> createState() => _LocationEditorState();
}

class _LocationEditorState extends State<_LocationEditor> {
  static const colors = <int>[
    0xFF6543E8,
    0xFF2563EB,
    0xFF0F766E,
    0xFF15803D,
    0xFFB45309,
    0xFFC2410C,
    0xFFBE185D,
  ];

  late final TextEditingController _name = TextEditingController(
    text: widget.location?.name ?? '',
  );
  late final TextEditingController _code = TextEditingController(
    text: widget.location?.code ?? '',
  );
  late int _colorValue = widget.location?.colorValue ?? colors.first;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final code = _code.text.trim().toUpperCase();
    if (name.isEmpty || code.isEmpty) return;
    Navigator.pop(
      context,
      _LocationDraft(name: name, code: code, colorValue: _colorValue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        LuqaSpacing.xl,
        LuqaSpacing.sm,
        LuqaSpacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + LuqaSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.location == null ? 'Add gym' : 'Edit gym',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: LuqaSpacing.xl),
          TextField(
            controller: _name,
            autofocus: widget.location == null,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: LuqaSpacing.md),
          TextField(
            controller: _code,
            maxLength: 12,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 -]')),
            ],
            decoration: const InputDecoration(labelText: 'Short code'),
          ),
          const SizedBox(height: LuqaSpacing.lg),
          Text('Color', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: LuqaSpacing.md),
          Wrap(
            spacing: LuqaSpacing.md,
            runSpacing: LuqaSpacing.md,
            children: [
              for (final color in colors)
                Semantics(
                  label: color == _colorValue
                      ? 'Selected gym color'
                      : 'Choose gym color',
                  selected: color == _colorValue,
                  button: true,
                  child: InkWell(
                    onTap: () => setState(() => _colorValue = color),
                    borderRadius: BorderRadius.circular(LuqaRadii.control),
                    child: SizedBox.square(
                      dimension: 48,
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: color == _colorValue
                                ? Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    width: 2,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: LuqaSpacing.xl),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _save,
              child: Text(widget.location == null ? 'Add gym' : 'Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}
