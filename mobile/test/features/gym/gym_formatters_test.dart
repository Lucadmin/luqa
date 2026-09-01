import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/gym/presentation/gym_formatters.dart';

/// Runs [read] with a real [MaterialLocalizations] in scope, which is what
/// both formatters spell the month with.
Future<String> _label(
  WidgetTester tester,
  String Function(BuildContext context) read,
) async {
  late String result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          result = read(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}

void main() {
  final now = DateTime(2026, 8, 27);

  group('gymDayLabel', () {
    testWidgets('the last two days are named rather than dated', (
      tester,
    ) async {
      expect(
        await _label(tester, (c) => gymDayLabel(c, '2026-08-27', now)),
        'Today',
      );
      expect(
        await _label(tester, (c) => gymDayLabel(c, '2026-08-26', now)),
        'Yesterday',
      );
    });

    testWidgets('this year needs no year, an older one does', (tester) async {
      expect(
        await _label(tester, (c) => gymDayLabel(c, '2026-03-14', now)),
        'Sat, Mar 14',
      );
      // Years of logging is exactly the case the bare label cannot serve: it
      // would read as though this March, which is what makes an old workout
      // impossible to place.
      expect(
        await _label(tester, (c) => gymDayLabel(c, '2021-03-14', now)),
        'Sun, Mar 14, 2021',
      );
    });
  });

  group('gymDatedLabel', () {
    testWidgets('history rows always carry the year', (tester) async {
      expect(
        await _label(tester, (c) => gymDatedLabel(c, DateTime(2026, 8, 25))),
        'Tue, Aug 25, 2026',
      );
      expect(
        await _label(tester, (c) => gymDatedLabel(c, DateTime(2019, 11, 2))),
        'Sat, Nov 2, 2019',
      );
    });
  });
}
