import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/auth/data/secure_credential_store.dart';
import 'package:luqa/features/health/application/health_sync_controller.dart';
import 'package:luqa/features/health/data/health_connect_reader.dart';
import 'package:luqa_api/api.dart' as api;

import '../../helpers/fake_health.dart';

({ProviderContainer container, FakeHealthReader reader, FakeHealthApi api})
setUpContainer({FakeHealthReader? reader, InMemoryHealthSyncStore? store}) {
  final health = reader ?? FakeHealthReader();
  final luqa = FakeHealthApi();
  final container = ProviderContainer(
    overrides: [
      healthReaderProvider.overrideWithValue(health),
      healthSyncStoreProvider.overrideWithValue(
        store ?? InMemoryHealthSyncStore(),
      ),
      luqaApiProvider.overrideWithValue(luqa),
      secureCredentialStoreProvider.overrideWithValue(_UnusedCredentialStore()),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, reader: health, api: luqa);
}

class _UnusedCredentialStore implements SecureCredentialStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('autoSync', () {
    test(
      'syncs on the first run, when nothing has been attempted yet',
      () async {
        final harness = setUpContainer();

        await harness.container
            .read(healthSyncControllerProvider.notifier)
            .autoSync();

        expect(harness.reader.reads, 1);
        expect(harness.api.pushes, 1);
      },
    );

    test('does not sync again inside the throttle interval', () async {
      final harness = setUpContainer();
      final controller = harness.container.read(
        healthSyncControllerProvider.notifier,
      );

      await controller.autoSync();
      await controller.autoSync();
      await controller.autoSync();

      expect(harness.api.pushes, 1, reason: 'throttled after the first run');
    });

    test('syncs again once the throttle interval has passed', () async {
      final store = InMemoryHealthSyncStore();
      final harness = setUpContainer(store: store);

      await harness.container
          .read(healthSyncControllerProvider.notifier)
          .autoSync();
      // Push the last attempt back beyond the interval.
      await store.setLastAttemptedAt(
        DateTime.now().subtract(kAutoSyncMinInterval * 2),
      );
      await harness.container
          .read(healthSyncControllerProvider.notifier)
          .autoSync();

      expect(harness.api.pushes, 2);
    });

    test(
      'backs off after a failure instead of retrying every resume',
      () async {
        final store = InMemoryHealthSyncStore();
        final harness = setUpContainer(store: store);
        harness.api.pushError = api.ApiException(500, 'boom');
        final controller = harness.container.read(
          healthSyncControllerProvider.notifier,
        );

        await controller.autoSync();
        await controller.autoSync();

        expect(harness.api.pushes, 1);
        expect(await store.lastAttemptedAt(), isNotNull);
        expect(
          await store.lastSyncedAt(),
          isNull,
          reason: 'a failed sync must not look successful',
        );
      },
    );

    test('stays silent about automatic failures', () async {
      final harness = setUpContainer();
      harness.api.pushError = api.ApiException(500, 'boom');

      await harness.container
          .read(healthSyncControllerProvider.notifier)
          .autoSync();

      expect(
        harness.container.read(healthSyncControllerProvider).error,
        isNull,
        reason: 'an unattended failure must not leave an error in Settings',
      );
    });

    test('still reports failures from a manual sync', () async {
      final harness = setUpContainer();
      harness.api.pushError = api.ApiException(500, 'boom');

      await harness.container
          .read(healthSyncControllerProvider.notifier)
          .sync();

      expect(
        harness.container.read(healthSyncControllerProvider).error,
        isNotNull,
      );
    });

    test('does nothing when permission has not been granted', () async {
      final harness = setUpContainer(reader: FakeHealthReader(granted: false));

      await harness.container
          .read(healthSyncControllerProvider.notifier)
          .autoSync();

      expect(harness.reader.reads, 0);
      expect(harness.api.pushes, 0);
    });

    test('never prompts for permission on its own', () async {
      final harness = setUpContainer(reader: FakeHealthReader(granted: false));

      await harness.container
          .read(healthSyncControllerProvider.notifier)
          .autoSync();

      expect(harness.reader.permissionRequests, 0);
    });

    test('does nothing when Health Connect is unavailable', () async {
      final harness = setUpContainer(
        reader: FakeHealthReader(available: HealthAvailability.notInstalled),
      );

      await harness.container
          .read(healthSyncControllerProvider.notifier)
          .autoSync();

      expect(harness.api.pushes, 0);
    });

    test('sends a reconciliation window so deletions can be applied', () async {
      final harness = setUpContainer();

      await harness.container
          .read(healthSyncControllerProvider.notifier)
          .autoSync();

      final sleep = harness.api.requests.single.sleep.value!;
      expect(sleep.window.value, isNotNull);
      expect(sleep.window.value!.to.isAfter(sleep.window.value!.from), isTrue);
    });
  });
}
