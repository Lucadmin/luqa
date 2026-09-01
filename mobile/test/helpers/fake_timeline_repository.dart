import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

/// Deterministic stand-in for the network, seeded around a fixed day so
/// widget tests and goldens see the same timeline every run.
class FakeTimelineRepository implements TodayRepository {
  FakeTimelineRepository({required this.today, int historyDays = 0}) {
    if (historyDays > 0) _seedHistory(historyDays);
  }

  final DateTime today;

  int nextId = 100;

  final List<Category> categories = [
    const Category(id: 'food', name: 'Food', colorValue: 0xFFB45309),
    const Category(
      id: 'master-thesis',
      name: 'Master thesis',
      colorValue: 0xFF6543E8,
    ),
    const Category(id: 'training', name: 'Training', colorValue: 0xFFC2410C),
    const Category(id: 'personal', name: 'Personal', colorValue: 0xFF0F766E),
  ];

  late final List<TimeEntry> entries = [
    TimeEntry(
      id: 'breakfast',
      description: 'Breakfast',
      categoryId: 'food',
      start: _at(8, 10),
      end: _at(8, 40),
    ),
    TimeEntry(
      id: 'thesis',
      description: 'Writing thesis',
      categoryId: 'master-thesis',
      start: _at(9, 0),
      end: _at(11, 45),
    ),
    TimeEntry(
      id: 'gym',
      description: 'Gym',
      categoryId: 'training',
      start: _at(12, 30),
      end: _at(13, 45),
    ),
  ];

  late final DateTime _sleepStart = _at(
    0,
    12,
  ).subtract(const Duration(hours: 1));

  late final List<SleepEntry> sleep = [
    SleepEntry(
      id: 'sleep-1',
      source: 'HEALTH_CONNECT',
      sourceApp: 'Pixel Watch',
      title: null,
      start: _sleepStart,
      end: _at(7, 29),
      sleepMinutes: 437,
      awakeMinutes: 22,
      awakeInBedMinutes: 9,
      outOfBedMinutes: 0,
      lightMinutes: 240,
      deepMinutes: 95,
      remMinutes: 102,
      unknownMinutes: null,
      inBedMinutes: 497,
      efficiencyPercent: 87.9,
      latencyMinutes: 11,
      wasoMinutes: 22,
      awakeningCount: 3,
      midpoint: _at(3, 50),
      isNap: false,
      recordingMethod: 'AUTOMATICALLY_RECORDED',
      deviceModel: 'Pixel Watch 3',
      stages: _stages,
    ),
  ];

  /// A plausible night: four cycles, deep front-loaded, REM lengthening
  /// towards morning, with a couple of brief wakings.
  late final List<SleepStage> _stages = () {
    const script = <(String, int)>[
      ('AWAKE', 11),
      ('LIGHT', 42),
      ('DEEP', 38),
      ('LIGHT', 24),
      ('REM', 14),
      ('LIGHT', 31),
      ('DEEP', 33),
      ('AWAKE', 6),
      ('LIGHT', 36),
      ('REM', 26),
      ('LIGHT', 29),
      ('DEEP', 24),
      ('LIGHT', 33),
      ('REM', 31),
      ('AWAKE', 5),
      ('LIGHT', 45),
      ('REM', 31),
      ('LIGHT', 28),
    ];
    var cursor = _sleepStart;
    return [
      for (final (stage, minutes) in script)
        () {
          final start = cursor;
          cursor = cursor.add(Duration(minutes: minutes));
          return SleepStage(stage: stage, start: start, end: cursor);
        }(),
    ];
  }();

  DateTime _at(int hour, int minute) =>
      DateTime(today.year, today.month, today.day, hour, minute);

  /// A plausible few weeks behind today, for the screens that read history
  /// rather than a day.
  ///
  /// Shaped rather than random: weekdays have a working middle, the gym lands
  /// on the same three evenings, and the nights run later after a Friday. A
  /// uniform scatter would make every pattern-finding screen look correct
  /// while proving nothing about whether it can find a pattern.
  void _seedHistory(int days) {
    var seed = 20260827;
    int jitter(int span) {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      return seed % span;
    }

    for (var back = days; back >= 1; back--) {
      final day = DateTime(today.year, today.month, today.day - back);
      final weekend =
          day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
      DateTime at(int hour, int minute) =>
          DateTime(day.year, day.month, day.day, hour, minute);

      void log(
        String description,
        String categoryId,
        DateTime start,
        int minutes, {
        List<String> personIds = const [],
      }) {
        entries.add(
          TimeEntry(
            id: 'seed-${entries.length}',
            description: description,
            categoryId: categoryId,
            start: start,
            end: start.add(Duration(minutes: minutes)),
            personIds: personIds,
          ),
        );
      }

      log(
        'Breakfast',
        'food',
        at(weekend ? 9 : 8, 5 + jitter(25)),
        25 + jitter(20),
      );

      if (weekend) {
        log('Errands', 'personal', at(11, jitter(45)), 80 + jitter(50));
        log(
          'Lunch',
          'food',
          at(13, jitter(30)),
          45 + jitter(25),
          personIds: const ['mara'],
        );
        log('Reading', 'personal', at(15, 30 + jitter(40)), 90 + jitter(60));
      } else {
        log(
          'Writing thesis',
          'master-thesis',
          at(9, jitter(35)),
          150 + jitter(70),
        );
        log('Lunch', 'food', at(12, 30 + jitter(25)), 35 + jitter(20));
        log(
          'Writing thesis',
          'master-thesis',
          at(14, jitter(30)),
          160 + jitter(80),
        );
      }

      if (day.weekday == DateTime.tuesday ||
          day.weekday == DateTime.thursday ||
          day.weekday == DateTime.saturday) {
        log('Gym', 'training', at(18, jitter(40)), 70 + jitter(25));
      }

      log(
        weekend ? 'Dinner out' : 'Dinner',
        'food',
        at(20, jitter(35)),
        45 + jitter(35),
        personIds: weekend ? const ['mara', 'jonas'] : const [],
      );
      log('Evening', 'personal', at(21, 30 + jitter(30)), 60 + jitter(70));

      // The night that begins on this day. Later after a Friday or Saturday,
      // which is the drift the Insights readings are there to notice.
      final lateNight =
          day.weekday == DateTime.friday || day.weekday == DateTime.saturday;
      final bed = at(23, jitter(40)).add(Duration(minutes: lateNight ? 75 : 0));
      final wake = DateTime(
        day.year,
        day.month,
        day.day + 1,
        7,
        jitter(35),
      ).add(Duration(minutes: lateNight ? 55 : 0));
      final awake = 14 + jitter(20);
      sleep.add(
        SleepEntry(
          id: 'seed-sleep-$back',
          source: 'HEALTH_CONNECT',
          sourceApp: 'Pixel Watch',
          title: null,
          start: bed,
          end: wake,
          sleepMinutes: wake.difference(bed).inMinutes - awake,
          awakeMinutes: awake,
          lightMinutes: null,
          deepMinutes: null,
          remMinutes: null,
          isNap: false,
          midpoint: bed.add(wake.difference(bed) ~/ 2),
        ),
      );
    }
  }

  @override
  Future<List<Category>?> loadCachedCategories() async => null;

  @override
  Future<TimelineWindow?> loadCachedWindow(DateTime from, DateTime to) async =>
      null;

  @override
  Future<List<Category>> loadCategories() async =>
      List.unmodifiable(categories);

  @override
  Future<TimelineWindow> loadWindow(DateTime from, DateTime to) async =>
      TimelineWindow(
        from: from,
        to: to,
        entries: entries
            .where(
              (entry) =>
                  entry.start.isBefore(to) && entry.endOrNow().isAfter(from),
            )
            .toList(growable: false),
        sleep: sleep
            .where((entry) => entry.end.isAfter(from) && entry.end.isBefore(to))
            .toList(growable: false),
      );

  @override
  Future<TimeEntry> addEntry(NewTimeEntry draft) async {
    final entry = TimeEntry(
      id: 'entry-${nextId++}',
      description: draft.description,
      categoryId: draft.categoryId,
      start: draft.start,
      end: draft.end,
      personIds: draft.personIds,
    );
    entries.add(entry);
    return entry;
  }

  @override
  Future<TimeEntry> updateEntry(TimeEntry entry, EntryPatch patch) async {
    final id = entry.id;
    final index = entries.indexWhere((existing) => existing.id == id);
    if (index == -1) throw StateError('No entry $id');
    final updated = entries[index].copyWith(
      description: patch.description,
      categoryId: patch.categoryId,
      clearCategory: patch.clearCategory,
      start: patch.start,
      end: patch.end,
      personIds: patch.personIds,
    );
    entries[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteEntry(String id) async {
    entries.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<Category> addCategory(String name) async {
    final category = Category(
      id: 'category-${nextId++}',
      name: name.trim(),
      colorValue: 0xFF6543E8,
    );
    categories.add(category);
    return category;
  }
}
