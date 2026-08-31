import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/core/storage/document_cache.dart';
import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa_api/api.dart' as api;

abstract interface class TimelineCache {
  Future<List<Category>?> readCategories();

  Future<void> writeCategories(List<Category> categories);

  Future<TimelineWindow?> readWindow(DateTime from, DateTime to);

  Future<void> writeWindow(TimelineWindow window);
}

/// App-private, user-scoped read cache. It holds the most recent window only —
/// enough to paint a cold start instantly, small enough that it never grows
/// without bound. No credential ever reaches it.
class SqliteTimelineCache implements TimelineCache {
  SqliteTimelineCache({required String namespace, LuqaStore? store})
    : _documents = DocumentCache(
        namespace: namespace,
        collection: 'timeline',
        store: store,
      );

  final DocumentCache _documents;

  @override
  Future<List<Category>?> readCategories() async {
    final value = await _documents.read<List<Object?>>('categories');
    if (value == null) return null;
    try {
      return value
          .map((item) => _categoryFromJson(item! as Map<String, Object?>))
          .toList(growable: false);
    } on Object {
      await _documents.remove('categories');
      return null;
    }
  }

  @override
  Future<void> writeCategories(List<Category> categories) => _documents.write(
    'categories',
    categories.map(_categoryToJson).toList(),
  );

  @override
  Future<TimelineWindow?> readWindow(DateTime from, DateTime to) async {
    final value = await _documents.read<Map<String, Object?>>('window');
    if (value == null) return null;
    try {
      // A cached window for a different range is useless; the caller is
      // looking at other days.
      if (value['from'] != _dayKey(from) || value['to'] != _dayKey(to)) {
        return null;
      }
      return TimelineWindow(
        from: from,
        to: to,
        entries: (value['entries']! as List<Object?>)
            .map((item) => _entryFromJson(item! as Map<String, Object?>))
            .toList(growable: false),
        sleep: (value['sleep']! as List<Object?>)
            .map((item) => _sleepFromJson(item! as Map<String, Object?>))
            .toList(growable: false),
      );
    } on Object {
      await _documents.remove('window');
      return null;
    }
  }

  @override
  Future<void> writeWindow(TimelineWindow window) => _documents.write('window', {
    'from': _dayKey(window.from),
    'to': _dayKey(window.to),
    'entries': window.entries.map(_entryToJson).toList(),
    'sleep': window.sleep.map(_sleepToJson).toList(),
  });
}

class RemoteTodayRepository implements TodayRepository {
  RemoteTodayRepository({required this.client, required this.cache});

  final LuqaApi client;
  final TimelineCache cache;

  @override
  Future<List<Category>?> loadCachedCategories() => cache.readCategories();

  @override
  Future<TimelineWindow?> loadCachedWindow(DateTime from, DateTime to) =>
      cache.readWindow(from, to);

  @override
  Future<List<Category>> loadCategories() async {
    final categories = (await client.listCategories())
        .where((category) => !category.archived)
        .map(_categoryFromApi)
        .toList(growable: false);
    await cache.writeCategories(categories);
    return categories;
  }

  @override
  Future<TimelineWindow> loadWindow(DateTime from, DateTime to) async {
    // Reach a day further back for entries so a block that crosses the
    // window's opening midnight arrives whole.
    final entries =
        (await client.listTimeEntries(
            from.subtract(const Duration(days: 1)),
            to,
          )).map(_entryFromApi).toList(growable: false)
          ..sort((left, right) => left.start.compareTo(right.start));

    // Sleep is context, not the point of the screen. A server that cannot
    // serve it — an older deployment, a transient error — must not take the
    // tracked day down with it.
    final sleep = <SleepEntry>[];
    try {
      // Sleep is attributed to the day it wakes up in, so a session that began
      // the evening before still belongs to this window.
      sleep.addAll(
        (await client.listSleepEntries(from, to)).map(_sleepFromApi),
      );
      sleep.sort((left, right) => left.start.compareTo(right.start));
    } on Object {
      // Leave the day without sleep bands rather than without a timeline.
    }

    final window = TimelineWindow(
      from: from,
      to: to,
      entries: entries,
      sleep: sleep,
    );
    await cache.writeWindow(window);
    return window;
  }

  @override
  Future<TimeEntry> addEntry(NewTimeEntry draft) async => _entryFromApi(
    await client.createTimeEntry(
      id: draft.id,
      description: draft.description,
      categoryId: draft.categoryId,
      start: draft.start,
      end: draft.end,
    ),
  );

  @override
  Future<TimeEntry> updateEntry(TimeEntry entry, EntryPatch patch) =>
      updateEntryById(entry.id, patch);

  /// The queue only carries the id of an edited row, not the row itself.
  Future<TimeEntry> updateEntryById(String id, EntryPatch patch) async {
    return _entryFromApi(
      await client.updateTimeEntry(
        id,
        api.UpdateTimeEntryRequest(
          description: patch.description == null
              ? const api.Optional.absent()
              : api.Optional.present(patch.description),
          categoryId: patch.clearCategory
              ? const api.Optional.present(null)
              : patch.categoryId == null
              ? const api.Optional.absent()
              : api.Optional.present(patch.categoryId),
          startTime: patch.start == null
              ? const api.Optional.absent()
              : api.Optional.present(patch.start!.toUtc()),
          endTime: patch.end == null
              ? const api.Optional.absent()
              : api.Optional.present(patch.end!.toUtc()),
        ),
      ),
    );
  }

  @override
  Future<void> deleteEntry(String id) => client.deleteTimeEntry(id);

  @override
  Future<Category> addCategory(String name) async =>
      _categoryFromApi(await client.createCategory(name));

  /// Creates a category under an id this device already handed out. The server
  /// may answer with a different one when the name is already taken, so the
  /// returned category is the authority.
  Future<Category> addCategoryWithId(Category category) async =>
      _categoryFromApi(
        await client.createCategory(category.name, id: category.id),
      );
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

SleepEntry _sleepFromApi(api.SleepEntry value) => SleepEntry(
  id: value.id,
  source: value.source_.toString(),
  sourceApp: value.sourceApp,
  title: value.title,
  start: value.startTime.toLocal(),
  end: value.endTime.toLocal(),
  sleepMinutes: value.sleepMinutes,
  awakeMinutes: value.awakeMinutes,
  awakeInBedMinutes: value.awakeInBedMinutes,
  outOfBedMinutes: value.outOfBedMinutes,
  lightMinutes: value.lightMinutes,
  deepMinutes: value.deepMinutes,
  remMinutes: value.remMinutes,
  unknownMinutes: value.unknownMinutes,
  inBedMinutes: value.inBedMinutes,
  efficiencyPercent: value.efficiencyPercent?.toDouble(),
  latencyMinutes: value.latencyMinutes,
  wasoMinutes: value.wasoMinutes,
  awakeningCount: value.awakeningCount,
  midpoint: value.midpoint?.toLocal(),
  isNap: value.isNap,
  recordingMethod: value.recordingMethod,
  deviceModel: value.deviceModel,
  stages: value.stages
      .map(
        (stage) => SleepStage(
          stage: stage.stage,
          start: stage.startTime.toLocal(),
          end: stage.endTime.toLocal(),
        ),
      )
      .toList(growable: false),
);

int _colorValue(String value) {
  final hex = value.startsWith('#') ? value.substring(1) : value;
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? 0xFF6543E8 : 0xFF000000 | parsed;
}

String _dayKey(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

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

Map<String, Object?> _sleepToJson(SleepEntry value) => {
  'id': value.id,
  'source': value.source,
  'sourceApp': value.sourceApp,
  'title': value.title,
  'start': value.start.toUtc().toIso8601String(),
  'end': value.end.toUtc().toIso8601String(),
  'sleepMinutes': value.sleepMinutes,
  'awakeMinutes': value.awakeMinutes,
  'awakeInBedMinutes': value.awakeInBedMinutes,
  'outOfBedMinutes': value.outOfBedMinutes,
  'lightMinutes': value.lightMinutes,
  'deepMinutes': value.deepMinutes,
  'remMinutes': value.remMinutes,
  'unknownMinutes': value.unknownMinutes,
  'inBedMinutes': value.inBedMinutes,
  'efficiencyPercent': value.efficiencyPercent,
  'latencyMinutes': value.latencyMinutes,
  'wasoMinutes': value.wasoMinutes,
  'awakeningCount': value.awakeningCount,
  'midpoint': value.midpoint?.toUtc().toIso8601String(),
  'isNap': value.isNap,
  'recordingMethod': value.recordingMethod,
  'deviceModel': value.deviceModel,
  'stages': [
    for (final stage in value.stages)
      {
        'stage': stage.stage,
        'start': stage.start.toUtc().toIso8601String(),
        'end': stage.end.toUtc().toIso8601String(),
      },
  ],
};

SleepEntry _sleepFromJson(Map<String, Object?> value) => SleepEntry(
  id: value['id']! as String,
  source: value['source']! as String,
  sourceApp: value['sourceApp'] as String?,
  title: value['title'] as String?,
  start: DateTime.parse(value['start']! as String).toLocal(),
  end: DateTime.parse(value['end']! as String).toLocal(),
  sleepMinutes: value['sleepMinutes'] as int?,
  awakeMinutes: value['awakeMinutes'] as int?,
  awakeInBedMinutes: value['awakeInBedMinutes'] as int?,
  outOfBedMinutes: value['outOfBedMinutes'] as int?,
  lightMinutes: value['lightMinutes'] as int?,
  deepMinutes: value['deepMinutes'] as int?,
  remMinutes: value['remMinutes'] as int?,
  unknownMinutes: value['unknownMinutes'] as int?,
  inBedMinutes: value['inBedMinutes'] as int?,
  efficiencyPercent: (value['efficiencyPercent'] as num?)?.toDouble(),
  latencyMinutes: value['latencyMinutes'] as int?,
  wasoMinutes: value['wasoMinutes'] as int?,
  awakeningCount: value['awakeningCount'] as int?,
  midpoint: value['midpoint'] == null
      ? null
      : DateTime.parse(value['midpoint']! as String).toLocal(),
  isNap: value['isNap']! as bool,
  recordingMethod: value['recordingMethod'] as String?,
  deviceModel: value['deviceModel'] as String?,
  stages: [
    for (final stage in (value['stages'] as List<Object?>? ?? const []))
      SleepStage(
        stage: (stage! as Map<String, Object?>)['stage']! as String,
        start: DateTime.parse(
          (stage as Map<String, Object?>)['start']! as String,
        ).toLocal(),
        end: DateTime.parse(stage['end']! as String).toLocal(),
      ),
  ],
);
