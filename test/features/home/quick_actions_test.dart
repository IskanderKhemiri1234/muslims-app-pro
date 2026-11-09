import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muslims_app/features/home/presentation/widgets/quick_actions.dart';

void main() {
  testWidgets(
    'every quick action accepts a tap with natural finger drift',
    (tester) async {
      final receivedActions = <String>[];
      const actionIds = <String>[
        'qibla',
        'quran',
        'mosques',
        'adhan',
        'adhkar',
        'tasbih',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: QuickActions(
                onAction: receivedActions.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));

      for (final actionId in actionIds) {
        final tile = find.byKey(ValueKey<String>(actionId));
        expect(tile, findsOneWidget, reason: 'Missing action: $actionId');
        final hitTarget = find.descendant(
          of: tile,
          matching: find.byType(InkWell),
        );
        expect(hitTarget, findsOneWidget);

        final gesture = await tester.startGesture(
          tester.getCenter(hitTarget),
        );
        await gesture.moveBy(const Offset(4, 2));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 40));
      }

      expect(receivedActions, actionIds);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('shortcut artwork has transparent edges and no rotating frame', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickActions(onAction: (_) {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ClipOval), findsNothing);
    expect(find.byType(Image), findsNWidgets(5));

    // Check the artwork tile itself. Flutter's Scrollbar has its own internal
    // RotationTransition for thumb animation, unrelated to shortcut artwork.
    for (final actionId in <String>[
      'qibla',
      'quran',
      'mosques',
      'adhkar',
      'tasbih',
    ]) {
      final tile = find.byKey(ValueKey<String>(actionId));
      expect(
        find.descendant(
          of: tile,
          matching: find.byType(RotationTransition),
        ),
        findsNothing,
        reason: '$actionId artwork must remain static.',
      );
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
