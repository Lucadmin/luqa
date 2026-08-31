import 'dart:convert';

import 'package:luqa/core/storage/legacy_preferences.dart';
import 'package:luqa/core/storage/luqa_store.dart';

/// One feature's user-scoped read cache, as a set of named JSON documents.
///
/// Every cache in the app wants the same four things — read a document, write
/// it, forget one that will not parse, and stop a collection of them growing
/// for ever — so they are written once here rather than three times over.
class DocumentCache {
  DocumentCache({
    required this.namespace,
    required this.collection,
    LuqaStore? store,
  }) : _store = store ?? LuqaStore.shared;

  final String namespace;
  final String collection;
  final LuqaStore _store;

  late final Future<void> _migrated = LegacyPreferences.migrate(
    _store,
    namespace,
  );

  /// The document at [key], or null when there is none — or when what is
  /// there cannot be read, which is the same thing to a caller and is cleaned
  /// up on the way past so it cannot fail twice.
  Future<T?> read<T extends Object>(String key) async {
    await _migrated;
    final encoded = await _store.readDocument(
      namespace: namespace,
      collection: collection,
      key: key,
    );
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is T) return decoded;
    } on Object {
      // Fall through: unreadable and wrongly shaped are both "not a cache".
    }
    await remove(key);
    return null;
  }

  Future<void> write(String key, Object value) async {
    await _migrated;
    await _store.writeDocument(
      namespace: namespace,
      collection: collection,
      key: key,
      value: jsonEncode(value),
    );
  }

  Future<void> remove(String key) async {
    await _migrated;
    await _store.removeDocument(
      namespace: namespace,
      collection: collection,
      key: key,
    );
  }

  /// Keeps only the [keep] most recently written documents. For collections
  /// keyed by row id, where the cache is a window onto what was opened
  /// recently rather than a fixed set of names.
  Future<void> trim(int keep) async {
    await _migrated;
    await _store.trimDocuments(
      namespace: namespace,
      collection: collection,
      keep: keep,
    );
  }
}
