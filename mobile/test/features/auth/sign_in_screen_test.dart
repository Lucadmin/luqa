import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/app/luqa_app.dart';
import 'package:luqa/app/theme_mode_controller.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/auth/domain/auth_user.dart';
import 'package:luqa/features/auth/presentation/sign_in_screen.dart';

void main() {
  testWidgets('signed-out launch presents the native credential screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(SignedOutAuthController.new),
          themeModeProvider.overrideWith(LightThemeModeController.new),
        ],
        child: const LuqaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Your life,\nin one place.'), findsOneWidget);
    expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('password-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('sign-in-button')), findsOneWidget);
  });
}

class SignedOutAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.signedOut();
}

class LightThemeModeController extends ThemeModeController {
  @override
  ThemeMode build() => ThemeMode.light;
}
