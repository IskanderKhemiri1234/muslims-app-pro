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

        final gesture = await tester.startGesture(
          tester.getCenter(tile),
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
}
