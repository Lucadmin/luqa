import 'dart:math';

/// Mints the identity of a row on the device that created it.
///
/// A block drawn on the timeline exists the moment it is drawn, whether or not
/// the phone can reach the server. Without a local id there is nothing for a
/// later edit, delete, or category reference to point at, and a create that is
/// retried after a lost response duplicates the row. Naming it here solves
/// both: the server accepts the id, so a retry is recognised as the same write.
///
/// The format is a ULID — 48 bits of millisecond timestamp followed by 80 bits
/// of randomness, in Crockford base32. It is chosen over a random UUID because
/// ids then sort by creation time, which keeps database indexes and any
/// debugging output in the order things actually happened.
String newLocalId() => _shared.next();

/// Crockford base32: no I, L, O or U, so an id read aloud or copied by hand is
/// hard to get wrong, and lexical order matches byte order.
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

const _timeChars = 10;
const _randomChars = 16;

final _shared = LocalIdGenerator();

/// The generator behind [newLocalId]. Instantiate one directly in tests to pin
/// the clock and the randomness.
class LocalIdGenerator {
  LocalIdGenerator({DateTime Function()? now, Random? random})
    : _now = now ?? DateTime.now,
      _random = random ?? Random.secure();

  final DateTime Function() _now;
  final Random _random;

  int _lastMillis = -1;
  final List<int> _lastRandom = List<int>.filled(_randomChars, 0);

  String next() {
    final millis = _now().toUtc().millisecondsSinceEpoch;
    // Two ids minted in the same millisecond would otherwise sort arbitrarily
    // against each other. Incrementing the previous randomness keeps them in
    // the order they were asked for, which is what the timestamp promises.
    if (millis == _lastMillis) {
      _incrementRandom();
    } else {
      _lastMillis = millis;
      for (var i = 0; i < _randomChars; i++) {
        _lastRandom[i] = _random.nextInt(32);
      }
    }

    final buffer = StringBuffer();
    var remaining = millis;
    final time = List<int>.filled(_timeChars, 0);
    for (var i = _timeChars - 1; i >= 0; i--) {
      time[i] = remaining & 0x1f;
      remaining >>= 5;
    }
    for (final value in time) {
      buffer.write(_alphabet[value]);
    }
    for (final value in _lastRandom) {
      buffer.write(_alphabet[value]);
    }
    return buffer.toString();
  }

  /// Carries from the least significant character up. Overflowing all 80 bits
  /// inside one millisecond is not reachable in practice; rerolling is the
  /// honest answer if it ever happens.
  void _incrementRandom() {
    for (var i = _randomChars - 1; i >= 0; i--) {
      if (_lastRandom[i] < 31) {
        _lastRandom[i]++;
        return;
      }
      _lastRandom[i] = 0;
    }
    for (var i = 0; i < _randomChars; i++) {
      _lastRandom[i] = _random.nextInt(32);
    }
  }
}
