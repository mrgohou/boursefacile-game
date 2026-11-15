import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/domain/learning_director.dart';
import 'package:paco_bourse/data/learning_repository.dart';

void main() {
  test('mastery is bounded and declines after two difficult rounds', () {
    var p = LearningProfile();
    for (var i = 0; i < 12; i++) {
      p = p.recordRound(
        level: i,
        won: true,
        elapsedSeconds: 20,
        remainingMoves: 20,
      );
    }
    expect(p.mastery, 3);
    expect(p.nextPracticeLevel, 42);
    p = p
        .recordRound(
          level: 12,
          won: false,
          elapsedSeconds: 180,
          remainingMoves: 0,
        )
        .recordRound(
          level: 12,
          won: false,
          elapsedSeconds: 180,
          remainingMoves: 0,
        );
    expect(p.mastery, 0);
  });
  test(
    'weak quiz topics outrank concentration reminders without personal advice',
    () {
      var p = LearningProfile();
      for (var i = 0; i < 3; i++) {
        p = p.recordTrade(companyId: 'SNTS', family: 'telecom', buy: true);
      }
      expect(p.recommendedTopic, 'Diversification');
      p = p.recordQuiz(topic: 'Liquidité', correct: false);
      expect(p.recommendedTopic, 'Liquidité');
      expect(LearningProfile.fromJson(p.toJson()).toJson(), p.toJson());
    },
  );
  test('updates immutable and reject invalid telemetry', () {
    final p = LearningProfile();
    final next = p.recordQuiz(topic: 'Frais', correct: false);
    expect(p.quizWrong, isEmpty);
    expect(() => next.quizWrong['Frais'] = 9, throwsUnsupportedError);
    expect(
      () => p.recordRound(
        level: -1,
        won: true,
        elapsedSeconds: 0,
        remainingMoves: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => LearningProfile.fromJson({...p.toJson(), 'wins': 1}),
      throwsFormatException,
    );
  });
  test('optional persistence survives plugin and storage failures', () async {
    String? stored;
    final repo = LearningRepository(
      read: (_) async => stored,
      write: (_, v) async {
        stored = v;
      },
    );
    final p = LearningProfile().recordQuiz(topic: 'Budget', correct: true);
    expect(await repo.save(p), true);
    expect((await repo.load()).toJson(), p.toJson());
    stored = 'invalid';
    expect((await repo.load()).rounds, 0);
    expect(repo.lastError, isNotNull);
    final failed = LearningRepository(
      write: (_, _) async => throw StateError('disk'),
    );
    expect(await failed.save(p), false);
    expect(failed.lastError, isNotNull);
    expect(jsonDecode(jsonEncode(p.toJson()))['version'], 1);
  });
}
