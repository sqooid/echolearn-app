import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lang_app/models/filter_state.dart';
import 'package:lang_app/utils/theme.dart';
import 'package:lang_app/widgets/filter_bar.dart';
import 'package:lang_app/widgets/play_fab.dart';

const _screenHeight = 560.0;

void _setShortScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, _screenHeight);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

class _Harness extends StatefulWidget {
  const _Harness({required this.onBehindTap});

  final VoidCallback onBehindTap;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    return LingoTheme(
      colors: lightColors,
      accent: const Color(0xFF3B82F6),
      onAccent: Colors.white,
      density: 1,
      gap: 12,
      child: Scaffold(
        body: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onBehindTap,
              child: const SizedBox.expand(),
            ),
            FilterBar(
              state: const FilterState(),
              onChange: (_) {},
              count: 5,
              open: _open,
              setOpen: (v) => setState(() => _open = v),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('open filter panel stays clear of the PlayFAB and scrolls', (tester) async {
    _setShortScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: _Harness(onBehindTap: _noop)));
    await tester.pumpAndSettle();

    final scrollView = find.byType(SingleChildScrollView);
    expect(scrollView, findsOneWidget);

    final fabTop = _screenHeight - kPlayFabBottom - kPlayFabDiameter;
    expect(
      tester.getBottomLeft(scrollView).dy,
      lessThanOrEqualTo(fabTop),
      reason: 'panel must not overlap the PlayFAB',
    );

    expect(_position(tester).maxScrollExtent, greaterThan(0), reason: 'body must be scrollable when constrained');
  });

  testWidgets('scroll offset survives collapse/expand; backdrop does not block when collapsed', (tester) async {
    _setShortScreen(tester);
    var behindTaps = 0;
    await tester.pumpWidget(MaterialApp(home: _Harness(onBehindTap: () => behindTaps++)));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    final saved = _position(tester).pixels;
    expect(saved, greaterThan(0));

    await tester.tap(find.text('5 cards'));
    await tester.pumpAndSettle();
    expect(_position(tester).pixels, saved, reason: 'collapsing must not reset the scroll position');

    await tester.tapAt(const Offset(200, 500));
    await tester.pumpAndSettle();
    expect(behindTaps, 1, reason: 'collapsed panel must not swallow taps');

    await tester.tap(find.text('5 cards'));
    await tester.pumpAndSettle();
    expect(_position(tester).pixels, saved, reason: 'scroll position must survive minimise/expand');

    await tester.tapAt(const Offset(200, 500));
    await tester.pumpAndSettle();
    expect(behindTaps, 1, reason: 'open panel backdrop must catch outside taps');
  });

  testWidgets('whole toggle row activates its switch exactly once', (tester) async {
    _setShortScreen(tester);
    var state = const FilterState();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: LingoTheme(
        colors: lightColors,
        accent: const Color(0xFF3B82F6),
        onAccent: Colors.white,
        density: 1,
        gap: 12,
        child: Scaffold(
          body: Stack(children: [
            StatefulBuilder(
              builder: (context, setState) => FilterBar(
                state: state,
                onChange: (s) {
                  calls++;
                  setState(() => state = s);
                },
                count: 5,
                open: true,
                setOpen: (_) {},
              ),
            ),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Reshuffle at end'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reshuffle at end'));
    await tester.pump();
    expect(state.reshuffle, isTrue);
    expect(calls, 1, reason: 'label tap must toggle exactly once');

    await tester.ensureVisible(find.text('Show untranslated'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show untranslated'));
    await tester.pump();
    expect(state.showUntranslated, isTrue);
    expect(calls, 2, reason: 'label tap must toggle exactly once');

    final switches = find.byType(Toggle);
    expect(switches, findsNWidgets(2));
    await tester.ensureVisible(switches.first);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(switches.first));
    await tester.pump();
    expect(state.reshuffle, isFalse);
    expect(calls, 3, reason: 'tapping the switch itself must toggle exactly once');
  });
}

void _noop() {}
