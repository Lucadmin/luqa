import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';
import 'package:luqa/features/people/application/people_controller.dart';
import 'package:luqa/features/people/domain/person.dart';

/// The owner's deliberately curated relationship map.
///
/// Nothing here is inferred. Bills, messages, and time together can be useful
/// context, but they cannot decide what a relationship means to somebody.
class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(peopleControllerProvider);
    final people = state.listed;
    final placed = [
      for (final person in people)
        if (person.closeness != null) person,
    ];
    final unplaced = [
      for (final person in people)
        if (person.closeness == null) person,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Connections')),
      body: state.isLoading && !state.loaded
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: RefreshIndicator(
                onRefresh: ref.read(peopleControllerProvider.notifier).refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    LuqaSpacing.lg,
                    LuqaSpacing.md,
                    LuqaSpacing.lg,
                    LuqaSpacing.section + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    Text(
                      'Your people, in relation',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: LuqaSpacing.sm),
                    Text(
                      'You decide the shape. Luqa does not calculate closeness '
                      'from activity.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: LuqaSpacing.xl),
                    if (placed.isEmpty)
                      _EmptyGraph(
                        hasPeople: people.isNotEmpty,
                        onPlace: people.isEmpty
                            ? null
                            : () => _placeSomeone(context, ref, unplaced),
                      )
                    else ...[
                      _ConnectionGraph(
                        people: placed,
                        allPeople: people,
                        onPersonTap: (person) =>
                            _editPerson(context, ref, person.id),
                      ),
                      const SizedBox(height: LuqaSpacing.lg),
                      const _ClosenessLegend(),
                      const SizedBox(height: LuqaSpacing.lg),
                      Text(
                        'Tap a person to move them or connect them to someone '
                        'else.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (unplaced.isNotEmpty) ...[
                        const SizedBox(height: LuqaSpacing.xl),
                        OutlinedButton.icon(
                          key: const ValueKey('connections-place-someone'),
                          onPressed: () =>
                              _placeSomeone(context, ref, unplaced),
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: Text(
                            unplaced.length == 1
                                ? 'Place 1 more person'
                                : 'Place ${unplaced.length} more people',
                          ),
                        ),
                      ],
                    ],
                    if (state.error != null) ...[
                      const SizedBox(height: LuqaSpacing.lg),
                      Text(
                        state.error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _placeSomeone(
    BuildContext context,
    WidgetRef ref,
    List<Person> people,
  ) async {
    final personId = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _PersonPicker(people: people),
    );
    if (personId == null || !context.mounted) return;
    await _editPerson(context, ref, personId);
  }

  Future<void> _editPerson(
    BuildContext context,
    WidgetRef ref,
    String personId,
  ) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => _RelationshipEditor(personId: personId),
  );
}

class _EmptyGraph extends StatelessWidget {
  const _EmptyGraph({required this.hasPeople, required this.onPlace});

  final bool hasPeople;
  final VoidCallback? onPlace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    return Container(
      key: const ValueKey('connections-empty'),
      padding: const EdgeInsets.all(LuqaSpacing.xl),
      decoration: BoxDecoration(
        color: palette.workingSurface,
        borderRadius: BorderRadius.circular(LuqaRadii.surface),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              'You',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: LuqaSpacing.lg),
          Text(
            hasPeople ? 'Start with who feels closest' : 'Nobody to place yet',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: LuqaSpacing.sm),
          Text(
            hasPeople
                ? 'Place one person, then build the map at your own pace.'
                : 'Add someone in People before building your map.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onPlace != null) ...[
            const SizedBox(height: LuqaSpacing.xl),
            FilledButton.icon(
              key: const ValueKey('connections-start'),
              onPressed: onPlace,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Place someone'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectionGraph extends StatelessWidget {
  const _ConnectionGraph({
    required this.people,
    required this.allPeople,
    required this.onPersonTap,
  });

  final List<Person> people;
  final List<Person> allPeople;
  final ValueChanged<Person> onPersonTap;

  @override
  Widget build(BuildContext context) {
    final palette = LuqaPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = math.max(350.0, math.min(430.0, width * 1.12));
        final size = Size(width, height);
        final layout = _GraphLayout(size, people);
        final edges = _relationshipEdges(allPeople)
            .where(
              (edge) =>
                  layout.positions.containsKey(edge.first.id) &&
                  layout.positions.containsKey(edge.second.id),
            )
            .toList(growable: false);

        return Semantics(
          container: true,
          label:
              'Relationship graph with ${people.length} people. '
              'Closeness to you is shown by distance.',
          child: Container(
            key: const ValueKey('connections-graph'),
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: palette.workingSurface,
              borderRadius: BorderRadius.circular(LuqaRadii.surface),
              border: Border.all(color: palette.border),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: _ConnectionsPainter(
                        center: layout.center,
                        ringRadii: layout.ringRadii,
                        positions: layout.positions,
                        people: people,
                        edges: edges,
                        lineColor: Theme.of(context).colorScheme.onSurface,
                        ringColor: palette.border,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: layout.center.dx - 30,
                  top: layout.center.dy - 30,
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'You',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                for (final person in people)
                  _GraphPersonNode(
                    person: person,
                    position: layout.positions[person.id]!,
                    connectionCount: edges
                        .where((edge) => edge.contains(person.id))
                        .length,
                    onTap: () => onPersonTap(person),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GraphPersonNode extends StatelessWidget {
  const _GraphPersonNode({
    required this.person,
    required this.position,
    required this.connectionCount,
    required this.onTap,
  });

  final Person person;
  final Offset position;
  final int connectionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = person.closeness!;
    return Positioned(
      left: position.dx - 42,
      top: position.dy - 34,
      width: 84,
      height: 76,
      child: Semantics(
        button: true,
        label:
            '${person.displayName}, ${level.label}, '
            '$connectionCount ${connectionCount == 1 ? 'connection' : 'connections'}',
        child: InkResponse(
          key: ValueKey('connection-node-${person.id}'),
          onTap: onTap,
          radius: 36,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PersonAvatar(
                name: person.name,
                colorValue: person.colorValue,
                emoji: person.emoji,
                size: 48,
              ),
              const SizedBox(height: LuqaSpacing.xs),
              Text(
                person.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GraphLayout {
  _GraphLayout(this.size, List<Person> people)
    : center = Offset(size.width / 2, size.height / 2),
      ringRadii = _radii(size),
      positions = _positions(size, people);

  final Size size;
  final Offset center;
  final Map<Closeness, double> ringRadii;
  final Map<String, Offset> positions;

  static Map<Closeness, double> _radii(Size size) {
    final maximum = math.max(
      104.0,
      math.min(size.width / 2 - 38, size.height / 2 - 42),
    );
    final minimum = math.min(68.0, maximum * 0.58);
    return {
      for (final level in Closeness.values)
        level: minimum + (4 - level.value) * ((maximum - minimum) / 3),
    };
  }

  static Map<String, Offset> _positions(Size size, List<Person> people) {
    final center = Offset(size.width / 2, size.height / 2);
    final radii = _radii(size);
    final positions = <String, Offset>{};
    final ordered = [...people]..sort((a, b) => a.order.compareTo(b.order));
    for (var i = 0; i < ordered.length; i++) {
      final person = ordered[i];
      // One shared set of angular slots keeps people on adjacent rings from
      // piling up at twelve o'clock. Radius still carries closeness; angle is
      // only a stable way to give every name its own space.
      final angle = -math.pi / 2 + (2 * math.pi * i / ordered.length);
      final radius = radii[person.closeness]!;
      positions[person.id] = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
    }
    return positions;
  }
}

class _ConnectionsPainter extends CustomPainter {
  const _ConnectionsPainter({
    required this.center,
    required this.ringRadii,
    required this.positions,
    required this.people,
    required this.edges,
    required this.lineColor,
    required this.ringColor,
  });

  final Offset center;
  final Map<Closeness, double> ringRadii;
  final Map<String, Offset> positions;
  final List<Person> people;
  final List<_RelationshipEdge> edges;
  final Color lineColor;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ringColor.withValues(alpha: 0.58);
    for (final radius in ringRadii.values) {
      canvas.drawCircle(center, radius, ringPaint);
    }

    final ownerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = lineColor.withValues(alpha: 0.16);
    for (final person in people) {
      canvas.drawLine(center, positions[person.id]!, ownerPaint);
    }

    for (final edge in edges) {
      final strength = edge.closeness.value;
      final edgePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.2 + strength * 0.55
        ..color = lineColor.withValues(alpha: 0.20 + strength * 0.10);
      canvas.drawLine(
        positions[edge.first.id]!,
        positions[edge.second.id]!,
        edgePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionsPainter oldDelegate) =>
      oldDelegate.people != people ||
      oldDelegate.edges != edges ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.center != center;
}

class _ClosenessLegend extends StatelessWidget {
  const _ClosenessLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LuqaSpacing.md,
      runSpacing: LuqaSpacing.sm,
      children: [
        for (final level in Closeness.values.reversed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6 + level.value * 2,
                height: 6 + level.value * 2,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.32 + level.value * 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: LuqaSpacing.xs),
              Text(level.label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
      ],
    );
  }
}

class _PersonPicker extends StatelessWidget {
  const _PersonPicker({required this.people});

  final List<Person> people;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LuqaSpacing.lg,
              LuqaSpacing.sm,
              LuqaSpacing.lg,
              LuqaSpacing.md,
            ),
            child: Text(
              'Place someone',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: EdgeInsets.only(
                bottom: LuqaSpacing.lg + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: people.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final person = people[index];
                return ListTile(
                  key: ValueKey('connections-place-${person.id}'),
                  leading: PersonAvatar(
                    name: person.name,
                    colorValue: person.colorValue,
                    emoji: person.emoji,
                  ),
                  title: Text(person.displayName),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pop(person.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RelationshipEditor extends ConsumerStatefulWidget {
  const _RelationshipEditor({required this.personId});

  final String personId;

  @override
  ConsumerState<_RelationshipEditor> createState() =>
      _RelationshipEditorState();
}

class _RelationshipEditorState extends ConsumerState<_RelationshipEditor> {
  String? _newPersonId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(peopleControllerProvider);
    final person = state.byId(widget.personId);
    if (person == null) return const SizedBox.shrink();

    final people = state.listed;
    final edges = _relationshipEdges(people);
    final connected = [
      for (final edge in edges)
        if (edge.contains(person.id)) edge,
    ];
    final connectedIds = {
      for (final edge in connected) edge.other(person.id).id,
    };
    final candidates = [
      for (final other in people)
        if (other.id != person.id &&
            other.closeness != null &&
            !connectedIds.contains(other.id))
          other,
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          LuqaSpacing.lg,
          LuqaSpacing.sm,
          LuqaSpacing.lg,
          LuqaSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          Row(
            children: [
              PersonAvatar(
                name: person.name,
                colorValue: person.colorValue,
                emoji: person.emoji,
                size: 48,
              ),
              const SizedBox(width: LuqaSpacing.md),
              Expanded(
                child: Text(
                  person.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Open profile',
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/people/${person.id}');
                },
                icon: const Icon(Icons.open_in_new_rounded),
              ),
            ],
          ),
          const SizedBox(height: LuqaSpacing.xl),
          Text(
            'How close are you?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: LuqaSpacing.sm),
          Wrap(
            spacing: LuqaSpacing.sm,
            runSpacing: LuqaSpacing.sm,
            children: [
              for (final level in Closeness.values.reversed)
                ChoiceChip(
                  key: ValueKey(
                    'connections-closeness-${person.id}-${level.value}',
                  ),
                  label: Text(level.label),
                  selected: person.closeness == level,
                  onSelected: (_) => ref
                      .read(peopleControllerProvider.notifier)
                      .setCloseness(person.id, level),
                ),
            ],
          ),
          if (person.closeness != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: ValueKey('connections-unplace-${person.id}'),
                onPressed: () async {
                  await ref
                      .read(peopleControllerProvider.notifier)
                      .setCloseness(person.id, null);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Remove from graph'),
              ),
            ),
          ],
          const SizedBox(height: LuqaSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Connected to',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${connected.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuqaSpacing.sm),
          if (connected.isEmpty)
            Text(
              'No links yet. Add the people they are close to.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final edge in connected)
              _ConnectionRow(
                edge: edge,
                person: person,
                onChanged: (level) => ref
                    .read(peopleControllerProvider.notifier)
                    .setConnection(
                      firstPersonId: person.id,
                      secondPersonId: edge.other(person.id).id,
                      closeness: level,
                    ),
              ),
          const SizedBox(height: LuqaSpacing.lg),
          if (candidates.isEmpty)
            Text(
              people.length <= 1
                  ? 'Place another person before adding a link.'
                  : 'Everyone placed in the graph is already connected here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            DropdownButtonFormField<String>(
              key: const ValueKey('connections-add-person'),
              initialValue: _newPersonId,
              decoration: const InputDecoration(labelText: 'Add a connection'),
              items: [
                for (final candidate in candidates)
                  DropdownMenuItem(
                    value: candidate.id,
                    child: Text(candidate.displayName),
                  ),
              ],
              onChanged: (value) => setState(() => _newPersonId = value),
            ),
            if (_newPersonId != null) ...[
              const SizedBox(height: LuqaSpacing.md),
              Text(
                'How close are they to each other?',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: LuqaSpacing.sm),
              Wrap(
                spacing: LuqaSpacing.sm,
                runSpacing: LuqaSpacing.sm,
                children: [
                  for (final level in Closeness.values.reversed)
                    ActionChip(
                      key: ValueKey('connections-add-level-${level.value}'),
                      label: Text(level.label),
                      onPressed: () async {
                        final otherId = _newPersonId!;
                        final saved = await ref
                            .read(peopleControllerProvider.notifier)
                            .setConnection(
                              firstPersonId: person.id,
                              secondPersonId: otherId,
                              closeness: level,
                            );
                        if (saved && mounted) {
                          setState(() => _newPersonId = null);
                        }
                      },
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({
    required this.edge,
    required this.person,
    required this.onChanged,
  });

  final _RelationshipEdge edge;
  final Person person;
  final ValueChanged<Closeness?> onChanged;

  @override
  Widget build(BuildContext context) {
    final other = edge.other(person.id);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: PersonAvatar(
        name: other.name,
        colorValue: other.colorValue,
        emoji: other.emoji,
      ),
      title: Text(other.displayName),
      subtitle: Text(edge.closeness.label),
      trailing: PopupMenuButton<Closeness?>(
        key: ValueKey('connection-edit-${person.id}-${other.id}'),
        tooltip: 'Edit connection',
        onSelected: onChanged,
        itemBuilder: (context) => [
          for (final level in Closeness.values.reversed)
            PopupMenuItem(value: level, child: Text(level.label)),
          const PopupMenuDivider(),
          const PopupMenuItem(value: null, child: Text('Remove connection')),
        ],
      ),
    );
  }
}

class _RelationshipEdge {
  const _RelationshipEdge({
    required this.first,
    required this.second,
    required this.closeness,
  });

  final Person first;
  final Person second;
  final Closeness closeness;

  bool contains(String personId) =>
      first.id == personId || second.id == personId;

  Person other(String personId) => first.id == personId ? second : first;
}

List<_RelationshipEdge> _relationshipEdges(List<Person> people) {
  final byId = {for (final person in people) person.id: person};
  final byPair = <String, _RelationshipEdge>{};
  for (final owner in people) {
    for (final connection in owner.connections) {
      final other = byId[connection.personId];
      if (other == null || other.id == owner.id) continue;
      final ids = [owner.id, other.id]..sort();
      final key = '${ids.first}\u0000${ids.last}';
      final existing = byPair[key];
      if (existing == null ||
          connection.closeness.value > existing.closeness.value) {
        byPair[key] = _RelationshipEdge(
          first: owner,
          second: other,
          closeness: connection.closeness,
        );
      }
    }
  }
  final edges = byPair.values.toList(growable: false);
  edges.sort((a, b) {
    final first = a.first.displayName.compareTo(b.first.displayName);
    return first != 0
        ? first
        : a.second.displayName.compareTo(b.second.displayName);
  });
  return edges;
}
