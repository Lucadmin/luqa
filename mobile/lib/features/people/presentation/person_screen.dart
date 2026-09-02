import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/application/money_controller.dart';
import 'package:luqa/features/money/presentation/money_formatters.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';
import 'package:luqa/features/people/application/people_controller.dart';
import 'package:luqa/features/people/application/shared_time_provider.dart';
import 'package:luqa/features/people/domain/people_math.dart';
import 'package:luqa/features/people/domain/person.dart';
import 'package:luqa/features/people/presentation/people_screen.dart'
    show describeCadence;
import 'package:luqa/features/people/presentation/person_editor_sheet.dart';
import 'package:luqa/features/people/presentation/widgets/city_picker_sheet.dart';

/// One person, and everything about them.
///
/// The money ledger stays where it is and is linked to rather than reproduced:
/// this screen is the relationship, and a balance is one fact about it.
class PersonScreen extends ConsumerWidget {
  const PersonScreen({required this.personId, super.key});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(peopleControllerProvider);
    final person = state.byId(personId);

    if (person == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(LuqaSpacing.xl),
            child: Text(
              state.loaded
                  ? 'This person is no longer on your list.'
                  : 'Loading…',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final now = ref.watch(peopleNowProvider);
    final controller = ref.read(peopleControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(person.displayName),
        actions: [
          IconButton(
            key: const ValueKey('person-edit'),
            tooltip: 'Edit',
            onPressed: () => showPersonEditorSheet(context, ref, person: person),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          LuqaSpacing.lg,
          LuqaSpacing.sm,
          LuqaSpacing.lg,
          LuqaSpacing.section + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _Identity(person: person),
          const SizedBox(height: LuqaSpacing.xl),
          _Focus(
            person: person,
            now: now,
            lastSeen: ref.watch(lastSeenProvider)(person),
          ),
          const SizedBox(height: LuqaSpacing.xl),
          _SeenAction(
            person: person,
            now: now,
            onSeen: () => controller.markSeen(person.id, now),
          ),
          _Balance(personId: person.id),
          const SizedBox(height: LuqaSpacing.section),
          _Together(person: person, now: now),
          const SizedBox(height: LuqaSpacing.section),
          _Notes(person: person),
          const SizedBox(height: LuqaSpacing.section),
          _Gifts(person: person),
          const SizedBox(height: LuqaSpacing.section),
          _Places(person: person),
          const SizedBox(height: LuqaSpacing.section),
          _Details(person: person),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = person.primaryPlace;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonAvatar(
          name: person.name,
          colorValue: person.colorValue,
          emoji: person.emoji,
          size: 56,
          dimmed: person.archived,
        ),
        const SizedBox(width: LuqaSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(person.displayName, style: theme.textTheme.headlineSmall),
              // The contact-book name still shows when a nickname is doing the
              // talking, so the row is recognisable against a phone's contacts.
              if (person.nickname != null &&
                  person.nickname!.trim().isNotEmpty) ...[
                const SizedBox(height: LuqaSpacing.xxs),
                Text(
                  person.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (place != null) ...[
                const SizedBox(height: LuqaSpacing.xs),
                Text(
                  place.shortLocation,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The one line at display size: the birthday when it is close, otherwise how
/// long it has been.
class _Focus extends StatelessWidget {
  const _Focus({required this.person, required this.now, required this.lastSeen});

  final Person person;
  final DateTime now;

  /// The newest of the typed date, a tagged block of time, and a shared bill.
  final DateTime? lastSeen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final birthday = person.birthday;
    final days = birthday?.daysUntil(now);

    if (birthday != null && days != null && days <= 30) {
      final age = birthday.ageOnNext(now);
      return _FocusLine(
        label: days == 0 ? 'Birthday today' : 'Birthday',
        value: describeCountdown(days),
        supporting: age == null ? formatBirthday(birthday) : 'Turns $age',
        valueKey: const ValueKey('person-focus-birthday'),
      );
    }

    final seen = lastSeen;
    if (seen != null) {
      final elapsed = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(seen.year, seen.month, seen.day)).inDays;
      return _FocusLine(
        label: 'Last seen',
        value: describeElapsed(elapsed),
        supporting: person.cadenceDays == null
            ? null
            : 'Aiming for every ${describeCadence(person.cadenceDays!)}',
        valueKey: const ValueKey('person-focus-seen'),
      );
    }

    if (birthday != null) {
      return _FocusLine(
        label: 'Birthday',
        value: formatBirthday(birthday),
        supporting: describeCountdown(days!),
        valueKey: const ValueKey('person-focus-birthday'),
      );
    }

    return Text(
      'Nothing on the record yet.',
      style: theme.textTheme.bodyLarge?.copyWith(color: muted),
    );
  }
}

class _FocusLine extends StatelessWidget {
  const _FocusLine({
    required this.label,
    required this.value,
    required this.supporting,
    required this.valueKey,
  });

  final String label;
  final String value;
  final String? supporting;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      key: valueKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
        const SizedBox(height: LuqaSpacing.sm),
        Text(value, style: theme.textTheme.displaySmall),
        if (supporting != null) ...[
          const SizedBox(height: LuqaSpacing.sm),
          Text(
            supporting!,
            style: theme.textTheme.bodyLarge?.copyWith(color: muted),
          ),
        ],
      ],
    );
  }
}

/// The write this screen makes most often, and the one that keeps every
/// overdue list honest.
class _SeenAction extends ConsumerWidget {
  const _SeenAction({
    required this.person,
    required this.now,
    required this.onSeen,
  });

  final Person person;
  final DateTime now;
  final VoidCallback onSeen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Anything that already counts as seeing them — a tagged dinner, a shared
    // bill — disables the button, because pressing it would record a fact the
    // app already has.
    final seen = ref.watch(lastSeenProvider)(person);
    final seenToday =
        seen != null &&
        seen.year == now.year &&
        seen.month == now.month &&
        seen.day == now.day;

    return Padding(
      padding: const EdgeInsets.only(bottom: LuqaSpacing.md),
      child: OutlinedButton.icon(
        key: const ValueKey('person-mark-seen'),
        onPressed: seenToday ? null : onSeen,
        icon: const Icon(Icons.check_rounded),
        label: Text(seenToday ? 'Seen today' : 'Saw them today'),
      ),
    );
  }
}

/// One row, only when there is actually a balance. A settled friend does not
/// need a line of money on their page.
class _Balance extends ConsumerWidget {
  const _Balance({required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(moneyControllerProvider).overview;
    final balance = overview?.balanceOf(personId);
    if (overview == null || balance == null || balance.balanceCents == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final owed = balance.balanceCents > 0;

    return InkWell(
      key: const ValueKey('person-balance'),
      onTap: () => context.push('/money/people/$personId'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                owed ? 'Owes you' : 'You owe',
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Text(
              formatMoney(balance.balanceCents.abs(), overview.currency),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: owed ? palette.credit : palette.debit,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: LuqaSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// The time actually spent together, from the timeline.
///
/// The point of tagging a block of time is that this list builds itself. It
/// only appears once there is something in it, because an empty "Together" on
/// every contact would be a reproach rather than a record.
class _Together extends ConsumerWidget {
  const _Together({required this.person, required this.now});

  final Person person;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entries = ref.watch(sharedEntriesProvider)(person.id);
    if (entries.isEmpty) return const SizedBox.shrink();

    final thisYear = entries.where((entry) => entry.start.year == now.year);
    final hours = thisYear.fold<Duration>(
      Duration.zero,
      (total, entry) => total + entry.duration,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(title: 'Together'),
        if (hours > Duration.zero)
          Text(
            '${_hours(hours)} in ${now.year}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: LuqaSpacing.sm),
        // A handful, newest first. The whole history belongs on the timeline,
        // which is where it already is.
        for (final entry in entries.take(6))
          Padding(
            key: ValueKey('together-${entry.id}'),
            padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.description.trim().isEmpty
                        ? 'Untitled'
                        : entry.description.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: LuqaSpacing.md),
                Text(
                  _day(entry.start),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _hours(Duration total) {
    final hours = total.inMinutes / 60;
    return hours < 10
        ? '${hours.toStringAsFixed(1)} hours'
        : '${hours.round()} hours';
  }

  String _day(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.';
}

class _Notes extends ConsumerStatefulWidget {
  const _Notes({required this.person});

  final Person person;

  @override
  ConsumerState<_Notes> createState() => _NotesState();
}

class _NotesState extends ConsumerState<_Notes> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _saving) return;
    setState(() => _saving = true);
    final ok = await ref
        .read(peopleControllerProvider.notifier)
        .addNote(widget.person.id, body: body);
    if (!mounted) return;
    if (ok) _controller.clear();
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ref.read(peopleControllerProvider.notifier);
    final notes = widget.person.orderedNotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(title: 'Notes'),
        if (notes.isEmpty)
          Text(
            'Nothing written down. The useful ones are the standing facts — '
            'the allergy, the kids’ names, what they are in the middle of.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        for (final note in notes)
          Padding(
            key: ValueKey('note-${note.id}'),
            padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.pinned)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: LuqaSpacing.xs,
                      right: LuqaSpacing.sm,
                    ),
                    child: Icon(
                      Icons.push_pin_rounded,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                Expanded(
                  child: Text(note.body, style: theme.textTheme.bodyLarge),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Note options',
                  onSelected: (action) => switch (action) {
                    'pin' => controller.setNotePinned(
                      widget.person.id,
                      noteId: note.id,
                      pinned: !note.pinned,
                    ),
                    _ => controller.removeNote(widget.person.id, note.id),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(note.pinned ? 'Unpin' : 'Pin to top'),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(
                        'Remove',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: LuqaSpacing.md),
        TextField(
          key: const ValueKey('person-note-field'),
          controller: _controller,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Add a note',
            suffixIcon: IconButton(
              key: const ValueKey('person-note-add'),
              tooltip: 'Save note',
              onPressed: _saving ? null : _add,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ),
          onSubmitted: (_) => _add(),
        ),
      ],
    );
  }
}

class _Gifts extends ConsumerStatefulWidget {
  const _Gifts({required this.person});

  final Person person;

  @override
  ConsumerState<_Gifts> createState() => _GiftsState();
}

class _GiftsState extends ConsumerState<_Gifts> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final idea = _controller.text.trim();
    if (idea.isEmpty) return;
    final ok = await ref
        .read(peopleControllerProvider.notifier)
        .addGift(widget.person.id, idea: idea);
    if (!mounted) return;
    if (ok) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ref.read(peopleControllerProvider.notifier);
    final gifts = widget.person.gifts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(title: 'Gift ideas'),
        if (gifts.isEmpty)
          Text(
            'Anything caught here shows up when their birthday comes round.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        for (final gift in gifts)
          Row(
            key: ValueKey('gift-${gift.id}'),
            children: [
              Checkbox(
                value: gift.isGiven,
                onChanged: (given) => controller.setGiftGiven(
                  widget.person.id,
                  giftId: gift.id,
                  givenAt: given == true ? DateTime.now() : null,
                ),
              ),
              Expanded(
                child: Text(
                  gift.idea,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    // Given ideas stay on the list — the second job of a gift
                    // list is not giving the same book twice — but they stop
                    // reading as plans.
                    color: gift.isGiven
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                    decoration: gift.isGiven ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove idea',
                onPressed: () =>
                    controller.removeGift(widget.person.id, gift.id),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        const SizedBox(height: LuqaSpacing.md),
        TextField(
          key: const ValueKey('person-gift-field'),
          controller: _controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Add a gift idea',
            suffixIcon: IconButton(
              key: const ValueKey('person-gift-add'),
              tooltip: 'Save idea',
              onPressed: _add,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ),
          onSubmitted: (_) => _add(),
        ),
      ],
    );
  }
}

class _Places extends ConsumerWidget {
  const _Places({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(peopleControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(title: 'Where they are'),
        if (person.places.isEmpty)
          Text(
            'No city yet, so they will not turn up when you are travelling.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        for (final place in person.places)
          Padding(
            key: ValueKey('place-${place.id}'),
            padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.sm),
            child: Row(
              children: [
                Icon(
                  place.isPrimary
                      ? Icons.location_on_rounded
                      : Icons.location_on_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: LuqaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.shortLocation, style: theme.textTheme.bodyLarge),
                      Text(
                        place.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove place',
                  onPressed: () => controller.removePlace(person.id, place.id),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        const SizedBox(height: LuqaSpacing.sm),
        TextButton.icon(
          key: const ValueKey('person-add-place'),
          onPressed: () => _addPlace(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add a city'),
        ),
      ],
    );
  }

  Future<void> _addPlace(BuildContext context, WidgetRef ref) async {
    final choice = await showCityPickerSheet(
      context,
      // The first city is primary whether or not anybody asks, so there is
      // nothing to offer until there is a second one.
      canChoosePrimary: person.places.isNotEmpty,
    );
    if (choice == null || choice.name.trim().isEmpty) return;
    await ref
        .read(peopleControllerProvider.notifier)
        .addPlace(
          person.id,
          label: choice.label,
          city: choice.name,
          chosen: choice.city,
          isPrimary: choice.isPrimary,
        );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final birthday = person.birthday;

    final rows = <(String, String)>[
      if (birthday != null) ('Birthday', formatBirthday(birthday)),
      (
        'Stay in touch',
        person.cadenceDays == null
            ? 'No rhythm set'
            : 'Every ${describeCadence(person.cadenceDays!)}',
      ),
      for (final channel in person.channels)
        (channel.label ?? _channelName(channel.kind), channel.value),
      (
        'Google Contacts',
        // Said plainly either way: whether a row is linked decides what a
        // future sync is allowed to touch, and guessing is worse than knowing.
        person.isLinkedToGoogle ? 'Linked' : 'Not linked',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(title: 'Details'),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                ),
                Expanded(
                  child: Text(value, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _channelName(ChannelKind kind) => switch (kind) {
    ChannelKind.phone => 'Phone',
    ChannelKind.email => 'Email',
    ChannelKind.handle => 'Handle',
  };
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LuqaSpacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
