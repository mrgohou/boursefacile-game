import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/domain/player_state.dart';
import 'package:paco_bourse/ui/city_map.dart';

void main() {
  Widget scene(
    PlayerState state,
    ValueChanged<String> tap, {
    bool reducedMotion = true,
    VoidCallback? guichet,
  }) => MaterialApp(
    home: Scaffold(
      body: CityMap(
        state: state,
        onBuildingTap: tap,
        onGuichetTap: guichet,
        reducedMotion: reducedMotion,
      ),
    ),
  );

  testWidgets(
    'empty plots open company guichet and ownership updates immediately',
    (tester) async {
      String? selected;
      var state = PlayerState.initial();
      await tester.pumpWidget(scene(state, (id) => selected = id));
      await tester.pumpAndSettle();
      expect(find.text('＋ Agroalimentaire'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('city-building-cacao')));
      expect(selected, 'cacao');
      state = state
          .completeLevel(0)
          .answerLesson(0)
          .completeLevel(1)
          .answerLesson(1)
          .buy('cacao');
      await tester.pumpWidget(scene(state, (id) => selected = id));
      await tester.pumpAndSettle();
      expect(find.text('Agroalimentaire · 1 part'), findsOneWidget);
      expect(find.text('＋ Agroalimentaire'), findsNothing);
      expect(
        find.byWidgetPredicate((w) {
          if (w is! Image) return false;
          final provider = w.image is ResizeImage
              ? (w.image as ResizeImage).imageProvider
              : w.image;
          return provider is AssetImage &&
              provider.assetName == 'assets/buildings/agro-1.webp';
        }),
        findsOneWidget,
      );
      selected = null;
      await tester.tap(find.byKey(const ValueKey('city-building-cacao')));
      expect(selected, 'cacao');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('drag pinch zoom and recenter preserve a navigable map', (
    tester,
  ) async {
    await tester.pumpWidget(scene(PlayerState.initial(), (_) {}));
    await tester.pumpAndSettle();
    InteractiveViewer viewer() => tester.widget<InteractiveViewer>(
      find.byKey(const ValueKey('city-interactive')),
    );
    final initial = viewer().transformationController!.value.clone();
    await tester.drag(
      find.byKey(const ValueKey('city-interactive')),
      const Offset(-60, 35),
    );
    await tester.pumpAndSettle();
    expect(viewer().transformationController!.value, isNot(equals(initial)));
    await tester.tap(find.byKey(const ValueKey('city-recenter')));
    await tester.pump();
    expect(viewer().transformationController!.value, equals(initial));
    final scale = viewer().transformationController!.value.getMaxScaleOnAxis();
    final middle = tester.getCenter(
      find.byKey(const ValueKey('city-interactive')),
    );
    final left = await tester.startGesture(
      middle - const Offset(50, 0),
      pointer: 1,
    );
    final right = await tester.startGesture(
      middle + const Offset(50, 0),
      pointer: 2,
    );
    await tester.pump();
    await left.moveTo(middle - const Offset(90, 0));
    await right.moveTo(middle + const Offset(90, 0));
    await tester.pump();
    await left.up();
    await right.up();
    await tester.pumpAndSettle();
    expect(
      viewer().transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(scale),
    );
    await tester.tap(find.byKey(const ValueKey('city-recenter')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('city-zoom-in')));
    await tester.pump();
    expect(
      viewer().transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(scale),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion stops ticker and guichet remains actionable', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      scene(PlayerState.initial(), (_) {}, guichet: () => opened = true),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.tap(find.byKey(const ValueKey('city-guichet')));
    expect(opened, isTrue);
    expect(
      tester.getSize(find.byKey(const ValueKey('city-recenter'))).width,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });
}
