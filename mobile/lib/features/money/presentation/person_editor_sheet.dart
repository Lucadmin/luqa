import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/application/money_controller.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/presentation/widgets/identity_picker.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';

/// Adding or restyling someone.
///
/// [person] null means a new person. Returns the person once the device has
/// recorded them, which is immediately.
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
  late final TextEditingController _percent = TextEditingController(
    text: widget.person?.defaultPercent?.toString() ?? '',
  );

  late int _colorValue = widget.person?.colorValue ?? identitySpectrum.first;
  late String? _emoji = widget.person?.emoji;
  bool _saving = false;

  bool get _isEdit => widget.person != null;

  @override
  void dispose() {
    _name.dispose();
    _percent.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);

    final typed = _percent.text.trim();
    final percent = typed.isEmpty ? null : int.tryParse(typed)?.clamp(0, 100);
    final controller = ref.read(moneyControllerProvider.notifier);
    final existing = widget.person;

    if (existing == null) {
      final created = await controller.addPerson(
        PersonWrite(
          name: name,
          colorValue: _colorValue,
          emoji: _emoji,
          defaultPercent: percent,
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
      defaultPercent: percent,
      clearDefaultPercent: percent == null,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      return;
    }
    Navigator.of(context).pop(
      existing.copyWith(
        name: name,
        colorValue: _colorValue,
        emoji: _emoji,
        clearEmoji: _emoji == null,
        defaultPercent: percent,
        clearDefaultPercent: percent == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _name.text.trim();

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
              controller: _name,
              autofocus: !_isEdit,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: LuqaSpacing.xl),
            Text(
              'Colour',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: LuqaSpacing.sm),
            IdentityColorPicker(
              selected: _colorValue,
              onChanged: (value) => setState(() => _colorValue = value),
            ),
            const SizedBox(height: LuqaSpacing.lg),
            Text(
              'Glyph',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: LuqaSpacing.sm),
            IdentityEmojiPicker(
              selected: _emoji,
              onChanged: (value) => setState(() => _emoji = value),
            ),
            const SizedBox(height: LuqaSpacing.xl),
            TextField(
              controller: _percent,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Usual cut',
                suffixText: '%',
                // The everyday default is an even split, so this field exists
                // for the flatmate who always takes 30% — not for everyone.
                helperText: 'Leave empty to share equally',
              ),
            ),
            const SizedBox(height: LuqaSpacing.xl),
            SizedBox(
              height: 52,
              child: FilledButton(
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
