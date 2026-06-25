import 'package:flutter_test/flutter_test.dart';
import 'package:volley_score/models/match_model.dart';

void main() {
  group('VolleyballMatch Scoring Logic Tests', () {
    late List<Player> testPlayers;

    setUp(() {
      testPlayers = [
        Player(id: 'p1', name: 'Lucas', number: 4),
        Player(id: 'p2', name: 'Thomas', number: 7),
      ];
    });

    test('Initial match state is correct', () {
      final match = VolleyballMatch(
        id: 'test_match_1',
        name: 'Test Match',
        players: testPlayers,
        winningSetsNeeded: 3,
      );

      expect(match.isFinished, isFalse);
      expect(match.sets.length, equals(1));
      expect(match.sets.first.scoreUs, equals(0));
      expect(match.sets.first.scoreThem, equals(0));
      expect(match.setsWonUs, equals(0));
      expect(match.setsWonThem, equals(0));
    });

    test('Standard set win requires 25 points and 2 points lead', () {
      final match = VolleyballMatch(
        id: 'test_match_2',
        name: 'Test Match',
        players: testPlayers,
        winningSetsNeeded: 3,
      );

      // Play to 24-24
      for (int i = 0; i < 24; i++) {
        match.addPoint('us', PointAction.attaque, 'p1');
        match.addPoint('them', PointAction.pointAdversaire, null);
      }

      expect(match.currentSet.scoreUs, equals(24));
      expect(match.currentSet.scoreThem, equals(24));
      expect(match.currentSet.isFinished, isFalse);

      // Score 25-24, shouldn't finish the set (needs 2 lead)
      match.addPoint('us', PointAction.ace, 'p1');
      expect(match.currentSet.scoreUs, equals(25));
      expect(match.currentSet.isFinished, isFalse);

      // Score 25-25
      match.addPoint('them', PointAction.pointAdversaire, null);
      expect(match.currentSet.scoreThem, equals(25));
      expect(match.currentSet.isFinished, isFalse);

      // Score 27-25 (Us wins the set)
      match.addPoint('us', PointAction.attaque, 'p1');
      match.addPoint('us', PointAction.attaque, 'p2');

      // The previous set should be finished and marked won
      expect(match.sets.first.isFinished, isTrue);
      expect(match.sets.first.scoreUs, equals(27));
      expect(match.sets.first.scoreThem, equals(25));
      expect(match.setsWonUs, equals(1));

      // A new set (Set 2) should be initialized
      expect(match.sets.length, equals(2));
      expect(match.currentSet.setNumber, equals(2));
      expect(match.currentSet.scoreUs, equals(0));
    });

    test('Deciding set (tie-break) requires 15 points and 2 points lead', () {
      final match = VolleyballMatch(
        id: 'test_match_3',
        name: 'Test Match',
        players: testPlayers,
        winningSetsNeeded: 2, // Best of 3 sets, so set 3 is deciding
      );

      // Us wins set 1 (25-0)
      for (int i = 0; i < 25; i++) {
        match.addPoint('us', PointAction.attaque, 'p1');
      }
      expect(match.setsWonUs, equals(1));

      // Them wins set 2 (0-25)
      for (int i = 0; i < 25; i++) {
        match.addPoint('them', PointAction.pointAdversaire, null);
      }
      expect(match.setsWonThem, equals(1));

      // Now we should be in the deciding Set 3
      expect(match.sets.length, equals(3));
      expect(match.isDecidingSet(3), isTrue);

      // Play up to 14-14
      for (int i = 0; i < 14; i++) {
        match.addPoint('us', PointAction.attaque, 'p1');
        match.addPoint('them', PointAction.pointAdversaire, null);
      }

      expect(match.currentSet.scoreUs, equals(14));
      expect(match.currentSet.scoreThem, equals(14));
      expect(match.currentSet.isFinished, isFalse);

      // Play to 16-14 (Us wins set 3 and the match)
      match.addPoint('us', PointAction.attaque, 'p1');
      match.addPoint('us', PointAction.contre, 'p2');

      expect(match.sets[2].isFinished, isTrue);
      expect(match.sets[2].scoreUs, equals(16));
      expect(match.sets[2].scoreThem, equals(14));
      
      expect(match.setsWonUs, equals(2));
      expect(match.isFinished, isTrue);
    });

    test('Undo reverts score and backtracks sets correctly', () {
      final match = VolleyballMatch(
        id: 'test_match_4',
        name: 'Test Match',
        players: testPlayers,
        winningSetsNeeded: 2,
      );

      // Us scores 1 point
      match.addPoint('us', PointAction.ace, 'p1');
      expect(match.currentSet.scoreUs, equals(1));

      // Undo last point
      match.undoLastPoint();
      expect(match.currentSet.scoreUs, equals(0));
      expect(match.currentSet.events.isEmpty, isTrue);

      // Play to win Set 1 (25 points)
      for (int i = 0; i < 25; i++) {
        match.addPoint('us', PointAction.attaque, 'p1');
      }
      expect(match.setsWonUs, equals(1));
      expect(match.sets.length, equals(2)); // Set 2 opened

      // Undo last point from the new set should backtrack into Set 1
      match.undoLastPoint();
      expect(match.sets.length, equals(1)); // Set 2 removed
      expect(match.sets.first.isFinished, isFalse); // Set 1 reopened
      expect(match.sets.first.scoreUs, equals(24)); // Set 1 score back to 24
      expect(match.setsWonUs, equals(0));
    });

    test('Statistics aggregation is calculated correctly', () {
      final match = VolleyballMatch(
        id: 'test_match_5',
        name: 'Test Match',
        players: testPlayers,
        winningSetsNeeded: 2,
      );

      // Lucas (p1) scores 2 aces, 1 attack error, 1 service error
      match.addPoint('us', PointAction.ace, 'p1');
      match.addPoint('us', PointAction.ace, 'p1');
      match.addPoint('them', PointAction.fauteAttaque, 'p1');
      match.addPoint('them', PointAction.fauteService, 'p1');

      // Thomas (p2) scores 3 attacks, 1 block, 1 reception error
      match.addPoint('us', PointAction.attaque, 'p2');
      match.addPoint('us', PointAction.attaque, 'p2');
      match.addPoint('us', PointAction.attaque, 'p2');
      match.addPoint('us', PointAction.contre, 'p2');
      match.addPoint('them', PointAction.erreurReception, 'p2');

      // Helper function to sum stats for player 1
      int p1Aces = 0;
      int p1AttackErrors = 0;
      int p2Attacks = 0;
      int p2Blocks = 0;
      int p2RecepErrors = 0;

      for (var set in match.sets) {
        for (var e in set.events) {
          if (e.playerId == 'p1') {
            if (e.action == PointAction.ace) p1Aces++;
            if (e.action == PointAction.fauteAttaque) p1AttackErrors++;
          }
          if (e.playerId == 'p2') {
            if (e.action == PointAction.attaque) p2Attacks++;
            if (e.action == PointAction.contre) p2Blocks++;
            if (e.action == PointAction.erreurReception) p2RecepErrors++;
          }
        }
      }

      expect(p1Aces, equals(2));
      expect(p1AttackErrors, equals(1));
      expect(p2Attacks, equals(3));
      expect(p2Blocks, equals(1));
      expect(p2RecepErrors, equals(1));
    });
   group('VolleyballMatch Ignore Stats Mode', () {
      test('Ignore stats does not record action-player metadata', () {
        final match = VolleyballMatch(
          id: 'test_match_6',
          name: 'Test Match',
          players: testPlayers,
          winningSetsNeeded: 2,
          ignoreStats: true,
        );

        match.addPoint('us', PointAction.none, null);
        match.addPoint('them', PointAction.none, null);

        expect(match.currentSet.scoreUs, equals(1));
        expect(match.currentSet.scoreThem, equals(1));
        expect(match.currentSet.events[0].action, equals(PointAction.none));
        expect(match.currentSet.events[0].playerId, isNull);
      });
    });
  });
}
