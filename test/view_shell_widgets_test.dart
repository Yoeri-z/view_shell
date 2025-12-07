import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:view_shell/view_shell.dart';

// --- Test Setup ---

// A simple control for testing widget interactions
class WidgetTestControl extends ViewShellControl {
  final Prop<String> textProp = Prop.empty();

  @override
  List<PropBase> get viewProps => [textProp];
}

// Custom ShellBuilders for testing fallback logic
class ConfigShellBuilder extends ShellBuilder {
  const ConfigShellBuilder();
  @override
  Widget build(BuildContext context, ViewShellState state, builder) =>
      const Text('ConfigBuilder');
}

class LocalShellBuilder extends ShellBuilder {
  const LocalShellBuilder();
  @override
  Widget build(BuildContext context, ViewShellState state, builder) =>
      const Text('LocalBuilder');
}

void main() {
  group('ViewShell Widget Tests', () {
    late WidgetTestControl control;

    setUp(() {
      control = WidgetTestControl();
    });

    testWidgets('ViewShell shows DefaultShellBuilder pending UI', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ViewShell(
            create: (_) => control,
            builder: (_, __) => const Text('Valid'),
          ),
        ),
      );

      // Initially, the prop is empty (invalid), so state is PendingView.
      // DefaultShellBuilder shows a CircularProgressIndicator for PendingView.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Valid'), findsNothing);
    });

    testWidgets('ViewShell shows DefaultShellBuilder error UI', (tester) async {
      // Set an error state
      control.textProp.runSync(() => throw 'Error');

      await tester.pumpWidget(
        MaterialApp(
          home: ViewShell(
            create: (_) => control,
            builder: (_, __) => const Text('Valid'),
          ),
        ),
      );
      await tester.pump(); // Re-render after state change

      // DefaultShellBuilder shows a specific text for ErrorView
      expect(find.text('An unexpected error occurred'), findsOneWidget);
      expect(find.text('Valid'), findsNothing);
    });

    testWidgets('ViewShell shows valid builder UI when state is valid', (
      tester,
    ) async {
      // Set a valid state
      control.textProp.set('Success');

      await tester.pumpWidget(
        MaterialApp(
          home: ViewShell(
            create: (_) => control,
            builder: (_, __) => const Text('Valid'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Valid'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('ViewShell uses local shellBuilder over all others', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ViewShellConfig(
            shellBuilder: const ConfigShellBuilder(),
            child: ViewShell(
              create: (_) => control,
              shellBuilder: const LocalShellBuilder(), // Highest priority
              builder: (_, __) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(find.text('LocalBuilder'), findsOneWidget);
      expect(find.text('ConfigBuilder'), findsNothing);
    });

    testWidgets('ViewShell falls back to ViewShellConfig builder', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ViewShellConfig(
            shellBuilder: const ConfigShellBuilder(), // Should be used
            child: ViewShell(
              create: (_) => control,
              // No local builder provided
              builder: (_, __) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(find.text('ConfigBuilder'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('PropBuilder and PropValueBuilder', () {
    late WidgetTestControl control;

    setUp(() {
      control = WidgetTestControl();
    });

    Widget buildTestApp(Widget child) {
      return MaterialApp(
        home: ChangeNotifierProvider.value(
          value: control,
          child: Scaffold(body: child),
        ),
      );
    }

    testWidgets('PropValueBuilder builds with the unwrapped value', (
      tester,
    ) async {
      control.textProp.set('The-Value');

      await tester.pumpWidget(
        buildTestApp(
          PropValueBuilder<WidgetTestControl, String>(
            selector: (c) => c.textProp,
            builder: (context, value) {
              // `value` should be the string 'The-Value', not the Prop
              return Text(value);
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('The-Value'), findsOneWidget);
    });

    testWidgets('PropBuilder builds with the Prop object itself', (
      tester,
    ) async {
      final completer = Completer<String>();

      await tester.pumpWidget(
        buildTestApp(
          PropBuilder<WidgetTestControl, Prop<String>>(
            selector: (c) => c.textProp,
            builder: (context, prop) {
              if (prop.isLoading) return const Text('Loading...');
              if (prop.hasError) return Text('Error: ${prop.error}');
              if (prop.valid) return Text('Value: ${prop.value}');
              return const Text('Initial');
            },
          ),
        ),
      );

      // 1. Initial state
      expect(find.text('Initial'), findsOneWidget);

      // 2. Loading state
      control.textProp.run(() => completer.future); // Start the async operation
      await tester.pump(); // Render the loading state frame
      expect(find.text('Loading...'), findsOneWidget);

      // 3. Valid state
      completer.complete('Loaded'); // Complete the future
      await tester.pumpAndSettle(); // Wait for all frames to settle
      expect(find.text('Value: Loaded'), findsOneWidget);

      // 4. Error state
      control.textProp.runSync(() => throw 'Failure');
      await tester.pump();
      expect(find.text('Error: Failure'), findsOneWidget);
    });
  });
}
