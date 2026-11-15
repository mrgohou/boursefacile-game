import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/domain/player_state.dart';
import 'package:paco_bourse/domain/city_growth.dart';
import 'package:paco_bourse/domain/companion_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('starter cash cannot bypass gains or neighbourhood order', () {
    final initial = PlayerState.initial();
    expect(() => initial.buyLand('rive'), throwsStateError);
    final rewarded = initial.completeLevel(0);
    expect(() => rewarded.buyLand('verger'), throwsStateError);
    final land = rewarded.buyLand('rive');
    expect(land.cash, 10500);
    expect(land.ownedPlots, {'rive'});
    expect(() => land.buyLand('rive'), throwsStateError);
    expect(() => initial.buyLand('unknown'), throwsArgumentError);
  });
  test('construction is a one-time expense on an acquired empty plot', () {
    final reward = PlayerState.initial().completeLevel(0);
    expect(() => reward.construct('rive', 'ferme'), throwsStateError);
    final built = reward.buyLand('rive').construct('rive', 'ferme');
    expect(built.cash, 10000);
    expect(built.townBuildings, {'rive': 'ferme'});
    expect(() => built.construct('rive', 'boutique'), throwsStateError);
    expect(PlayerState.fromJson(built.toJson()).toJson(), built.toJson());
    expect(() => built.ownedPlots.add('verger'), throwsUnsupportedError);
  });
  test('journey rewards are unique and sequential and help unlock land', () {
    var s = PlayerState.initial();
    expect(() => s.answerJourney(1, 0), throwsStateError);
    for (var q = 0; q < 3; q++) {
      s = s.answerJourney(0, q);
    }
    final once = s;
    s = s.answerJourney(0, 0);
    expect(identical(s, once), isTrue);
    expect(s.cash, 10900);
    s = s.answerJourney(1, 0).answerJourney(1, 1);
    expect(s.earnedRewards, 1500);
    expect(s.buyLand('rive').cash, 10500);
    expect(() => s.answerJourney(15, 0), throwsArgumentError);
    expect(() => s.answerJourney(0, -1), throwsArgumentError);
  });
  test('v2 saves preserve portfolio and receive empty expansion progress', () {
    final before = PlayerState.initial().completeLevel(0).toJson();
    final raw = legacySave(before, 2)
      ..remove('ownedPlots')
      ..remove('townBuildings')
      ..remove('journeyAnswers');
    final migrated = PlayerState.fromJson(raw);
    expect(migrated.cash, 11500);
    expect(migrated.completed, {0});
    expect(migrated.ownedPlots, isEmpty);
    expect(migrated.journeyAnswers, isEmpty);
    expect(migrated.toJson()['version'], 6);
  });
  test('invalid expansion data and insufficient budget are rejected', () {
    final s = PlayerState.initial().completeLevel(0);
    final raw = s.toJson();
    for (final bad in [
      {
        ...raw,
        'ownedPlots': ['rive', 'rive'],
      },
      {
        ...raw,
        'townBuildings': {'rive': 'ferme'},
      },
      {
        ...raw,
        'ownedPlots': ['verger'],
      },
      {
        ...raw,
        'journeyAnswers': [3],
      },
      {
        ...raw,
        'journeyAnswers': [0, 0],
      },
      {
        ...raw,
        'ownedPlots': ['rive'],
        'townBuildings': {'rive': 'unknown'},
      },
    ]) {
      expect(() => PlayerState.fromJson(bad), throwsFormatException);
    }
    final poor = PlayerState.fromJson({...raw, 'cash': 999});
    expect(() => poor.buyLand('rive'), throwsStateError);
    final plot = s.buyLand('rive');
    final poorBuilder = PlayerState.fromJson({...plot.toJson(), 'cash': 499});
    expect(() => poorBuilder.construct('rive', 'ferme'), throwsStateError);
  });
  test('all six expansions are affordable through finite earned rewards', () {
    var s = PlayerState.initial();
    for (var i = 0; i < 6; i++) {
      s = s.completeLevel(i).answerLesson(i);
    }
    for (var city = 0; city < 15; city++) {
      for (var q = 0; q < 3; q++) {
        s = s.answerJourney(city, q);
      }
    }
    for (final l in lands) {
      s = s.buyLand(l.id).construct(l.id, 'services');
    }
    expect(s.ownedPlots.length, 6);
    expect(s.townBuildings.length, 6);
    expect(s.cash, greaterThanOrEqualTo(0));
  });
  test('APK catalogue provides 15 destinations, 45 quizzes, 45 level definitions and 45 archived companies', () async {
    final catalog = await CompanionCatalog.load();
    expect(catalog.cities.length, 15);
    expect(catalog.levels.length, 45);
    expect(
      catalog.quiz.values.fold<int>(0, (n, v) => n + (v as List).length),
      45,
    );
    expect((catalog.market['companies'] as List).length, 45);
    expect(catalog.market['sessionDate'], '2026-11-13');
  });
}

Map<String, dynamic> legacySave(Map<String, dynamic> raw, int version) => {
  ...raw,
  'version': version,
  'holdings': {
    for (final id in ['cacao', 'telecom', 'banque'])
      id: (raw['holdings'] as Map)[id],
  },
  'prices': {
    for (final id in ['cacao', 'telecom', 'banque'])
      id: (raw['prices'] as Map)[id],
  },
};
