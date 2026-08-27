import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/app/theme_mode_controller.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/health/presentation/health_connect_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text('Appearance', style: theme.textTheme.titleLarge),
            const SizedBox(height: LuqaSpacing.md),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) =>
                  ref.read(themeModeProvider.notifier).select(selection.first),
            ),
            const SizedBox(height: LuqaSpacing.section),
            Text('Build tools', style: theme.textTheme.titleLarge),
            const SizedBox(height: LuqaSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 56,
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Component gallery'),
              subtitle: const Text('Theme tokens and reusable primitives'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/gallery'),
            ),
            const SizedBox(height: LuqaSpacing.section),
            Text('Integrations', style: theme.textTheme.titleLarge),
            const SizedBox(height: LuqaSpacing.sm),
            const HealthConnectTile(),
            const Divider(height: LuqaSpacing.section),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 56,
              leading: Icon(Icons.event_outlined),
              title: Text('Calendar'),
              subtitle: Text('Google Calendar sync follows'),
            ),
          ],
        ),
      ),
    );
  }
}
