import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';

class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Component gallery')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _Section(
            title: 'Actions',
            child: Wrap(
              spacing: LuqaSpacing.sm,
              runSpacing: LuqaSpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Primary'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Secondary'),
                ),
                FilledButton(onPressed: null, child: const Text('Disabled')),
              ],
            ),
          ),
          _Section(
            title: 'Fields',
            child: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'What did you do?',
                    hintText: 'Describe the activity',
                  ),
                ),
                const SizedBox(height: LuqaSpacing.md),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    errorText: 'Choose a category that still exists',
                    prefixIcon: Icon(
                      Icons.circle,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Identity colors',
            child: Wrap(
              spacing: LuqaSpacing.lg,
              runSpacing: LuqaSpacing.md,
              children: [
                _Swatch('Purple', theme.colorScheme.primary),
                _Swatch('Blue', palette.blue),
                _Swatch('Teal', palette.teal),
                _Swatch('Green', palette.green),
                _Swatch('Amber', palette.amber),
                _Swatch('Orange', palette.orange),
                _Swatch('Pink', palette.pink),
              ],
            ),
          ),
          _Section(
            title: 'Feedback',
            child: Column(
              children: [
                _FeedbackRow(
                  icon: Icons.cloud_done_outlined,
                  label: 'Saved and synced',
                  color: palette.green,
                ),
                const Divider(),
                _FeedbackRow(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Waiting to sync',
                  color: palette.amber,
                ),
                const Divider(),
                _FeedbackRow(
                  icon: Icons.error_outline_rounded,
                  label: 'Needs attention',
                  color: theme.colorScheme.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: LuqaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: LuqaSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label identity color',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox.square(dimension: 14),
          ),
          const SizedBox(width: LuqaSpacing.sm),
          Text(label),
        ],
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: LuqaSpacing.md),
          Text(label),
        ],
      ),
    );
  }
}
