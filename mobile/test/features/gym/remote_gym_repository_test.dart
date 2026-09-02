import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/gym/data/remote_gym_repository.dart';
import 'package:luqa_api/api.dart' as api;

void main() {
  test('finishing a workout does not replace its exercises', () async {
    final client = _RecordingApi();
    final stoppedAt = DateTime.parse('2026-09-02T13:45:00Z');

    await expectLater(
      RemoteGymRepository(client).endSession('session-1', stoppedAt),
      throwsA(isA<_RequestRecorded>()),
    );

    expect(client.request.toJson(), {
      'endedAt': stoppedAt.toUtc().toIso8601String(),
    });
  });
}

final class _RecordingApi implements LuqaApi {
  late api.UpdateGymSessionRequest request;

  @override
  Future<api.GymSession> updateGymSession(
    String id,
    api.UpdateGymSessionRequest request,
  ) async {
    this.request = request;
    throw const _RequestRecorded();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RequestRecorded implements Exception {
  const _RequestRecorded();
}
