import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:view_shell/view_shell.dart';

Future<String?> testAction(BuildContext context) {
  throw UnimplementedError();
}

// A concrete implementation of Shell for testing purposes
class TestShell extends Shell {
  final Prop<int> successProp = Prop.withValue(1);
  final Prop<int> errorProp = Prop.empty()..runSync(() => throw 'error');
  final Prop<int> pendingProp = Prop.empty();

  final bool includeError;
  final bool includePending;

  TestShell({this.includeError = false, this.includePending = false});

  @override
  List<PropBase> get viewProps {
    final props = <PropBase>[successProp];
    if (includeError) props.add(errorProp);
    if (includePending) props.add(pendingProp);
    return props;
  }

  Future<String?> testShellFunction() async {
    return shellRun<String>(testAction);
  }
}

void main() {
  group('Shell Logic', () {
    test('state is ValidShell when all props are valid', () {
      final shell = TestShell();
      expect(shell.state, isA<ValidShell>());
    });

    test('state is ErrorShell if one prop has an error', () {
      final shell = TestShell(includeError: true);
      expect(shell.state, isA<ErrorShell>());
    });

    test('state is PendingShell if one prop is not valid', () {
      final shell = TestShell(includePending: true);
      expect(shell.state, isA<PendingShell>());
    });

    test('state reactively updates when a prop changes state', () {
      final shell = TestShell(includePending: true);
      expect(shell.state, isA<PendingShell>());

      bool notified = false;
      shell.addListener(() {
        notified = true;
      });

      shell.pendingProp.set(123);
      expect(shell.state, isA<ValidShell>());
      expect(notified, isTrue);
    });

    group('shellRun testing mechanism', () {
      test('fakeShell enables testing of shellRun actions', () async {
        final shell = TestShell();
        shell.fakeShell(); // Enable testing mode

        // Call the method that uses shellRun
        final futureResult = shell.testShellFunction();

        // Verify that the action is pending
        expect(shell.shellIsActionPending(testAction), isTrue);

        // Complete the pending action
        shell.shellReturnForAction(testAction, 'Fake Dialog Result');

        // Verify the future completes with the faked value
        await expectLater(
          futureResult,
          completion(equals('Fake Dialog Result')),
        );
        expect(shell.shellIsActionPending(testAction), isFalse);
      });

      test(
        'shellRun returns null and asserts if not mounted and not faked',
        () {
          final shell = TestShell();
          // Do NOT call fakeShell() and do not mount in a widget
          expect(
            () => shell.testShellFunction(),
            throwsA(isA<AssertionError>()),
          );
        },
      );
    });
  });
}
