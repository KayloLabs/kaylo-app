import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/core/widgets/liquid_tab_bar.dart';

const _labels = ['Home', 'Bookings', 'Care', 'Messages', 'Profile'];

Widget _harness({
  required int index,
  required ValueChanged<int> onSelected,
  TextDirection direction = TextDirection.ltr,
  bool accessible = false,
  double width = 360,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: accessible,
      highContrast: accessible,
      textScaler: TextScaler.linear(accessible ? 2.4 : 1),
    ),
    child: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: LiquidTabBar(
              index: index,
              labels: _labels,
              onSelected: onSelected,
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('drag previews each destination and commits only on release', (
    tester,
  ) async {
    final selections = <int>[];
    await tester.pumpWidget(_harness(index: 0, onSelected: selections.add));
    final home = tester.getCenter(find.byIcon(Icons.home_rounded));
    final care = tester.getCenter(find.byIcon(Icons.favorite_outline));
    final profile = tester.getCenter(find.byIcon(Icons.person_outline));

    final gesture = await tester.startGesture(home);
    await gesture.moveTo(care);
    await tester.pump();
    expect(selections, isEmpty);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    await gesture.moveTo(profile);
    await tester.pump();
    expect(selections, isEmpty);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, [4]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled drag returns to the selected tab without navigating', (
    tester,
  ) async {
    final selections = <int>[];
    await tester.pumpWidget(_harness(index: 1, onSelected: selections.add));
    final bookings = tester.getCenter(
      find.byIcon(Icons.calendar_today_rounded),
    );
    final profile = tester.getCenter(find.byIcon(Icons.person_outline));
    final gesture = await tester.startGesture(bookings);
    await gesture.moveTo(profile);
    await tester.pump();
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);

    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
    expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('holding then sliding selects the destination on release', (
    tester,
  ) async {
    final selections = <int>[];
    await tester.pumpWidget(_harness(index: 0, onSelected: selections.add));
    final home = tester.getCenter(find.byIcon(Icons.home_rounded));
    final messages = tester.getCenter(find.byIcon(Icons.chat_bubble_outline));
    final gesture = await tester.startGesture(home);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
    await gesture.moveTo(messages);
    await tester.pump();

    expect(selections, isEmpty);
    expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, [3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL sliding follows the visible tab positions', (tester) async {
    final selections = <int>[];
    await tester.pumpWidget(
      _harness(
        index: 0,
        onSelected: selections.add,
        direction: TextDirection.rtl,
      ),
    );
    final home = tester.getCenter(find.byIcon(Icons.home_rounded));
    final messages = tester.getCenter(find.byIcon(Icons.chat_bubble_outline));
    expect(messages.dx, lessThan(home.dx));
    final gesture = await tester.startGesture(home);
    await gesture.moveTo(messages);
    await tester.pump();
    expect(selections, isEmpty);
    expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, [3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'external navigation updates the selected tab without callbacks',
    (tester) async {
      final selections = <int>[];
      var index = 0;
      late StateSetter update;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return _harness(index: index, onSelected: selections.add);
          },
        ),
      );
      update(() => index = 3);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(selections, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancel restores the latest external destination during a drag', (
    tester,
  ) async {
    final selections = <int>[];
    var index = 0;
    late StateSetter update;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return _harness(index: index, onSelected: selections.add);
        },
      ),
    );
    final home = tester.getCenter(find.byIcon(Icons.home_rounded));
    final profile = tester.getCenter(find.byIcon(Icons.person_outline));
    final gesture = await tester.startGesture(home);
    await gesture.moveTo(profile);
    await tester.pump();
    update(() => index = 2);
    await tester.pump();

    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(selections, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all tabs remain usable at a compact accessible width', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final selections = <int>[];
    var index = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, update) => _harness(
          index: index,
          accessible: true,
          width: 240,
          onSelected: (value) {
            selections.add(value);
            update(() => index = value);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < _labels.length; i++) {
      final tab = find.bySemanticsLabel(_labels[i]);
      expect(tab, findsOneWidget);
      final barBounds = tester.getRect(find.byType(LiquidTabBar));
      expect(barBounds.contains(tester.getCenter(tab)), isTrue);
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(index, i);
      expect(tester.takeException(), isNull);
    }
    // Tapping the already selected Home tab may be a no-op; every other
    // destination must still have been reachable in order.
    expect(selections.where((value) => value != 0), [1, 2, 3, 4]);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    semantics.dispose();
  });
}
