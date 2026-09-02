import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/people/application/people_controller.dart';
import 'package:luqa/features/people/domain/city_candidate.dart';

/// What the picker came back with.
///
/// [city] is the one that was chosen. It is null when the search could not be
/// made — offline, mostly — and the typed [name] is being taken at its word,
/// which leaves the place listing without a pin until the server's geocoding
/// batch has a guess at it.
class PlaceChoice {
  const PlaceChoice({
    required this.name,
    required this.label,
    this.city,
    this.isPrimary = false,
  });

  final String name;
  final String label;
  final CityCandidate? city;
  final bool isPrimary;
}

/// Choosing which city, rather than typing one and hoping.
///
/// There are two dozen Springfields and two famous Cambridges. Until this
/// existed a typed name was handed to a geocoder that kept whatever it ranked
/// first, so the owner never got a say and never saw that a choice had been
/// made on their behalf. Here the choice is the whole interaction: the
/// candidates carry their region, country and size, which is what a person
/// actually recognises a city by.
Future<PlaceChoice?> showCityPickerSheet(
  BuildContext context, {
  required bool canChoosePrimary,
}) {
  return showModalBottomSheet<PlaceChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.88,
      child: _CityPickerSheet(canChoosePrimary: canChoosePrimary),
    ),
  );
}

class _CityPickerSheet extends ConsumerStatefulWidget {
  const _CityPickerSheet({required this.canChoosePrimary});

  /// Only worth asking about when they already have a city: the first one is
  /// primary whether or not anybody chose it.
  final bool canChoosePrimary;

  @override
  ConsumerState<_CityPickerSheet> createState() => _CityPickerSheetState();
}

/// Long enough that a fast typist makes one request instead of eight, short
/// enough that stopping to think is answered before the finger moves.
const _debounce = Duration(milliseconds: 300);

/// Below this a query matches half the world and none of it usefully.
const _minQuery = 2;

class _CityPickerSheetState extends ConsumerState<_CityPickerSheet> {
  final _search = TextEditingController();
  final _label = TextEditingController(text: 'Home');
  final _focus = FocusNode();

  Timer? _timer;

  /// Which search the results on screen belong to. An answer to an older
  /// query arriving after a newer one is the classic way a picker ends up
  /// showing results for what was typed two letters ago.
  int _generation = 0;

  List<CityCandidate> _results = const [];
  bool _searching = false;

  /// The search could not be made at all — which is a different thing from
  /// finding nothing, and leads somewhere different on screen.
  bool _unreachable = false;

  CityCandidate? _chosen;

  /// Whether the typed name is being taken as it stands. Separate from
  /// [_chosen] being null, which is also what "still choosing" looks like —
  /// one is a decision and the other is the absence of one.
  bool _asTyped = false;

  bool _isPrimary = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search
      ..removeListener(_onQueryChanged)
      ..dispose();
    _label.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim();

  void _onQueryChanged() {
    _timer?.cancel();
    // Anything already on screen belongs to a query that is no longer what is
    // in the field, so it stops being an answer the moment a key is pressed.
    setState(() {
      _results = const [];
      _unreachable = false;
      _searching = _query.length >= _minQuery;
    });
    if (_query.length < _minQuery) return;
    _timer = Timer(_debounce, _run);
  }

  Future<void> _run() async {
    final generation = ++_generation;
    final query = _query;
    try {
      final results = await ref
          .read(peopleControllerProvider.notifier)
          .searchCities(query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (_) {
      // Which failure it was does not change what can be offered: the name as
      // typed, resolved later. The banner for a failed write would be wrong
      // here — nothing was being written.
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = const [];
        _searching = false;
        _unreachable = true;
      });
    }
  }

  void _choose(CityCandidate? city) {
    setState(() {
      _chosen = city;
      _asTyped = city == null;
    });
    // The label is the only thing left to say, so put the cursor on it.
    FocusScope.of(context).unfocus();
  }

  void _unchoose() => setState(() {
    _chosen = null;
    _asTyped = false;
  });

  void _add() {
    final label = _label.text.trim();
    Navigator.of(context).pop(
      PlaceChoice(
        name: _chosen?.name ?? _query,
        label: label.isEmpty ? 'Home' : label,
        city: _chosen,
        isPrimary: _isPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        LuqaSpacing.lg,
        LuqaSpacing.sm,
        LuqaSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + LuqaSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: LuqaSpacing.sm),
          Text('Add a city', style: theme.textTheme.titleLarge),
          const SizedBox(height: LuqaSpacing.lg),
          if (_chosen == null && !_asTyped)
            ..._searchStep(theme)
          else
            ..._labelStep(theme),
        ],
      ),
    );
  }

  List<Widget> _searchStep(ThemeData theme) => [
    TextField(
      key: const ValueKey('place-city'),
      controller: _search,
      focusNode: _focus,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: 'Search for a city',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    ),
    const SizedBox(height: LuqaSpacing.lg),
    Expanded(child: _results.isEmpty ? _noResults(theme) : _resultList()),
  ];

  Widget _resultList() => ListView.separated(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    itemCount: _results.length,
    separatorBuilder: (_, _) => const Divider(),
    itemBuilder: (context, index) {
      final city = _results[index];
      return _CityRow(
        key: ValueKey('city-candidate-${city.id}'),
        city: city,
        onTap: () => _choose(city),
      );
    },
  );

  /// Nothing to show yet, nothing to show at all, or nothing reachable. Three
  /// different sentences, because they ask for three different things.
  Widget _noResults(ThemeData theme) {
    final muted = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (_query.length < _minQuery) {
      return Center(
        child: Text(
          'Type a city name to see which one you mean.',
          textAlign: TextAlign.center,
          style: muted,
        ),
      );
    }
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _unreachable
                ? 'No connection, so the city list is not available.'
                : 'No city called “$_query”.',
            textAlign: TextAlign.center,
            style: muted,
          ),
          const SizedBox(height: LuqaSpacing.sm),
          Text(
            _unreachable
                // Said plainly: this is the fallback, and it is worse than
                // picking. What it costs is the pin, until the server catches
                // up.
                ? 'You can add it as typed and it will find itself on the map '
                      'later.'
                : 'Check the spelling, or add it as typed.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: LuqaSpacing.md),
          TextButton(
            key: const ValueKey('place-as-typed'),
            onPressed: () => _choose(null),
            child: Text('Add “$_query” as typed'),
          ),
        ],
      ),
    );
  }

  List<Widget> _labelStep(ThemeData theme) {
    final city = _chosen;
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.location_on_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(city?.name ?? _query),
        subtitle: Text(
          city == null
              ? 'As typed — it will pin once the server resolves it'
              : [
                  if (city.where.isNotEmpty) city.where,
                  if (city.population != null) _people(city.population!),
                ].join(' · '),
        ),
        trailing: TextButton(onPressed: _unchoose, child: const Text('Change')),
      ),
      const SizedBox(height: LuqaSpacing.md),
      TextField(
        key: const ValueKey('place-label'),
        controller: _label,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'What it is',
          helperText: 'Home, parents, where they summer',
        ),
      ),
      if (widget.canChoosePrimary) ...[
        const SizedBox(height: LuqaSpacing.sm),
        SwitchListTile(
          key: const ValueKey('place-primary'),
          contentPadding: EdgeInsets.zero,
          value: _isPrimary,
          onChanged: (value) => setState(() => _isPrimary = value),
          title: const Text('Where they mostly are'),
          subtitle: const Text('Shown under their name'),
        ),
      ],
      const Spacer(),
      FilledButton(
        key: const ValueKey('place-add'),
        onPressed: _add,
        child: const Text('Add'),
      ),
    ];
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({required this.city, required this.onTap, super.key});

  final CityCandidate city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The region and the size, which together are what tell Springfield,
    // Illinois from Springfield, Missouri at a glance.
    final detail = [
      if (city.where.isNotEmpty) city.where,
      if (city.population != null) _people(city.population!),
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(city.name, style: theme.textTheme.bodyLarge),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: LuqaSpacing.xs),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "1.5M", "114k", "8,300". Rounded hard on purpose: this is here to say how
/// big a place is, not how many people live there.
String _people(int population) {
  if (population >= 1000000) {
    final millions = population / 1000000;
    return '${millions >= 10 ? millions.round() : millions.toStringAsFixed(1)}M';
  }
  if (population >= 1000) return '${(population / 1000).round()}k';
  return '$population';
}
