import 'package:shared_preferences/shared_preferences.dart';

/// Device-local sync bookkeeping.
///
/// This lives on the phone rather than the server because it describes what
/// *this install* has read from Health Connect. Reinstalling clears it, which
/// correctly triggers a fresh backfill.
abstract interface class HealthSyncStore {
  /// When a sync last succeeded. Drives the "last synced" label.
  Future<DateTime?> lastSyncedAt();

  Future<void> setLastSyncedAt(DateTime value);

  /// When a sync was last *attempted*, successful or not.
  ///
  /// Throttling reads this rather than [lastSyncedAt] so a failing sync backs
  /// off instead of retrying on every single resume.
  Future<DateTime?> lastAttemptedAt();

  Future<void> setLastAttemptedAt(DateTime value);

  /// The oldest point a full read has already covered, so a later sync does not
  /// re-request months of history it has seen.
  Future<DateTime?> backfilledThrough();

  Future<void> setBackfilledThrough(DateTime value);

  Future<void> clear();
}

class SharedPreferencesHealthSyncStore implements HealthSyncStore {
  SharedPreferencesHealthSyncStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _lastSyncKey = 'luqa.health.v1.lastSyncedAt';
  static const _lastAttemptKey = 'luqa.health.v1.lastAttemptedAt';
  static const _backfilledKey = 'luqa.health.v1.backfilledThrough';

  final SharedPreferencesAsync _preferences;

  @override
  Future<DateTime?> lastSyncedAt() => _readTime(_lastSyncKey);

  @override
  Future<void> setLastSyncedAt(DateTime value) =>
      _preferences.setString(_lastSyncKey, value.toUtc().toIso8601String());

  @override
  Future<DateTime?> lastAttemptedAt() => _readTime(_lastAttemptKey);

  @override
  Future<void> setLastAttemptedAt(DateTime value) =>
      _preferences.setString(_lastAttemptKey, value.toUtc().toIso8601String());

  @override
  Future<DateTime?> backfilledThrough() => _readTime(_backfilledKey);

  @override
  Future<void> setBackfilledThrough(DateTime value) =>
      _preferences.setString(_backfilledKey, value.toUtc().toIso8601String());

  @override
  Future<void> clear() async {
    await _preferences.remove(_lastSyncKey);
    await _preferences.remove(_lastAttemptKey);
    await _preferences.remove(_backfilledKey);
  }

  Future<DateTime?> _readTime(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }
}
