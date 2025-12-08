import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:view_shell/view_shell.dart';

// Test Shell implementation
class CounterShell extends Shell {
  final counter = SyncProp(0);
  final otherCounter = SyncProp(100);

  @override
  List<PropBase> get viewProps => [counter, otherCounter];

  void increment() => counter.transform((val) => val + 1);
}

void main() {
  group('Shell Widget Tests', () {
    testWidgets('ShellWidget provides shell to descendants', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShellWidget<CounterShell>(
            create: (_) => CounterShell(),
            child: Builder(
              builder: (context) {
                // Access the shell
                final shell = context.shell<CounterShell>();
                // Call a method on it
                shell.increment();
                return Text('Value: ${shell.counter.value}');
              },
            ),
          ),
        ),
      );

      // The builder should have run and updated the counter
      expect(find.text('Value: 1'), findsOneWidget);
    });

    testWidgets(
      'PropValueBuilder rebuilds only when its selected prop changes',
      (WidgetTester tester) async {
        int mainBuilds = 0;
        int otherBuilds = 0;

        final shell = CounterShell();

        await tester.pumpWidget(
          MaterialApp(
            home: ShellWidget<CounterShell>(
              create: (_) => shell,
              child: Column(
                children: [
                  PropValueBuilder<CounterShell, int>(
                    selector: (s) => s.counter,
                    builder: (context, value) {
                      mainBuilds++;
                      return Text('Main: $value');
                    },
                  ),
                  PropValueBuilder<CounterShell, int>(
                    selector: (s) => s.otherCounter,
                    builder: (context, value) {
                      otherBuilds++;
                      return Text('Other: $value');
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        // Initial build
        expect(mainBuilds, 1);
        expect(otherBuilds, 1);
        expect(find.text('Main: 0'), findsOneWidget);

        // Update the main counter
        shell.increment();
        await tester.pump();

        // Only the main builder should have been rebuilt
        expect(mainBuilds, 2);
        expect(otherBuilds, 1);
        expect(find.text('Main: 1'), findsOneWidget);
      },
    );

    testWidgets('PropValueBuilder builds loading and error states', (
      tester,
    ) async {
      final prop = Prop<int>.empty();
      final shell = CounterShell(); // Not used, just to satisfy the generic

      await tester.pumpWidget(
        MaterialApp(
          home: ShellWidget<CounterShell>(
            create: (_) => shell,
            child: PropValueBuilder<CounterShell, int>(
              selector: (_) => prop,
              builder: (_, val) => Text('Success: $val'),
              loadingBuilder: (_) => const Text('Loading...'),
              errorBuilder: (_, err, __) => Text('Error: $err'),
            ),
          ),
        ),
      );

      // Prop is "initial", which should show loading
      expect(find.text('Loading...'), findsOneWidget);

      // Set to loading
      prop.run(() async => 0);

      // Complete the future
      await tester.pumpAndSettle();
      expect(find.text('Success: 0'), findsOneWidget);

      // Set to error
      prop.runSync(() => throw 'Failure');
      await tester.pump();
      expect(find.text('Error: Failure'), findsOneWidget);
    });
  });
}
