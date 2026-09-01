import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa_api/api.dart' as api;

class RemoteTodayRepository implements TodayRepository {
  RemoteTodayRepository({required this.client});

  final LuqaApi client;

  // Nothing is kept here any more; the device owns its rows. Signed out,
  // there is nowhere local to read from and nothing to paint early.
  @override
  Future<List<Category>?> loadCachedCategories() async => null;

  @override
  Future<TimelineWindow?> loadCachedWindow(DateTime from, DateTime to) async =>
      null;

  @override
  Future<List<Category>> loadCategories() async {
    final categories = (await client.listCategories())
        .where((category) => !category.archived)
        .map(categoryFromApi)
        .toList(growable: false);
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
          )).map(entryFromApi).toList(growable: false)
          ..sort((left, right) => left.start.compareTo(right.start));

    // Sleep is context, not the point of the screen. A server that cannot
    // serve it — an older deployment, a transient error — must not take the
    // tracked day down with it.
    final sleep = <SleepEntry>[];
    try {
      // Sleep is attributed to the day it wakes up in, so a session that began
      // the evening before still belongs to this window.
      sleep.addAll(
        (await client.listSleepEntries(from, to)).map(sleepFromApi),
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
    return window;
  }

  @override
  Future<TimeEntry> addEntry(NewTimeEntry draft) async => entryFromApi(
    await client.createTimeEntry(
      id: draft.id,
      description: draft.description,
      categoryId: draft.categoryId,
      start: draft.start,
      end: draft.end,
      personIds: draft.personIds,
    ),
  );

  @override
  Future<TimeEntry> updateEntry(TimeEntry entry, EntryPatch patch) =>
      updateEntryById(entry.id, patch);

  /// The queue only carries the id of an edited row, not the row itself.
  Future<TimeEntry> updateEntryById(String id, EntryPatch patch) async {
    return entryFromApi(
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
          // Absent leaves the tags alone; an empty list clears them, so the
          // list itself has to travel whenever it was decided.
          personIds: patch.personIds == null
              ? const api.Optional.absent()
              : api.Optional.present(patch.personIds!),
        ),
      ),
    );
  }

  @override
  Future<void> deleteEntry(String id) => client.deleteTimeEntry(id);

  @override
  Future<Category> addCategory(String name) async =>
      categoryFromApi(await client.createCategory(name));

  /// Creates a category under an id this device already handed out. The server
  /// may answer with a different one when the name is already taken, so the
  /// returned category is the authority.
  Future<Category> addCategoryWithId(Category category) async =>
      categoryFromApi(
        await client.createCategory(category.name, id: category.id),
      );
}

Category categoryFromApi(api.Category value) => Category(
  id: value.id,
  name: value.name,
  colorValue: _colorValue(value.color),
);

TimeEntry entryFromApi(api.TimeEntry value) => TimeEntry(
  id: value.id,
  description: value.description,
  categoryId: value.categoryId,
  start: value.startTime.toLocal(),
  end: value.endTime?.toLocal(),
  personIds: value.personIds.toList(growable: false),
);

SleepEntry sleepFromApi(api.SleepEntry value) => SleepEntry(
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






Map<String, Object?> sleepToJson(SleepEntry value) => {
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

SleepEntry sleepFromJson(Map<String, Object?> value) => SleepEntry(
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
