import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/people/domain/people_math.dart';

/// Where everyone is, on a map.
///
/// One pin per **city**, not per person. Thirty overlapping pins in Munich is
/// not an overview, and grouping by city means the map never needs clustering
/// at all. The pin carries a count and opens the list of names.
class PeopleMap extends StatefulWidget {
  const PeopleMap({
    required this.cities,
    required this.onSelect,
    super.key,
  });

  /// Only cities with a point can be drawn. The rest still exist and are
  /// listed by the screen around this one — a place that lists without pinning
  /// is a normal state, not an error.
  final List<PeopleInCity> cities;

  final void Function(PeopleInCity city) onSelect;

  @override
  State<PeopleMap> createState() => _PeopleMapState();
}

class _PeopleMapState extends State<PeopleMap> {
  final _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<PeopleInCity> get _mappable => [
    for (final city in widget.cities)
      if (city.isMappable) city,
  ];

  /// Everything on screen at once, so the first look answers "where is
  /// everyone" without a single gesture.
  CameraFit? get _fit {
    final points = [
      for (final city in _mappable) LatLng(city.latitude!, city.longitude!),
    ];
    if (points.isEmpty) return null;
    return CameraFit.coordinates(
      coordinates: points,
      padding: const EdgeInsets.all(64),
      // A single city would otherwise fill the screen at street level, which
      // says less than a country's worth of context does.
      maxZoom: 11,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cities = _mappable;

    return ClipRRect(
      borderRadius: BorderRadius.circular(LuqaRadii.surface),
      child: FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCameraFit: _fit,
          initialCenter: const LatLng(48.137, 11.575),
          initialZoom: 4,
          minZoom: 2,
          maxZoom: 12,
          // Nothing on this map rotates, and a stray two-finger twist that
          // leaves north pointing sideways is only ever an accident.
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.drag |
                InteractiveFlag.pinchZoom |
                InteractiveFlag.doubleTapZoom,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'app.luqa.mobile',
            // The shell belongs to Luqa; the colour belongs to the data. OSM's
            // own palette would be the loudest thing on a screen whose point
            // is a handful of identity-coloured pins, so the tiles are drained
            // to a neutral ground and the markers carry the only colour.
            tileBuilder: (context, tileWidget, tile) => ColorFiltered(
              colorFilter: isDark ? _darkTiles : _lightTiles,
              child: tileWidget,
            ),
          ),
          MarkerLayer(
            markers: [
              for (final city in cities)
                Marker(
                  point: LatLng(city.latitude!, city.longitude!),
                  width: 96,
                  height: 44,
                  alignment: Alignment.center,
                  child: _CityPin(
                    city: city,
                    onTap: () => widget.onSelect(city),
                  ),
                ),
            ],
          ),
          // The tile licence requires this, and it stays legible against both
          // filtered grounds.
          const RichAttributionWidget(
            alignment: AttributionAlignment.bottomRight,
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Greyscale, then lifted and flattened, so the map reads as paper rather than
/// as a competing illustration.
const _lightTiles = ColorFilter.matrix(<double>[
  0.29, 0.58, 0.11, 0, 70, //
  0.29, 0.58, 0.11, 0, 70, //
  0.29, 0.58, 0.11, 0, 70, //
  0, 0, 0, 1, 0, //
]);

/// The same drain, then inverted and darkened, so a dark theme gets a dark
/// ground rather than a glowing white rectangle.
const _darkTiles = ColorFilter.matrix(<double>[
  -0.22, -0.44, -0.08, 0, 150, //
  -0.22, -0.44, -0.08, 0, 150, //
  -0.22, -0.44, -0.08, 0, 150, //
  0, 0, 0, 1, 0, //
]);

/// A city, as a mark: the count and the name together, because a dot alone
/// would make the map a puzzle rather than an answer.
class _CityPin extends StatelessWidget {
  const _CityPin({required this.city, required this.onTap});

  final PeopleInCity city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    return Semantics(
      button: true,
      label: '${city.people.length} in ${city.city}',
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(LuqaRadii.compact),
              border: Border.all(color: palette.border),
              // The one place a shadow is right: this is floating above
              // another surface rather than sitting on one.
              boxShadow: const [
                BoxShadow(
                  color: Color(0x29000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuqaSpacing.sm,
                vertical: LuqaSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${city.people.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: LuqaSpacing.xs),
                  Flexible(
                    child: Text(
                      city.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
