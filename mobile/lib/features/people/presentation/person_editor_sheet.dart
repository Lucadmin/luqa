import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/presentation/widgets/identity_picker.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';
import 'package:luqa/features/people/application/people_controller.dart';
import 'package:luqa/features/people/data/people_repository.dart';
import 'package:luqa/features/people/domain/person.dart';

/// Adding or editing someone from the People tab.
///
/// [person] null means a new person. Returns them once the device has recorded
/// them, which is immediately.
Future<Person?> showPersonEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  Person? person,
}) {
  return showModalBottomSheet<Person>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _PersonEditorSheet(person: person),
    ),
  );
}

class _PersonEditorSheet extends ConsumerStatefulWidget {
  const _PersonEditorSheet({required this.person});

  final Person? person;

  @override
  ConsumerState<_PersonEditorSheet> createState() => _PersonEditorSheetState();
}

class _PersonEditorSheetState extends ConsumerState<_PersonEditorSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.person?.name ?? '',
  );
  late final TextEditingController _nickname = TextEditingController(
    text: widget.person?.nickname ?? '',
  );

  late int _colorValue = widget.person?.colorValue ?? identitySpectrum.first;
  late String? _emoji = widget.person?.emoji;
  late Birthday? _birthday = widget.person?.birthday;
  late int? _cadenceDays = widget.person?.cadenceDays;
  bool _saving = false;

  bool get _isEdit => widget.person != null;

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = ref.read(peopleNowProvider);
    final existing = _birthday;
    final picked = await showDatePicker(
      context: context,
      initialDate: existing == null
          ? DateTime(now.year - 30, now.month, now.day)
          : DateTime(existing.year ?? now.year - 30, existing.month, existing.day),
      firstDate: DateTime(now.year - 120),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Birthday',
    );
    if (picked == null) return;
    setState(
      () => _birthday = Birthday(
        month: picked.month,
        day: picked.day,
        // The picker always yields a year. Keeping whichever one was already
        // known matters more than the one the picker defaulted to: a contact
        // synced without a year must not silently acquire an invented age.
        year: existing != null && !existing.hasYear ? null : picked.year,
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);

    final controller = ref.read(peopleControllerProvider.notifier);
    final nickname = _nickname.text.trim();
    final existing = widget.person;

    if (existing == null) {
      final created = await controller.addPerson(
        PersonWrite(
          name: name,
          colorValue: _colorValue,
          emoji: _emoji,
          nickname: nickname.isEmpty ? null : nickname,
          birthday: _birthday,
          cadenceDays: _cadenceDays,
        ),
      );
      if (!mounted) return;
      if (created == null) {
        setState(() => _saving = false);
        return;
      }
      Navigator.of(context).pop(created);
      return;
    }

    final ok = await controller.updatePerson(
      id: existing.id,
      name: name,
      colorValue: _colorValue,
      emoji: _emoji,
      clearEmoji: _emoji == null,
      nickname: nickname.isEmpty ? null : nickname,
      clearNickname: nickname.isEmpty,
      birthday: _birthday,
      clearBirthday: _birthday == null,
      cadenceDays: _cadenceDays,
      clearCadence: _cadenceDays == null,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      return;
    }
    Navigator.of(
      context,
    ).pop(ref.read(peopleControllerProvider).byId(existing.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _name.text.trim();
    final birthday = _birthday;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          LuqaSpacing.lg,
          0,
          LuqaSpacing.lg,
          LuqaSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PersonAvatar(
                  name: name.isEmpty ? '?' : name,
                  colorValue: _colorValue,
                  emoji: _emoji,
                  size: 44,
                ),
                const SizedBox(width: LuqaSpacing.md),
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit person' : 'New person',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LuqaSpacing.lg),
            TextField(
              key: const ValueKey('person-name'),
              controller: _name,
              autofocus: !_isEdit,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: LuqaSpacing.md),
            TextField(
              key: const ValueKey('person-nickname'),
              controller: _nickname,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                helperText: 'What you actually call them',
              ),
            ),
            const SizedBox(height: LuqaSpacing.xl),
            _FieldLabel('Birthday'),
            const SizedBox(height: LuqaSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('person-birthday'),
                    onPressed: _pickBirthday,
                    child: Text(
                      birthday == null
                          ? 'Add a birthday'
                          : formatBirthday(birthday),
                    ),
                  ),
                ),
                if (birthday != null)
                  IconButton(
                    tooltip: 'Clear birthday',
                    onPressed: () => setState(() => _birthday = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: LuqaSpacing.xl),
            _FieldLabel('Stay in touch'),
            const SizedBox(height: LuqaSpacing.xs),
            Text(
              // Said plainly, because an empty cadence is the right answer for
              // most people and the field should not imply otherwise.
              'Optional. Only people with a rhythm ever show up as overdue.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: LuqaSpacing.sm),
            _CadencePicker(
              selected: _cadenceDays,
              onChanged: (value) => setState(() => _cadenceDays = value),
            ),
            const SizedBox(height: LuqaSpacing.xl),
            _FieldLabel('Colour'),
            const SizedBox(height: LuqaSpacing.sm),
            IdentityColorPicker(
              selected: _colorValue,
              onChanged: (value) => setState(() => _colorValue = value),
            ),
            const SizedBox(height: LuqaSpacing.lg),
            _FieldLabel('Glyph'),
            const SizedBox(height: LuqaSpacing.sm),
            IdentityEmojiPicker(
              selected: _emoji,
              onChanged: (value) => setState(() => _emoji = value),
            ),
            const SizedBox(height: LuqaSpacing.xl),
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const ValueKey('person-save'),
                onPressed: name.isEmpty || _saving ? null : _save,
                child: Text(_isEdit ? 'Save changes' : 'Add person'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// The rhythms people actually keep, plus off.
///
/// A free-text number of days would be more flexible and less usable: nobody
/// thinks "every 91 days".
class _CadencePicker extends StatelessWidget {
  const _CadencePicker({required this.selected, required this.onChanged});

  final int? selected;
  final ValueChanged<int?> onChanged;

  static const _options = <(String, int?)>[
    ('Off', null),
    ('Monthly', 30),
    ('Every 3 months', 91),
    ('Every 6 months', 182),
    ('Yearly', 365),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LuqaSpacing.sm,
      runSpacing: LuqaSpacing.sm,
      children: [
        for (final (label, days) in _options)
          ChoiceChip(
            key: ValueKey('cadence-${days ?? 'off'}'),
            label: Text(label),
            selected: selected == days,
            onSelected: (_) => onChanged(days),
          ),
      ],
    );
  }
}

/// "14 March" without a year, "14 March 1997" with one.
String formatBirthday(Birthday birthday) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final month = months[birthday.month - 1];
  return birthday.hasYear
      ? '${birthday.day} $month ${birthday.year}'
      : '${birthday.day} $month';
}

/// Kept beside the editor because both the sheet and the person screen need to
/// filter a typed number the same way.
final birthdayDigits = FilteringTextInputFormatter.digitsOnly;
