import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/gym/data/gym_json.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

/// The writes the gym log can make while offline.
///
/// Sessions are saved wholesale rather than by field, which makes this queue
/// much simpler than the timeline's: the newest save of a workout supersedes
/// every earlier one, so a set of thirty reps entered one keystroke at a time
/// still leaves exactly one request to send.
sealed class GymMutation implements PendingMutation {
  const GymMutation({required this.queuedAt});

  @override
  final DateTime queuedAt;

  /// Named the way the user would name it, because this is only ever read
  /// when they are being told the change did not survive.
  @override
  String describe() => switch (this) {
    CreateSession(:final session) => "${session.dateKey}'s workout",
    SaveSession(:final write) => write.exercises.isEmpty
        ? "your ${write.dateKey} workout"
        : 'your ${write.dateKey} workout '
              '(${write.exercises.length} exercises)',
    CreateLocation(:final location) => 'the gym ${location.name}',
    UpdateLocation(:final name) => 'your edit to ${name ?? 'a gym'}',
  };

  static GymMutation? fromJson(Map<String, Object?> json) {
    final queuedAt = DateTime.tryParse(json['queuedAt'] as String? ?? '');
    if (queuedAt == null) return null;
    return switch (json['op']) {
      'createSession' => CreateSession(
        session: gymSessionFromJson(json['session']! as Map<String, Object?>),
        queuedAt: queuedAt,
      ),
      'saveSession' => SaveSession(
        sessionId: json['sessionId']! as String,
        write: gymWriteFromJson(json['write']! as Map<String, Object?>),
        queuedAt: queuedAt,
      ),
      'createLocation' => CreateLocation(
        location: gymLocationFromJson(
          json['location']! as Map<String, Object?>,
        ),
        queuedAt: queuedAt,
      ),
      'updateLocation' => UpdateLocation(
        locationId: json['locationId']! as String,
        name: json['name'] as String?,
        code: json['code'] as String?,
        colorValue: json['colorValue'] as int?,
        archived: json['archived'] as bool?,
        queuedAt: queuedAt,
      ),
      // An op written by a newer build is not something this one can replay.
      _ => null,
    };
  }
}

final class CreateSession extends GymMutation {
  const CreateSession({required this.session, required super.queuedAt});

  final GymSession session;

  @override
  String get subjectId => session.id;

  @override
  Map<String, Object?> toJson() => {
    'op': 'createSession',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'session': gymSessionToJson(session),
  };
}

final class SaveSession extends GymMutation {
  const SaveSession({
    required this.sessionId,
    required this.write,
    required super.queuedAt,
  });

  final String sessionId;
  final GymSessionWrite write;

  @override
  String get subjectId => sessionId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'saveSession',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'sessionId': sessionId,
    'write': gymWriteToJson(write),
  };
}

final class CreateLocation extends GymMutation {
  const CreateLocation({required this.location, required super.queuedAt});

  final GymLocation location;

  @override
  String get subjectId => location.id;

  @override
  Map<String, Object?> toJson() => {
    'op': 'createLocation',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'location': gymLocationToJson(location),
  };
}

final class UpdateLocation extends GymMutation {
  const UpdateLocation({
    required this.locationId,
    required this.name,
    required this.code,
    required this.colorValue,
    required this.archived,
    required super.queuedAt,
  });

  final String locationId;
  final String? name;
  final String? code;
  final int? colorValue;
  final bool? archived;

  @override
  String get subjectId => locationId;

  UpdateLocation mergedOver(UpdateLocation earlier) => UpdateLocation(
    locationId: locationId,
    name: name ?? earlier.name,
    code: code ?? earlier.code,
    colorValue: colorValue ?? earlier.colorValue,
    archived: archived ?? earlier.archived,
    queuedAt: earlier.queuedAt,
  );

  GymLocation applyTo(GymLocation location) => GymLocation(
    id: location.id,
    code: code ?? location.code,
    name: name ?? location.name,
    colorValue: colorValue ?? location.colorValue,
    order: location.order,
    archived: archived ?? location.archived,
  );

  @override
  Map<String, Object?> toJson() => {
    'op': 'updateLocation',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'locationId': locationId,
    'name': name,
    'code': code,
    'colorValue': colorValue,
    'archived': archived,
  };
}

/// Appends [next], folding it into what is already queued for the same row.
List<GymMutation> foldGym(List<GymMutation> queue, GymMutation next) {
  switch (next) {
    case SaveSession(:final sessionId, :final write):
      // Deliberately not folded into a pending create: a create only carries
      // the workout's date and gym, so absorbing a save into it would throw
      // away every set that had been entered. A workout logged offline
      // therefore leaves exactly two requests — make it, then fill it in.
      final folded = <GymMutation>[];
      var absorbed = false;
      for (final pending in queue) {
        // Saves replace the whole workout, so only the newest one matters.
        // This is what keeps a set entered one keystroke at a time from
        // becoming a queue of thirty requests.
        if (pending is SaveSession && pending.sessionId == sessionId) {
          folded.add(
            SaveSession(
              sessionId: sessionId,
              write: write,
              queuedAt: pending.queuedAt,
            ),
          );
          absorbed = true;
        } else {
          folded.add(pending);
        }
      }
      return absorbed ? folded : [...folded, next];

    case UpdateLocation(:final locationId):
      final folded = <GymMutation>[];
      var absorbed = false;
      for (final pending in queue) {
        switch (pending) {
          case CreateLocation(:final location) when location.id == locationId:
            folded.add(
              CreateLocation(
                location: next.applyTo(location),
                queuedAt: pending.queuedAt,
              ),
            );
            absorbed = true;
          case UpdateLocation(locationId: final id) when id == locationId:
            folded.add(next.mergedOver(pending));
            absorbed = true;
          case _:
            folded.add(pending);
        }
      }
      return absorbed ? folded : [...folded, next];

    case CreateSession() || CreateLocation():
      return [...queue, next];
  }
}

/// The session as it would look once [write] has been applied — which is what
/// the user is already looking at.
///
/// Exercise ids are the interesting part: an exercise typed by name has none
/// until the server resolves it, so the local copy keeps a placeholder id and
/// adopts the real one after the save lands.
GymSession applyWrite(GymSession session, GymSessionWrite write) => GymSession(
  id: session.id,
  dateKey: write.dateKey,
  locationId: write.locationId,
  notes: write.notes,
  createdAt: session.createdAt,
  exercises: [
    for (final (index, exercise) in write.exercises.indexed)
      GymSessionExercise(
        id: '${session.id}#$index',
        exerciseId: exercise.exerciseId ?? '',
        name: exercise.name,
        order: index,
        raw: [
          for (final set in exercise.sets) formatGymSet(_toSet(set)),
        ].join(', '),
        notes: exercise.notes,
        sets: [for (final set in exercise.sets) _toSet(set)],
      ),
  ],
);

GymSet _toSet(GymSetWrite write) =>
    GymSet(weight: write.weight, reps: write.reps, note: write.note);

/// Lays the queue over a server snapshot, so what the user sees is what they
/// did, whether or not it has been sent yet.

List<GymMutation> remapLocationId(
  List<GymMutation> queue,
  String from,
  String to,
) {
  if (from == to) return queue;
  return [
    for (final pending in queue)
      switch (pending) {
        CreateSession(:final session) when session.locationId == from =>
          CreateSession(
            session: GymSession(
              id: session.id,
              dateKey: session.dateKey,
              locationId: to,
              notes: session.notes,
              exercises: session.exercises,
              createdAt: session.createdAt,
            ),
            queuedAt: pending.queuedAt,
          ),
        SaveSession(:final sessionId, :final write)
            when write.locationId == from =>
          SaveSession(
            sessionId: sessionId,
            write: GymSessionWrite(
              dateKey: write.dateKey,
              locationId: to,
              notes: write.notes,
              exercises: write.exercises,
            ),
            queuedAt: pending.queuedAt,
          ),
        UpdateLocation(:final locationId) when locationId == from =>
          UpdateLocation(
            locationId: to,
            name: pending.name,
            code: pending.code,
            colorValue: pending.colorValue,
            archived: pending.archived,
            queuedAt: pending.queuedAt,
          ),
        _ => pending,
      },
  ];
}

/// The gym log's durable queue.
class SqliteGymOutbox extends SqliteOutbox<GymMutation> {
  SqliteGymOutbox({required super.namespace, super.store})
    : super(key: 'gym', decode: GymMutation.fromJson);
}
