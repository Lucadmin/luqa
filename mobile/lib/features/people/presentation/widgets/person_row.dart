import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';
import 'package:luqa/features/people/domain/person.dart';

/// One person, as a row on a continuous surface.
///
/// A card per person would turn thirty-eight friends into thirty-eight
/// competing objects. The name carries the row; everything else is one quiet
/// supporting line.
class PersonRow extends StatelessWidget {
  const PersonRow({
    required this.person,
    required this.onTap,
    this.detail,
    this.trailing,
    super.key,
  });

  final Person person;
  final VoidCallback onTap;

  /// The supporting line. Falls back to the person's city when not given.
  final String? detail;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supporting = detail ?? person.primaryPlace?.city;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.md),
        child: Row(
          children: [
            PersonAvatar(
              name: person.name,
              colorValue: person.colorValue,
              emoji: person.emoji,
              dimmed: person.archived,
            ),
            const SizedBox(width: LuqaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (supporting != null && supporting.isNotEmpty) ...[
                    const SizedBox(height: LuqaSpacing.xxs),
                    Text(
                      supporting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: LuqaSpacing.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
