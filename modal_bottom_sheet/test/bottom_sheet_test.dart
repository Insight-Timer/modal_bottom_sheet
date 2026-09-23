import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

void main() {
  group(
    'Route.mainState are well-controlled by `mainState`',
    () {
      Future<void> testInitStateAndDispose(
        WidgetTester tester,
        Future<void> Function(BuildContext context, WidgetBuilder builder)
            onPressed,
      ) async {
        int initState = 0, dispose = 0;
        await _pumpWidget(
          tester: tester,
          onPressed: (context) => onPressed(
            context,
            (_) => _TestWidget(
              onInitState: () => initState++,
              onDispose: () => dispose++,
            ),
          ),
        );
        expect(initState, 0);
        await tester.tap(_textButtonWithText('Press me'));
        await tester.pumpAndSettle();
        expect(initState, 1);
        expect(dispose, 0);
        await tester.tap(_textButtonWithText('TestWidget push'));
        await tester.pumpAndSettle();
        expect(initState, 1);
        expect(dispose, 0);
        await tester.tap(_textButtonWithText('TestWidget pushed pop'));
        await tester.pumpAndSettle();
        expect(initState, 1);
        expect(dispose, 0);
        await tester.tap(_textButtonWithText('TestWidget pop'));
        await tester.pumpAndSettle();
        expect(initState, 1);
        expect(dispose, 1);
      }

      testWidgets('with showCupertinoModalBottomSheet', (tester) {
        return testInitStateAndDispose(
          tester,
          (context, builder) => showCupertinoModalBottomSheet(
            context: context,
            builder: builder,
          ),
        );
      });
      testWidgets('with showMaterialModalBottomSheet', (tester) {
        return testInitStateAndDispose(
          tester,
          (context, builder) => showMaterialModalBottomSheet(
            context: context,
            builder: builder,
          ),
        );
      });
    },
  );

  group('releasing a drag', () {
    Future<void> openSheet(WidgetTester tester, WidgetBuilder builder) async {
      await _pumpWidget(
        tester: tester,
        onPressed: (context) =>
            showMaterialModalBottomSheet(context: context, builder: builder),
      );
      await tester.tap(_textButtonWithText('Press me'));
      await tester.pumpAndSettle();
    }

    Future<TestGesture> drag(
      WidgetTester tester, {
      required double down,
      double back = 0,
    }) async {
      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(find.text('Sheet')));
      int ms = 0;
      Future<void> move(double dy) async {
        await gesture.moveBy(Offset(0, dy / 10),
            timeStamp: Duration(milliseconds: ms += 16));
        await tester.pump(const Duration(milliseconds: 16));
      }

      for (int i = 0; i < 10; i++) {
        await move(down);
      }
      for (int i = 0; i < 10 && back > 0; i++) {
        await move(-back);
      }
      await gesture.up(timeStamp: Duration(milliseconds: ms += 16));
      await tester.pumpAndSettle();
      return gesture;
    }

    Widget fixedSheet(BuildContext context) =>
        const SizedBox(height: 400, child: Text('Sheet'));

    Widget scrollingSheet(BuildContext context) => SizedBox(
          height: 400,
          child: ListView(
            controller: ModalScrollController.of(context),
            children: [
              const SizedBox(height: 100, child: Text('Sheet')),
              for (int i = 0; i < 20; i++)
                SizedBox(height: 100, child: Text('Row $i')),
            ],
          ),
        );

    ScrollPosition listPosition(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable)).position;

    for (final (String name, WidgetBuilder builder) in [
      ('fixed content', fixedSheet),
      ('scrolling content', scrollingSheet),
    ]) {
      testWidgets('over $name past the threshold while moving down closes',
          (tester) async {
        await openSheet(tester, builder);
        await drag(tester, down: 300);
        expect(find.text('Sheet'), findsNothing);
      });

      testWidgets(
          'over $name past the threshold while moving back up stays open',
          (tester) async {
        await openSheet(tester, builder);
        await drag(tester, down: 300, back: 60);
        expect(find.text('Sheet'), findsOneWidget);
        expect(tester.getTopLeft(find.text('Sheet')).dy, 200);
      });
    }

    testWidgets('lifting a pulled-down sheet does not scroll its content',
        (tester) async {
      await openSheet(tester, scrollingSheet);
      await drag(tester, down: 200, back: 150);
      expect(tester.getTopLeft(find.text('Sheet')).dy, 200);
      expect(listPosition(tester).pixels, 0);
    });

    testWidgets('dragging down inside scrolled content scrolls back first',
        (tester) async {
      await openSheet(tester, scrollingSheet);
      listPosition(tester).jumpTo(300);
      await tester.pump();
      final TestGesture gesture =
          await tester.startGesture(const Offset(400, 400));
      for (int i = 1; i <= 10; i++) {
        await gesture.moveBy(const Offset(0, 10),
            timeStamp: Duration(milliseconds: 100 * i));
        await tester.pump();
      }
      await gesture.up(timeStamp: const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();
      expect(listPosition(tester).pixels, lessThan(300));
      expect(listPosition(tester).pixels, greaterThan(0));
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}

Future<void> _pumpWidget({
  required WidgetTester tester,
  required void Function(BuildContext context) onPressed,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => onPressed(context),
              child: Text('Press me'),
            ),
          ),
        ),
      ),
    ),
  );
}

Finder _textButtonWithText(String text) {
  return find.widgetWithText(TextButton, text);
}

class _TestWidget extends StatefulWidget {
  const _TestWidget({
    this.onInitState,
    this.onDispose,
  });

  final VoidCallback? onInitState;
  final VoidCallback? onDispose;

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget> {
  @override
  void initState() {
    super.initState();
    widget.onInitState?.call();
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              defaultPageRoute(
                targetPlatform: Theme.of(context).platform,
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('TestWidget pushed pop'),
                    ),
                  ),
                ),
              ),
            ),
            child: Text('TestWidget push'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('TestWidget pop'),
          ),
        ],
      ),
    );
  }
}

PageRoute<T> defaultPageRoute<T>({
  required TargetPlatform targetPlatform,
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool maintainState = true,
  bool fullscreenDialog = false,
}) {
  switch (targetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return CupertinoPageRoute<T>(
        builder: builder,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    default:
      return MaterialPageRoute<T>(
        builder: builder,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
  }
}
