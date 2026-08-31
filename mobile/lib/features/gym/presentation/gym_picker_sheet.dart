import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

class GymPickerResult {
  const GymPickerResult.location(this.locationId) : manage = false;
  const GymPickerResult.manage() : locationId = null, manage = true;

  final String? locationId;
  final bool manage;
}

Future<GymPickerResult?> showGymPickerSheet(
  BuildContext context, {
  required List<GymLocation> locations,
  required String? selectedId,
  bool allowNoGym = true,
}) {
  return showModalBottomSheet<GymPickerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _GymPickerSheet(
      locations: locations,
      selectedId: selectedId,
      allowNoGym: allowNoGym,
    ),
  );
}

class _GymPickerSheet extends StatelessWidget {
  const _GymPickerSheet({
    required this.locations,
    required this.selectedId,
    required this.allowNoGym,
  });

  final List<GymLocation> locations;
  final String? selectedId;
  final bool allowNoGym;

  @override
  Widget build(BuildContext context) {
    final active = locations
        .where((location) => !location.archived || location.id == selectedId)
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LuqaSpacing.xl,
        LuqaSpacing.sm,
        LuqaSpacing.xl,
        LuqaSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Workout gym', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: LuqaSpacing.lg),
          if (active.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.xl),
              child: Text(
                'Add your first gym so machine weights stay comparable.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final location in active)
            _GymRow(
              location: location,
              selected: location.id == selectedId,
              onTap: () =>
                  Navigator.pop(context, GymPickerResult.location(location.id)),
            ),
          if (allowNoGym)
            _PlainRow(
              title: 'No gym',
              subtitle: 'Keep this workout unassigned',
              selected: selectedId == null,
              onTap: () =>
                  Navigator.pop(context, const GymPickerResult.location(null)),
            ),
          const Divider(),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: () =>
                  Navigator.pop(context, const GymPickerResult.manage()),
              child: const Text('Manage gyms'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymRow extends StatelessWidget {
  const _GymRow({
    required this.location,
    required this.selected,
    required this.onTap,
  });

  final GymLocation location;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LuqaRadii.control),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
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
            if (selected) const Icon(Icons.check_rounded),
          ],
        ),
      ),
    );
  }
}

class _PlainRow extends StatelessWidget {
  const _PlainRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const SizedBox(width: 34),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_rounded),
          ],
        ),
      ),
    );
  }
}
