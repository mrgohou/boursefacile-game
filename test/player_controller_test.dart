import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/data/player_controller.dart';
import 'package:paco_bourse/data/player_repository.dart';
import 'package:paco_bourse/domain/player_state.dart';

class MemoryRepository implements PlayerRepository {
  PlayerState state = PlayerState.initial();
  Completer<void>? pending;
  bool fail = false;
  Completer<PlayerState>? pendingLoad;
  int writes = 0;
  @override
  Future<PlayerState> load() async =>
      pendingLoad == null ? state : await pendingLoad!.future;
  @override
  Future<void> save(PlayerState s) async {
    writes++;
    if (fail) throw Exception('disk unavailable');
    if (pending != null) await pending!.future;
    state = s;
  }
}

void main() {
  testWidgets('stalled storage exits loading without overwriting the save', (
    tester,
  ) async {
    final repo = MemoryRepository()..pendingLoad = Completer<PlayerState>();
    final controller = PlayerController(repo);
    final loading = controller.load();
    expect(controller.loading, isTrue);
    await tester.pump(const Duration(seconds: 16));
    await loading;
    expect(controller.loading, isFalse);
    expect(controller.error, isNotNull);
    expect(repo.writes, 0);
    repo.pendingLoad!.complete(PlayerState.initial().completeLevel(0));
    await tester.pump();
    expect(controller.error, isNotNull);
    expect(controller.state.completed, isEmpty);
    repo.pendingLoad = null;
    await controller.load();
    expect(controller.error, isNull);
    controller.dispose();
  });

  test(
    'two simultaneous reward requests do not race local persistence',
    () async {
      final repo = MemoryRepository()..pending = Completer<void>();
      final c = PlayerController(repo);
      await c.load();
      final first = c.change((s) => s.completeLevel(0));
      expect(c.busy, isTrue);
      expect(c.state.cash, 10000);
      expect(await c.change((s) => s.completeLevel(0)), isFalse);
      expect(repo.writes, 1);
      repo.pending!.complete();
      expect(await first, isTrue);
      expect(c.state.cash, 11500);
      expect(c.busy, isFalse);
      c.dispose();
    },
  );
  test('failed persistence does not publish a phantom reward', () async {
    final repo = MemoryRepository();
    final c = PlayerController(repo);
    await c.load();
    repo.fail = true;
    await expectLater(c.change((s) => s.completeLevel(0)), throwsException);
    expect(c.state.cash, 10000);
    expect(c.state.completed, isEmpty);
    expect(c.busy, isFalse);
    repo.fail = false;
    await c.change((s) => s.completeLevel(0));
    expect(c.state.cash, 11500);
    c.dispose();
  });
}
