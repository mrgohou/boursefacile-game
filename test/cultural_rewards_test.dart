import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/domain/player_state.dart';
import 'package:paco_bourse/domain/cultural_rewards.dart';
import 'package:paco_bourse/domain/city_growth.dart';
import 'package:paco_bourse/domain/cultural_catalog.dart';

PlayerState cleanLevel(PlayerState s, int n) =>
    s.startPuzzle(n).completeLevel(n, flawless: true).answerLesson(n);
void main() {
  test('32 villes et huit pays, IDs des anciennes sauvegardes conservés', () {
    expect(lands.length, 31);
    expect(cityName('centre'), 'Abidjan');
    expect(lands.take(6).map((l) => l.id), [
      'rive',
      'verger',
      'marche',
      'atelier',
      'lumiere',
      'jardin',
    ]);
    expect({0, ...lands.map((l) => cityCountryIndex(l.id))}.length, 8);
    expect(culturalTokens.length, 20);
    for (final l in lands) {
      for (var t = 0; t < 3; t++) {
        expect(cityBuildingFrame(l.id, t), inInclusiveRange(0, 23));
      }
    }
  });
  test(
    '5 et 10 quiz : cadeaux distincts et versement uniquement à COLLECTER',
    () {
      var s = PlayerState.initial();
      for (var n = 0; n < 10; n++) {
        s = cleanLevel(s, n);
      }
      expect(s.rewards.pending.map((r) => r.kind), [
        'quiz5',
        'level5',
        'quiz10',
        'level10',
      ]);
      expect(s.cash, 25000);
      expect(s.rewards.quizStreak, 10);
      expect(s.rewards.levelStreak, 10);
      for (final r in [...s.rewards.pending]) {
        s = s.collectReward(r.id);
      }
      expect(s.cash, 56500);
      expect(s.rewards.colas, 5);
      expect(s.rewards.cauris, 9);
      expect(s.rewards.gold, 10);
      expect(s.rewards.crosses, 1);
      expect(() => s.collectReward(1), throwsStateError);
      expect(PlayerState.fromJson(s.toJson()).cash, s.cash);
    },
  );
  test('une mauvaise réponse survit au rechargement et rompt les séries', () {
    var s = PlayerState.initial();
    for (var n = 0; n < 4; n++) {
      s = cleanLevel(s, n);
    }
    s = s
        .startPuzzle(4)
        .completeLevel(4, flawless: true)
        .recordQuizAttempt('lesson:4', false);
    s = PlayerState.fromJson(s.toJson()).answerLesson(4);
    expect(s.rewards.quizStreak, 0);
    expect(s.rewards.levelStreak, 0);
    expect(s.rewards.pending, isEmpty);
  });
  test('nouvelle tentative ou échange refusé exclut le niveau sans faute', () {
    var s = PlayerState.initial().startPuzzle(0);
    s = PlayerState.fromJson(s.toJson())
        .startPuzzle(0)
        .completeLevel(0, flawless: true)
        .answerLesson(0);
    expect(s.rewards.levelStreak, 0);
    expect(s.rewards.quizStreak, 1);
    s = s.startPuzzle(1).completeLevel(1, flawless: false).answerLesson(1);
    expect(s.rewards.levelStreak, 0);
  });
  test('questions revues ne permettent pas de farmer et séries répétées ont des IDs uniques', () {
    var r = CulturalRewards();
    for (var i = 1; i <= 20; i++) {
      r = r.quiz('knowledge:practical-brvm-$i', true);
    }
    expect(r.pending.map((r) => r.kind), [
      'quiz5',
      'quiz10',
      'quiz5',
      'quiz10',
    ]);
    expect(r.pending.map((r) => r.id).toSet().length, 4);
    final before = r.toJson();
    r = r.quiz('knowledge:practical-brvm-1', true);
    expect(r.toJson(), before);
  });
  test(
    'migration v6 conserve les acquis sans inventer une série rétroactive',
    () {
      var s = cleanLevel(PlayerState.initial(), 0);
      final raw = s.toJson()
        ..['version'] = 6
        ..remove('culturalRewards')
        ..remove('cityStage');
      s = PlayerState.fromJson(raw);
      expect(s.cash, 11500);
      expect(s.rewards.pending, isEmpty);
      expect(s.rewards.quizStreak, 0);
      expect(s.rewards.seen, contains('lesson:0'));
    },
  );
  test(
    'modernisation ne régresse pas après vente et survit à la sauvegarde',
    () {
      var s = PlayerState.initial();
      for (var i = 0; i < 10; i++) {
        s = cleanLevel(s, i);
      }
      for (var i = 0; i < 6; i++) {
        s = s.buy('cacao');
      }
      expect(s.cityTier, 2);
      for (var i = 0; i < 6; i++) {
        s = s.sell('cacao');
      }
      expect(s.cityTier, 2);
      expect(PlayerState.fromJson(s.toJson()).cityTier, 2);
    },
  );
  test(
    'cadeau en attente conservé après échec de collecte et après relance',
    () {
      var s = PlayerState.initial();
      for (var i = 0; i < 5; i++) {
        s = cleanLevel(s, i);
      }
      final restored = PlayerState.fromJson(s.toJson());
      expect(restored.rewards.pending.length, 2);
      expect(restored.cash, s.cash);
    },
  );
  test('les 32 terrains restent accessibles avec des gains finis et des fermes rurales', () {
    var s = PlayerState.initial();
    for (var i = 0; i < 30; i++) {
      s = s.completeLevel(i).answerLesson(i);
    }
    for (var c = 0; c < 15; c++) {
      for (var q = 0; q < 3; q++) {
        s = s.answerJourney(c, q);
      }
    }
    for (final l in lands) {
      s = s.buyLand(l.id).construct(l.id, 'ferme');
    }
    expect(s.ownedPlots.length, 31);
    expect(s.townBuildings.length, 31);
    expect(s.cash, greaterThanOrEqualTo(0));
    expect(PlayerState.fromJson(s.toJson()).ownedPlots.length, 31);
  });
  test('sauvegarde avec cadeau dupliqué refusée', () {
    var s = PlayerState.initial();
    for (var i = 0; i < 5; i++) {
      s = cleanLevel(s, i);
    }
    final raw = s.toJson();
    final r = raw['culturalRewards'] as Map;
    final p = r['pending'] as List;
    p.add(p.first);
    expect(() => PlayerState.fromJson(raw), throwsFormatException);
  });
}
