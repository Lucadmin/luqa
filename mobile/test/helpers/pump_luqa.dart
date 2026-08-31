import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/app/luqa_app.dart';
import 'package:luqa/app/router.dart';
import 'package:luqa/app/theme_mode_controller.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/auth/domain/auth_user.dart';
import 'package:luqa/features/health/application/health_sync_controller.dart';
import 'package:luqa/features/health/data/health_connect_reader.dart';
import 'package:luqa/features/gym/application/gym_overview_controller.dart';
import 'package:luqa/features/gym/data/gym_cache.dart';
import 'package:luqa/features/gym/data/gym_providers.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/today/data/today_providers.dart';
import 'package:luqa/features/today/presentation/widgets/timeline_view.dart';

import 'fake_health.dart';
import 'fake_gym_repository.dart';
import 'fake_timeline_repository.dart';

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

/// Boots the app with deterministic dependencies and hands back the fake
/// repository, so a test can assert on what was actually written.
Future<FakeTimelineRepository> pumpLuqa(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.light,
  Size size = const Size(412, 915),
  GymRepository? gymRepository,
}) async {
  final repository = FakeTimelineRepository(today: fixedNow);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  luqaRouter.go('/');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // HealthAutoSync is mounted in the signed-in branch of the app, so
        // without these every widget test would reach for real SharedPreferences
        // and the real Health Connect plugin. Auto-sync has its own tests.
        healthReaderProvider.overrideWithValue(
          FakeHealthReader(available: HealthAvailability.unsupportedPlatform),
        ),
        healthSyncStoreProvider.overrideWithValue(InMemoryHealthSyncStore()),
        // Same reason for the write queues: OutboxAutoSync is mounted next to
        // HealthAutoSync, and the real stores want a platform channel.
        outboxProvider.overrideWithValue(const NullOutbox()),
        gymOutboxProvider.overrideWithValue(const NullOutbox()),
        gymCacheProvider.overrideWithValue(const NullGymCache()),
        luqaApiProvider.overrideWithValue(FakeHealthApi()),
        gymRepositoryProvider.overrideWithValue(
          gymRepository ?? FakeGymRepository.sample(),
        ),
        gymNowProvider.overrideWithValue(fixedNow),
        currentTimeProvider.overrideWithValue(fixedNow),
        todayRepositoryProvider.overrideWithValue(repository),
        authControllerProvider.overrideWith(FixedAuthController.new),
        themeModeProvider.overrideWith(
          () => FixedThemeModeController(themeMode),
        ),
      ],
      child: const LuqaApp(),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

/// Taps a point inside the timeline grid, in coordinates relative to the
/// timeline's own top-left rather than the screen's.
Future<void> tapTimelineAt(WidgetTester tester, Offset local) async {
  final origin = tester.getTopLeft(find.byType(TimelineView));
  await tester.tapAt(origin + local);
  await tester.pumpAndSettle();
}
