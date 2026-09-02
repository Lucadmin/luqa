import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/gym/presentation/widgets/exercise_progress_chart.dart';

import '../../helpers/fake_gym_repository.dart';
import '../../helpers/pump_luqa.dart';

void main() {
  testWidgets('plots every gym at once and lets one be switched off', (
    tester,
  ) async {
    await pumpLuqa(
      tester,
      gymRepository: FakeGymRepository.sample(),
      initialLocation: '/gym/exercises/lat-pulldown/history',
    );

    // Arriving without a gym opens on all of them: a line each, so the two
    // can be read against one another.
    expect(_seriesLabels(tester), ['Luqa Gym', 'McFit Mitte']);
    expect(find.text('96.67 kg'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('Luqa Gym'));
    await tester.pumpAndSettle();

    // The numbers follow the chart. Reading a best the reader has just
    // switched off would contradict the line above it.
    expect(_seriesLabels(tester), ['McFit Mitte']);
    expect(find.text('96.67 kg'), findsNothing);
    expect(find.text('91 kg'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('reads the picked gyms as one line on request', (tester) async {
    await pumpLuqa(
      tester,
      gymRepository: FakeGymRepository.sample(),
      initialLocation: '/gym/exercises/lat-pulldown/history',
    );

    await tester.tap(find.text('Across gyms'));
    await tester.pumpAndSettle();

    final series = _series(tester);
    expect(series.length, 1);
    expect(series.single.points.length, 2);
    // Each workout keeps its gym's dot even on the combined line.
    expect(series.single.dotColors!.toSet().length, 2);
  });

  testWidgets('opens on the gym the workout was logged at', (tester) async {
    await pumpLuqa(
      tester,
      gymRepository: FakeGymRepository.sample(),
      initialLocation: '/gym/exercises/lat-pulldown/history?locationId=mcfit',
    );

    expect(_seriesLabels(tester), ['McFit Mitte']);

    await tester.tap(find.text('Luqa Gym'));
    await tester.pumpAndSettle();

    expect(_seriesLabels(tester), ['Luqa Gym', 'McFit Mitte']);
  });
}

List<ExerciseProgressSeries> _series(WidgetTester tester) => tester
    .widget<ExerciseProgressChart>(find.byType(ExerciseProgressChart))
    .series;

List<String> _seriesLabels(WidgetTester tester) => [
  for (final series in _series(tester)) series.label,
];
