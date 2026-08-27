import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/app/router.dart';
import 'package:luqa/app/theme_mode_controller.dart';
import 'package:luqa/design_system/luqa_theme.dart';

class LuqaApp extends ConsumerWidget {
  const LuqaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Luqa',
      debugShowCheckedModeBanner: false,
      theme: LuqaTheme.light,
      darkTheme: LuqaTheme.dark,
      themeMode: themeMode,
      routerConfig: luqaRouter,
    );
  }
}
