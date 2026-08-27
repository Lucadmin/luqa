import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/app/luqa_app.dart';
import 'package:luqa/app/router.dart';
import 'package:luqa/app/theme_mode_controller.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/auth/domain/auth_user.dart';
import 'package:luqa/features/today/application/today_controller.dart';
import 'package:luqa/features/today/data/fake_today_repository.dart';

final fixedNow = DateTime(2026, 8, 27, 15);

class FixedThemeModeController extends ThemeModeController {
  FixedThemeModeController(this.mode);

  final ThemeMode mode;

  @override
  ThemeMode build() => mode;
}

class FixedAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.signedIn(
    AuthUser(id: 'luca', email: 'luca@example.com', name: 'Luca'),
  );
}

Future<void> pumpLuqa(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.light,
  Size size = const Size(412, 915),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  luqaRouter.go('/');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentTimeProvider.overrideWithValue(fixedNow),
        todayRepositoryProvider.overrideWithValue(FakeTodayRepository()),
        authControllerProvider.overrideWith(FixedAuthController.new),
        themeModeProvider.overrideWith(
          () => FixedThemeModeController(themeMode),
        ),
      ],
      child: const LuqaApp(),
    ),
  );
  await tester.pumpAndSettle();
}
