import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/domain/challenge_catalog.dart';

void main() {
  test('campaign contains standalone and combined meaningful challenges', () {
    final campaign = List.generate(30, challengeFor);
    expect(campaign.any((s) => s.locks == 4), isTrue);
    expect(campaign.any((s) => s.locks == 6), isTrue);
    expect(campaign.any((s) => s.perfectMoves == 7), isTrue);
    expect(campaign.any((s) => s.collectCount == 30), isTrue);
    expect(campaign.any((s) => s.specialUses >= 2), isTrue);
    expect(campaign.any((s) => s.score == 0), isTrue);
    expect(campaign.any((s) => s.score > 0 && s.locks > 0), isTrue);
    expect(campaign.map((s) => s.themeIndex).toSet().length, 30);
    expect(campaign.last.score, greaterThan(campaign.first.score));
  });

  test('continued levels and all mastery tiers retain bounded valid goals', () {
    for (var i = 0; i < 300; i++) {
      for (var mastery = 0; mastery <= 5; mastery++) {
        final s = challengeFor(i, mastery: mastery);
        expect(s.objectives, isNotEmpty);
        expect(s.moves, inInclusiveRange(24, 40));
        expect(s.seconds, inInclusiveRange(90, 180));
        expect(s.score, greaterThanOrEqualTo(0));
        expect(s.collectType, s.collectCount > 0 ? inInclusiveRange(0, 5) : -1);
        expect(s.locks, anyOf(0, 4, 6));
        if (s.perfectMoves > 0) {
          expect(s.moves, greaterThanOrEqualTo(s.perfectMoves * 4));
          expect(s.seconds, greaterThanOrEqualTo(150));
        }
      }
    }
  });

  test(
    'round settings are repeatable and adaptation never changes identity',
    () {
      final normal = challengeFor(29);
      final practiced = challengeFor(29, mastery: 3);
      expect(challengeFor(29).instruction, normal.instruction);
      expect(practiced.themeIndex, normal.themeIndex);
      expect(practiced.score, greaterThanOrEqualTo(normal.score));
      expect(practiced.moves, lessThanOrEqualTo(normal.moves));
      expect(challengeFor(29, mastery: 999).instruction, practiced.instruction);
      expect(challengeFor(29, mastery: -5).instruction, normal.instruction);
      expect(() => challengeFor(-1), throwsArgumentError);
    },
  );
}
