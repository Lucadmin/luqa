import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authentication = ref.watch(authControllerProvider);
    final user = authentication.value?.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(
                      user?.initial ?? 'L',
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: LuqaSpacing.lg),
                  Text(
                    user?.displayName ?? 'Luqa',
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: LuqaSpacing.sm),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: LuqaSpacing.section),
                  const Divider(),
                  const SizedBox(height: LuqaSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: authentication.isLoading
                          ? null
                          : () => ref
                                .read(authControllerProvider.notifier)
                                .signOut(),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        authentication.isLoading ? 'Signing out…' : 'Sign out',
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
