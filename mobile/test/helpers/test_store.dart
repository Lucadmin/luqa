import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/storage/luqa_store.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A database of this test's very own.
///
/// Deliberately not `inMemoryDatabasePath`: `flutter test` runs test files
/// concurrently in one process, and every `:memory:` open through the same ffi
/// factory reaches the same handle. Eight suites sharing one database is eight
/// suites reading each other's rows, which shows up as a test that passes on
/// its own and fails about one run in five.
///
/// A temp file per store costs a few milliseconds and cannot be shared by
/// accident. Closed and deleted when the test ends.
LuqaStore openTestStore() {
  sqfliteFfiInit();
  final directory = Directory.systemTemp.createTempSync('luqa-test-');
  final store = LuqaStore(
    factory: databaseFactoryFfi,
    path: p.join(directory.path, 'luqa.db'),
  );
  addTearDown(() async {
    await store.close();
    try {
      directory.deleteSync(recursive: true);
    } on FileSystemException {
      // A temp directory that will not delete is not worth failing a passing
      // test over; the operating system clears it soon enough.
    }
  });
  return store;
}
