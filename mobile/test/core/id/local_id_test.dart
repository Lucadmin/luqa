import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/id/local_id.dart';

void main() {
  test('an id is 26 Crockford base32 characters', () {
    final id = newLocalId();
    expect(id, hasLength(26));
    expect(id, matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$')));
  });

  test('ids mint distinctly even within the same millisecond', () {
    final frozen = DateTime.utc(2026, 8, 31, 12);
    final generator = LocalIdGenerator(now: () => frozen, random: Random(7));

    final ids = [for (var i = 0; i < 500; i++) generator.next()];

    expect(ids.toSet(), hasLength(500));
  });

  test('ids sort in the order they were minted', () {
    var millis = DateTime.utc(2026, 8, 31, 12).millisecondsSinceEpoch;
    final generator = LocalIdGenerator(
      now: () => DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true),
      random: Random(11),
    );

    final ids = <String>[];
    for (var tick = 0; tick < 100; tick++) {
      // Two per millisecond, so the tie-break inside one tick is exercised as
      // well as the timestamp itself.
      ids
        ..add(generator.next())
        ..add(generator.next());
      millis++;
    }

    expect(ids, orderedEquals([...ids]..sort()));
  });

  test('the timestamp survives a round trip through the alphabet', () {
    final at = DateTime.utc(2026, 8, 31, 12, 34, 56);
    final id = LocalIdGenerator(now: () => at, random: Random(1)).next();

    const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
    var decoded = 0;
    for (final char in id.substring(0, 10).split('')) {
      decoded = (decoded << 5) | alphabet.indexOf(char);
    }

    expect(decoded, at.millisecondsSinceEpoch);
  });
}
