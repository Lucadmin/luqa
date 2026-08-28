import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/health/data/health_connect_reader.dart';
import 'package:luqa/features/health/data/health_sync_store.dart';
import 'package:luqa_api/api.dart' as api;

/// How far back a first sync reaches. Health Connect only guarantees 30 days of
/// history without the extra read-history permission, so asking for more would
/// promise data the platform will not hand over.
const kInitialBackfill = Duration(days: 30);

/// Overlap re-read on every incremental sync. Trackers revise a night for a
/// while after you wake up, so the last few days are read again rather than
/// trusted as final.
const kResyncOverlap = Duration(days: 3);

/// Minimum gap between automatic syncs. A night lands once a day, so anything
/// tighter just spends battery re-reading sessions that have not changed. It is
/// measured from the last *attempt*, so a failing sync backs off too.
const kAutoSyncMinInterval = Duration(minutes: 30);

enum HealthSyncStage { idle, checking, syncing }

class HealthSyncState {
  const HealthSyncState({
    this.availability,
    this.permissionGranted = false,
    this.stage = HealthSyncStage.idle,
    this.lastSyncedAt,
    this.lastResult,
    this.error,
  });

  final HealthAvailability? availability;
  final bool permissionGranted;
  final HealthSyncStage stage;
  final DateTime? lastSyncedAt;
  final String? lastResult;
  final String? error;

  bool get isBusy => stage != HealthSyncStage.idle;

  bool get canSync =>
      availability == HealthAvailability.available && permissionGranted;

  HealthSyncState copyWith({
    HealthAvailability? availability,
    bool? permissionGranted,
    HealthSyncStage? stage,
    DateTime? lastSyncedAt,
    String? lastResult,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) => HealthSyncState(
    availability: availability ?? this.availability,
    permissionGranted: permissionGranted ?? this.permissionGranted,
    stage: stage ?? this.stage,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    lastResult: clearResult ? null : (lastResult ?? this.lastResult),
    error: clearError ? null : (error ?? this.error),
  );
}

final healthReaderProvider = Provider<HealthReader>(
  (ref) => HealthConnectReader(),
);

final healthSyncStoreProvider = Provider<HealthSyncStore>(
  (ref) => SharedPreferencesHealthSyncStore(),
);

final healthSyncControllerProvider =
    NotifierProvider<HealthSyncController, HealthSyncState>(
      HealthSyncController.new,
    );

class HealthSyncController extends Notifier<HealthSyncState> {
  late HealthReader _reader;
  late HealthSyncStore _store;
  late LuqaApi _api;

  @override
  HealthSyncState build() {
    _reader = ref.watch(healthReaderProvider);
    _store = ref.watch(healthSyncStoreProvider);
    _api = ref.watch(luqaApiProvider);
    return const HealthSyncState();
  }

  /// Reads platform availability and permission status without prompting.
  Future<void> refreshStatus() async {
    state = state.copyWith(stage: HealthSyncStage.checking, clearError: true);
    try {
      final availability = await _reader.availability();
      final granted = availability == HealthAvailability.available
          ? await _reader.hasPermissions()
          : false;
      state = state.copyWith(
        availability: availability,
        permissionGranted: granted,
        lastSyncedAt: await _store.lastSyncedAt(),
        stage: HealthSyncStage.idle,
      );
    } on Object catch (error) {
      state = state.copyWith(
        stage: HealthSyncStage.idle,
        error: _message(error),
      );
    }
  }

  Future<void> openInstall() => _reader.openInstall();

  /// Prompts for Health Connect access, then syncs immediately if granted, so
  /// granting permission visibly does something.
  Future<void> requestPermission() async {
    state = state.copyWith(stage: HealthSyncStage.checking, clearError: true);
    try {
      final granted = await _reader.requestPermissions();
      state = state.copyWith(
        permissionGranted: granted,
        stage: HealthSyncStage.idle,
        error: granted ? null : 'Health Connect access was not granted.',
      );
      if (granted) await sync();
    } on Object catch (error) {
      state = state.copyWith(
        stage: HealthSyncStage.idle,
        error: _message(error),
      );
    }
  }

  /// Syncs without being asked, on launch and on every resume.
  ///
  /// Silent by design: it never prompts for permission, never shows a spinner
  /// for the availability check, and swallows failures. A persistently broken
  /// sync still surfaces — the tile's "last synced" label goes stale — but a
  /// single offline moment must not leave a red error sitting in Settings.
  Future<void> autoSync() async {
    if (state.isBusy) return;

    final attempted = await _store.lastAttemptedAt();
    if (attempted != null &&
        DateTime.now().difference(attempted) < kAutoSyncMinInterval) {
      return;
    }

    try {
      if (await _reader.availability() != HealthAvailability.available) return;
      if (!await _reader.hasPermissions()) return;
    } on Object {
      return;
    }

    // Reflect what the quiet check just learned, so opening Settings after an
    // automatic sync shows the real state rather than "Checking availability…".
    state = state.copyWith(
      availability: HealthAvailability.available,
      permissionGranted: true,
    );
    await sync(auto: true);
  }

  /// Reads the device and pushes to the server.
  ///
  /// The window always starts far enough back to re-read recently revised
  /// nights, and the push carries it so the server can reconcile deletions
  /// inside exactly the range that was re-read.
  Future<void> sync({bool full = false, bool auto = false}) async {
    if (state.isBusy) return;
    state = state.copyWith(
      stage: HealthSyncStage.syncing,
      clearError: true,
      clearResult: true,
    );

    try {
      final now = DateTime.now();
      // Recorded before the work, not after: a sync that hangs or throws must
      // still push the next automatic attempt out by the throttle interval.
      await _store.setLastAttemptedAt(now);
      final backfilled = await _store.backfilledThrough();
      final from = full || backfilled == null
          ? now.subtract(kInitialBackfill)
          : _earlier(
              now.subtract(kResyncOverlap),
              backfilled.add(const Duration(seconds: 1)),
            );
      // Reach slightly past now: a session that ends a moment from now still
      // belongs in this window.
      final to = now.add(const Duration(hours: 1));

      final read = await _reader.read(from: from, to: to);
      final response = await _api.pushHealthSync(
        api.HealthSyncRequest(
          source_: api.Optional.present(api.DeviceHealthSource.HEALTH_CONNECT),
          sleep: api.Optional.present(
            api.SleepSyncPayload(
              entries: api.Optional.present(read.sleep),
              window: api.Optional.present(
                api.SleepSyncWindow(from: from.toUtc(), to: to.toUtc()),
              ),
            ),
          ),
          samples: api.Optional.present(read.samples),
        ),
      );

      await _store.setLastSyncedAt(now);
      if (full || backfilled == null) await _store.setBackfilledThrough(from);

      state = state.copyWith(
        stage: HealthSyncStage.idle,
        lastSyncedAt: now,
        lastResult: _summary(response),
      );
    } on Object catch (error) {
      state = state.copyWith(
        stage: HealthSyncStage.idle,
        error: auto ? null : _message(error),
      );
    }
  }

  static DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  String _summary(api.HealthSyncResponse response) {
    final imported = response.sleep.imported;
    final removed = response.sleep.deleted;
    final sessions = imported == 1 ? '1 night' : '$imported nights';
    final samples = response.samples.imported;
    return [
      'Synced $sessions',
      if (removed > 0) '$removed removed',
      if (samples > 0) '$samples samples',
    ].join(' · ');
  }

  String _message(Object error) {
    if (error is SessionExpiredException) {
      return 'Your session expired. Sign in again to sync.';
    }
    if (error is TimeoutException) {
      return 'The server took too long to respond. Check your connection.';
    }
    if (error is api.ApiException) {
      return 'Luqa could not save the sync (${error.code}). Try again.';
    }
    return 'Could not read from Health Connect. Try again.';
  }
}
