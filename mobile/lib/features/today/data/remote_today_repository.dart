import 'dart:convert';

import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa_api/api.dart' as api;
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class TodayCache {
  Future<TodaySnapshot?> read(DateTime day);

  Future<void> write(TodaySnapshot snapshot);
}

class SharedPreferencesTodayCache implements TodayCache {
  SharedPreferencesTodayCache({
    required String namespace,
    SharedPreferencesAsync? preferences,
  }) : _namespace = base64Url.encode(utf8.encode(namespace)),
       _preferences = preferences ?? SharedPreferencesAsync();

  final String _namespace;
  final SharedPreferencesAsync _preferences;

  String _key(DateTime day) =>
      'luqa.today.v1.$_namespace.${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  @override
  Future<TodaySnapshot?> read(DateTime day) async {
    final encoded = await _preferences.getString(_key(day));
    if (encoded == null) return null;
    try {
      final value = jsonDecode(encoded) as Map<String, Object?>;
      final categories = (value['categories']! as List<Object?>)
          .map((item) => item! as Map<String, Object?>)
          .map(_categoryFromJson)
          .toList(growable: false);
      final entries = (value['entries']! as List<Object?>)
          .map((item) => item! as Map<String, Object?>)
          .map(_entryFromJson)
          .toList(growable: false);
      return TodaySnapshot(
        day: DateTime(day.year, day.month, day.day),
        entries: entries,
        categories: categories,
        recentActivities: _recentActivities(entries),
        habits: const [],
        sleep: null,
      );
    } on Object {
      await _preferences.remove(_key(day));
      return null;
    }
  }

  @override
  Future<void> write(TodaySnapshot snapshot) => _preferences.setString(
    _key(snapshot.day),
    jsonEncode({
      'version': 1,
      'categories': snapshot.categories.map(_categoryToJson).toList(),
      'entries': snapshot.entries.map(_entryToJson).toList(),
    }),
  );
}

class RemoteTodayRepository implements TodayRepository {
  RemoteTodayRepository({required this.client, required this.cache});

  final LuqaApi client;
  final TodayCache cache;
  TodaySnapshot? _latest;

  @override
  Future<TodaySnapshot?> loadCached(DateTime day) async {
    final cached = await cache.read(day);
    _latest = cached;
    return cached;
  }

  @override
  Future<TodaySnapshot> refresh(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final results = await Future.wait<Object>([
      client.listCategories(),
      client.listTimeEntries(start, end),
    ]);
    final categories = (results[0] as List<api.Category>)
        .where((category) => !category.archived)
        .map(_categoryFromApi)
        .toList(growable: false);
    final entries =
        (results[1] as List<api.TimeEntry>)
            .map(_entryFromApi)
            .toList(growable: false)
          ..sort((left, right) => left.start.compareTo(right.start));
    final snapshot = TodaySnapshot(
      day: start,
      entries: entries,
      categories: categories,
      recentActivities: _recentActivities(entries),
      habits: const [],
      sleep: null,
    );
    _latest = snapshot;
    await cache.write(snapshot);
    return snapshot;
  }

  @override
  Future<TimeEntry> addEntry(NewTimeEntry draft) async {
    final created = _entryFromApi(
      await client.createTimeEntry(
        description: draft.description,
        categoryId: draft.categoryId,
        start: draft.start,
        end: draft.end,
      ),
    );
    final latest = _latest;
    if (latest != null) {
      final entries = [...latest.entries, created]
        ..sort((left, right) => left.start.compareTo(right.start));
      _latest = TodaySnapshot(
        day: latest.day,
        entries: entries,
        categories: latest.categories,
        recentActivities: _recentActivities(entries),
        habits: latest.habits,
        sleep: latest.sleep,
      );
      await cache.write(_latest!);
    }
    return created;
  }

  @override
  Future<Category> addCategory(String name) async {
    final created = _categoryFromApi(await client.createCategory(name));
    final latest = _latest;
    if (latest != null &&
        !latest.categories.any((category) => category.id == created.id)) {
      final categories = [...latest.categories, created]
        ..sort((left, right) => left.name.compareTo(right.name));
      _latest = TodaySnapshot(
        day: latest.day,
        entries: latest.entries,
        categories: categories,
        recentActivities: latest.recentActivities,
        habits: latest.habits,
        sleep: latest.sleep,
      );
      await cache.write(_latest!);
    }
    return created;
  }
}

Category _categoryFromApi(api.Category value) => Category(
  id: value.id,
  name: value.name,
  colorValue: _colorValue(value.color),
);

TimeEntry _entryFromApi(api.TimeEntry value) => TimeEntry(
  id: value.id,
  description: value.description,
  categoryId: value.categoryId,
  start: value.startTime.toLocal(),
  end: value.endTime?.toLocal(),
);

int _colorValue(String value) {
  final hex = value.startsWith('#') ? value.substring(1) : value;
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? 0xFF6543E8 : 0xFF000000 | parsed;
}

Map<String, Object?> _categoryToJson(Category value) => {
  'id': value.id,
  'name': value.name,
  'colorValue': value.colorValue,
};

Category _categoryFromJson(Map<String, Object?> value) => Category(
  id: value['id']! as String,
  name: value['name']! as String,
  colorValue: value['colorValue']! as int,
);

Map<String, Object?> _entryToJson(TimeEntry value) => {
  'id': value.id,
  'description': value.description,
  'categoryId': value.categoryId,
  'start': value.start.toUtc().toIso8601String(),
  'end': value.end?.toUtc().toIso8601String(),
};

TimeEntry _entryFromJson(Map<String, Object?> value) => TimeEntry(
  id: value['id']! as String,
  description: value['description']! as String,
  categoryId: value['categoryId'] as String?,
  start: DateTime.parse(value['start']! as String).toLocal(),
  end: value['end'] == null
      ? null
      : DateTime.parse(value['end']! as String).toLocal(),
);

List<RecentActivity> _recentActivities(List<TimeEntry> entries) {
  final seen = <String>{};
  final recent = <RecentActivity>[];
  for (final entry in entries.reversed) {
    if (entry.description.trim().isEmpty && entry.categoryId == null) continue;
    final key = '${entry.description.trim()}\u0000${entry.categoryId ?? ''}';
    if (!seen.add(key)) continue;
    recent.add(
      RecentActivity(
        description: entry.description,
        categoryId: entry.categoryId,
      ),
    );
    if (recent.length == 5) break;
  }
  return recent;
}
