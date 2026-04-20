import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/services/api_client.dart';
import 'package:hold_the_hooch/widgets/leaderboard_entry_row.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('LeaderboardEntryRow', () {
    testWidgets('shows rank, name and formatted score', (tester) async {
      await tester.pumpWidget(_wrap(LeaderboardEntryRow(
        rank: 1,
        entry: LeaderboardEntry(name: 'Gurgles', score: 12345),
        highlighted: false,
      )));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('Gurgles'), findsOneWidget);
      expect(find.text('12,345'), findsOneWidget);
    });

    testWidgets('highlighted rows have a non-null background decoration',
        (tester) async {
      await tester.pumpWidget(_wrap(LeaderboardEntryRow(
        rank: 3,
        entry: LeaderboardEntry(name: 'Me', score: 100),
        highlighted: true,
      )));

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('leaderboard-row-bg')),
      );
      expect(container.decoration, isNotNull);
    });

    testWidgets('non-highlighted rows have no background decoration',
        (tester) async {
      await tester.pumpWidget(_wrap(LeaderboardEntryRow(
        rank: 3,
        entry: LeaderboardEntry(name: 'Other', score: 100),
        highlighted: false,
      )));

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('leaderboard-row-bg')),
      );
      expect(container.decoration, isNull);
    });
  });
}
