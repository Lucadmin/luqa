import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/app/router.dart';
import 'package:luqa/core/sync/outbox_auto_sync.dart';
import 'package:luqa/app/theme_mode_controller.dart';
import 'package:luqa/design_system/luqa_theme.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/auth/presentation/auth_bootstrap_screen.dart';
import 'package:luqa/features/auth/presentation/sign_in_screen.dart';
import 'package:luqa/features/health/presentation/health_auto_sync.dart';

class LuqaApp extends ConsumerWidget {
  const LuqaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authentication = ref.watch(authControllerProvider);
    final session = authentication.value;

    if (session?.isAuthenticated == true) {
      return OutboxAutoSync(
        child: HealthAutoSync(
          child: MaterialApp.router(
            title: 'Luqa',
            debugShowCheckedModeBanner: false,
            theme: LuqaTheme.light,
            darkTheme: LuqaTheme.dark,
            themeMode: themeMode,
            routerConfig: luqaRouter,
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Luqa',
      debugShowCheckedModeBanner: false,
      theme: LuqaTheme.light,
      darkTheme: LuqaTheme.dark,
      themeMode: themeMode,
      home: authentication.isLoading && session == null
          ? const AuthBootstrapScreen()
          : const SignInScreen(),
    );
  }
}
