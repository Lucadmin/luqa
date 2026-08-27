import 'package:flutter/material.dart';

class DestinationPlaceholder extends StatelessWidget {
  const DestinationPlaceholder({
    required this.title,
    required this.icon,
    required this.description,
    super.key,
  });

  final String title;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 30, color: theme.colorScheme.primary),
                const SizedBox(height: 20),
                Text(title, style: theme.textTheme.headlineLarge),
                const SizedBox(height: 10),
                Text(description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 20),
                Text(
                  'The route and adaptive navigation state are ready. Feature '
                  'behavior arrives as a tested vertical slice.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
