import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/main.dart' as entrypoint;

void main() {
  testWidgets(
    'real entrypoint displays a recoverable error if native storage is unavailable',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      entrypoint.main();
      await tester.pumpAndSettle();
      expect(find.text('Réessayer'), findsOneWidget);
      expect(
        find.textContaining('Impossible de lire la sauvegarde'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
