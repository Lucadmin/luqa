import 'package:shared_preferences/shared_preferences.dart';

/// Device-local sync bookkeeping.
///
/// This lives on the phone rather than the server because it describes what
/// *this install* has read from Health Connect. Reinstalling clears it, which
/// correctly triggers a fresh backfill.
class HealthSyncStore {
  HealthSyncStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _lastSyncKey = 'luqa.health.v1.lastSyncedAt';
  static const _backfilledKey = 'luqa.health.v1.backfilledThrough';

  final SharedPreferencesAsync _preferences;

  Future<DateTime?> lastSyncedAt() => _readTime(_lastSyncKey);

  Future<void> setLastSyncedAt(DateTime value) =>
      _preferences.setString(_lastSyncKey, value.toUtc().toIso8601String());

  /// The oldest point a full read has already covered, so a later sync does not
  /// re-request months of history it has seen.
  Future<DateTime?> backfilledThrough() => _readTime(_backfilledKey);

  Future<void> setBackfilledThrough(DateTime value) =>
      _preferences.setString(_backfilledKey, value.toUtc().toIso8601String());

  Future<void> clear() async {
    await _preferences.remove(_lastSyncKey);
    await _preferences.remove(_backfilledKey);
  }

  Future<DateTime?> _readTime(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }
}
