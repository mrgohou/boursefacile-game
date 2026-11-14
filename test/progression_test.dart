import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/domain/stage_catalog.dart';
import 'package:paco_bourse/domain/lessons.dart';
import 'package:paco_bourse/domain/player_state.dart';
import 'package:paco_bourse/domain/puzzle_clock.dart';
import 'package:paco_bourse/game/match_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'all 30 stages match the shared catalogue and have valid learning tasks',
    () async {
      final raw = jsonDecode(
        await rootBundle.loadString('assets/progression/stages.json'),
      ) as Map;
      final list = raw['stages'] as List;
      expect(stageCount, 30);
      expect(lessons.length, stageCount);
      expect(list.length, stageCount);
      expect(stageSpecs.map((s) => s.id).toSet().length, stageCount);
      for (var i = 0; i < stageCount; i++) {
        final spec = stageSpecs[i];
        final engine = MatchEngine(i);
        expect(engine.target, list[i]['target']);
        expect(engine.moves, list[i]['moves']);
        expect(puzzleSeconds(i), list[i]['seconds']);
        expect(spec.target, lessThanOrEqualTo(spec.moves * 90));
        expect(spec.moves, inInclusiveRange(19, 24));
        expect(spec.seconds, inInclusiveRange(60, 90));
        expect(MatchEngine.findMatches(engine.board), isEmpty);
        expect(engine.hint(), isNotNull);
        expect(lessons[i].question, isNotEmpty);
        expect(
          lessons[i].answer,
          inInclusiveRange(0, lessons[i].options.length - 1),
        );
      }
    },
  );
  test(
    'every stage is solvable using legal matches within its move budget',
    () {
      for (var i = 0; i < stageCount; i++) {
        final engine = MatchEngine(i);
        final budget = engine.moves;
        for (var turn = 0; turn < budget && !engine.won; turn++) {
          final pair = engine.hint()!;
          expect(engine.swap(pair[0], pair[1]), isTrue);
        }
        expect(
          engine.won,
          isTrue,
          reason: 'Stage ${i + 1} must have a reachable target',
        );
      }
    },
  );
  test(
    'legacy six-stage progress unlocks stage seven without another reward',
    () {
      var old = PlayerState.initial();
      for (var i = 0; i < 6; i++) {
        old = old.completeLevel(i).answerLesson(i);
      }
      final legacy = {...old.toJson(), 'version': 3};
      final restored = PlayerState.fromJson(legacy);
      expect(restored.unlockedLevel, 6);
      expect(restored.cash, 19000);
      expect(identical(restored.completeLevel(5), restored), isTrue);
      final next = restored.completeLevel(6).answerLesson(6);
      expect(next.cash, 20500);
      expect(next.unlockedLevel, 7);
      expect(next.toJson()['version'], 4);
      expect(PlayerState.fromJson(next.toJson()).toJson(), next.toJson());
      expect(
        () => PlayerState.fromJson({...next.toJson(), 'version': 3}),
        throwsFormatException,
      );
    },
  );
  test('all 30 stages persist sequentially with unique rewards and reject stage 31', () {
    var state = PlayerState.initial();
    for (var i = 0; i < stageCount; i++) {
      state = state.completeLevel(i).answerLesson(i);
      state = PlayerState.fromJson(state.toJson());
      expect(identical(state.completeLevel(i), state), isTrue);
    }
    expect(state.unlockedLevel, 30);
    expect(state.completed.length, 30);
    expect(state.cash, 55000);
    expect(() => state.completeLevel(30), throwsArgumentError);
    expect(() => PlayerState.initial().completeLevel(20), throwsStateError);
  });
}
