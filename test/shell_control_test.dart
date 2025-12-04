import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:view_shell/view_shell.dart';

import 'shell_control_test.mocks.dart';

@GenerateMocks([TestProp])
abstract class TestProp extends Mock implements PropBase {}

class TestControl extends ViewShellControl {
  final List<PropBase> _props;

  TestControl(
    this._props, {
    ViewShellState Function(List<PropBase> props)? customResolver,
  }) : super(statusResolver: customResolver);

  @override
  List<PropBase> get viewProps => _props;
}

void main() {
  group('ViewShellControl', () {
    late MockTestProp prop1;
    late MockTestProp prop2;

    setUp(() {
      prop1 = MockTestProp();
      prop2 = MockTestProp();
    });

    // Helper to set up mock prop states
    void setupProp(
      MockTestProp prop, {
      bool isValid = true,
      bool hasErr = false,
      dynamic val,
    }) {
      when(prop.valid).thenReturn(isValid);
      when(prop.hasError).thenReturn(hasErr);
      when(prop.value).thenReturn(val);
      when(prop.error).thenReturn(hasErr ? 'Error' : null);
      when(prop.stackTrace).thenReturn(null);
    }

    // Track registered listeners manually
    final Map<MockTestProp, VoidCallback> _listeners = {};

    void registerListener(TestControl control, MockTestProp prop) {
      void listener() {
        control.reevaluateProps();
      }

      prop.addListener(listener);
      _listeners[prop] = listener;
    }

    test('initial state is ValidView when all props are valid', () {
      setupProp(prop1, isValid: true);
      setupProp(prop2, isValid: true);
      final control = TestControl([prop1, prop2]);
      expect(control.state, isA<ValidView>());
    });

    test('initial state is PendingView if any prop is not valid', () {
      setupProp(prop1, isValid: true);
      setupProp(prop2, isValid: false);
      final control = TestControl([prop1, prop2]);
      expect(control.state, isA<PendingView>());
    });

    test('initial state is ErrorView if any prop has an error', () {
      setupProp(prop1, isValid: true);
      setupProp(prop2, isValid: false, hasErr: true);
      final control = TestControl([prop1, prop2]);
      expect(control.state, isA<ErrorView>());
    });

    test('ErrorView has priority over PendingView', () {
      setupProp(prop1, isValid: false, hasErr: true); // Both error and invalid
      setupProp(prop2, isValid: false);
      final control = TestControl([prop1, prop2]);
      expect(control.state, isA<ErrorView>());
    });

    test('listens to prop changes and updates state', () {
      setupProp(prop1, isValid: true);
      setupProp(prop2, isValid: true);

      final control = TestControl([prop1, prop2]);

      // Register listeners
      registerListener(control, prop1);
      registerListener(control, prop2);

      var listenerCallCount = 0;
      void listener() => listenerCallCount++;
      control.addListener(listener);

      // Simulate a prop becoming invalid
      setupProp(prop1, isValid: false);
      _listeners[prop1]!(); // trigger manually

      expect(control.state, isA<PendingView>());
      expect(listenerCallCount, 1);

      // Simulate a prop getting an error
      setupProp(prop2, hasErr: true);
      _listeners[prop2]!(); // trigger manually

      expect(control.state, isA<ErrorView>());
      expect(listenerCallCount, 2);

      // Simulate all props becoming valid again
      setupProp(prop1, isValid: true);
      setupProp(prop2, isValid: true, hasErr: false);
      _listeners[prop1]!(); // trigger manually

      expect(control.state, isA<ValidView>());
      expect(listenerCallCount, 3);
    });

    test('uses custom statusResolver when provided', () {
      // A resolver that returns PendingView if prop1 has a value of "wait"
      ViewShellState customResolver(List<PropBase> props) {
        if (props.first.value == 'wait') {
          return const PendingView();
        }
        return const ValidView();
      }

      setupProp(prop1, isValid: true, val: 'wait');
      final control = TestControl([prop1], customResolver: customResolver);

      expect(control.state, isA<PendingView>());
    });

    test('does not notify if state type does not change', () {
      // Prop 1 is invalid -> PendingView
      setupProp(prop1, isValid: false);
      setupProp(prop2, isValid: true);
      final control = TestControl([prop1, prop2]);
      registerListener(control, prop1);
      registerListener(control, prop2);

      var listenerCallCount = 0;
      control.addListener(() => listenerCallCount++);

      expect(control.state, isA<PendingView>());

      // Now prop 2 becomes invalid. State is still PendingView.

      setupProp(prop2, isValid: false);
      _listeners[prop2]!();

      expect(control.state, isA<PendingView>());
      expect(listenerCallCount, 0); // No notification should have been sent
    });

    test('dispose removes listeners from all props', () {
      setupProp(prop1, isValid: false);
      setupProp(prop2, isValid: true);

      final control = TestControl([prop1, prop2]);
      control.dispose();
      verify(prop1.dispose()).called(1);
      verify(prop2.dispose()).called(1);
    });
  });
}
