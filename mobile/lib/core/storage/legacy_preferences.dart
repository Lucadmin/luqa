import 'dart:convert';

import 'package:luqa/core/storage/luqa_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Moves what earlier builds kept in shared preferences into [LuqaStore].
///
/// Only the queues and the discard log are actually carried over. Those hold
/// work the user did that nothing else remembers — a bill split in a basement
/// that has not reached the server yet — and losing them on an app update
/// would be the exact failure the outbox exists to prevent. The read caches
/// are merely deleted: they are copies of rows the server still has, so the
/// next load refills them.
///
/// Every step is best-effort and swallowed. A migration that fails must leave
/// a working app behind, and on a fresh install there is nothing here at all.
///
/// Deletable once every device has run a build containing it.
abstract final class LegacyPreferences {
  /// One pass per namespace per launch, however many stores ask for it.
  static final Map<String, Future<void>> _passes = {};

  static Future<void> migrate(LuqaStore store, String namespace) =>
      _passes.putIfAbsent(namespace, () => _migrate(store, namespace));

  static Future<void> _migrate(LuqaStore store, String namespace) async {
    final SharedPreferencesAsync preferences;
    try {
      preferences = SharedPreferencesAsync();
    } on Object {
      return;
    }

    final encoded = base64Url.encode(utf8.encode(namespace));
    for (final feature in const ['timeline', 'money', 'gym']) {
      await _carry(
        store,
        preferences,
        namespace: namespace,
        collection: 'outbox.$feature',
        legacyKey: 'luqa.outbox.$feature.v1.$encoded',
      );
      await _carry(
        store,
        preferences,
        namespace: namespace,
        collection: 'discarded.$feature',
        legacyKey: 'luqa.discarded.$feature.v1.$encoded',
      );
    }

    for (final key in [
      'luqa.timeline.v2.$encoded.categories',
      'luqa.timeline.v2.$encoded.window',
      'luqa.money.v1.$encoded.overview',
      'luqa.money.v1.$encoded.expenses',
      'luqa.gym.v1.$encoded.overview',
      'luqa.gym.v1.$encoded.sessions',
    ]) {
      try {
        await preferences.remove(key);
      } on Object {
        // Nothing depends on the old copy going away.
      }
    }
  }

  /// Moves one JSON list across, then forgets the old key so this never runs
  /// twice for it. The absence of the key is the record that it is done.
  static Future<void> _carry(
    LuqaStore store,
    SharedPreferencesAsync preferences, {
    required String namespace,
    required String collection,
    required String legacyKey,
  }) async {
    try {
      final encoded = await preferences.getString(legacyKey);
      if (encoded == null) return;
      final items = [
        for (final item in jsonDecode(encoded) as List<Object?>)
          jsonEncode(item),
      ];
      // Only into an empty collection: if this device has already queued work
      // under the new store, that queue is the newer truth and replacing it
      // would undo writes the user has since made.
      if (items.isNotEmpty) {
        final existing = await store.readRecords(
          namespace: namespace,
          collection: collection,
        );
        if (existing.isEmpty) {
          await store.replaceRecords(
            namespace: namespace,
            collection: collection,
            values: items,
          );
        }
      }
      await preferences.remove(legacyKey);
    } on Object {
      // An unreadable legacy blob is exactly what the old store would have
      // thrown away itself on the next read.
    }
  }
}
