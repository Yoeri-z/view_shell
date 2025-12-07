import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:view_shell/view_shell.dart';

import 'package:mockito/annotations.dart';
import 'prop_test.mocks.dart';

@GenerateMocks([Callbacks])
abstract class Callbacks {
  Future<String> futureSuccess();
  Future<String> futureFailure();
  String syncSuccess();
  String syncFailure();
  void onSucces(dynamic value);
  void onFailure(Object error, StackTrace st);
}

void main() {
  late MockCallbacks mockCallbacks;

  setUp(() {
    mockCallbacks = MockCallbacks();
    when(
      mockCallbacks.futureSuccess(),
    ).thenAnswer((_) => Future.value('Success'));
    when(
      mockCallbacks.futureFailure(),
    ).thenAnswer((_) => Future.error('Failure', StackTrace.empty));
    when(mockCallbacks.syncSuccess()).thenReturn('Success');
    when(mockCallbacks.syncFailure()).thenThrow('Failure');
  });

  group('Prop', () {
    test('Prop.empty initializes as invalid and not loading', () {
      final prop = Prop<String>.empty();
      expect(prop.valid, isFalse);
      expect(prop.isLoading, isFalse);
      expect(prop.hasError, isFalse);
      expect(prop.value, isNull);
    });

    test('Prop.withValue initializes as valid with a value', () {
      final prop = Prop.withValue('initial');
      expect(prop.valid, isTrue);
      expect(prop.value, 'initial');
    });

    test('set() updates value, marks as valid, and notifies listeners', () {
      final prop = Prop<String>.empty();
      var listenerCallCount = 0;
      prop.addListener(() => listenerCallCount++);

      prop.set('new value');

      expect(prop.value, 'new value');
      expect(prop.valid, isTrue);
      expect(prop.hasError, isFalse);
      expect(listenerCallCount, 1);
    });

    test('reset() clears all state and notifies listeners', () {
      final prop = Prop.withValue('initial');
      var listenerCallCount = 0;
      prop.addListener(() => listenerCallCount++);

      prop.reset();

      expect(prop.value, isNull);
      expect(prop.valid, isFalse);
      expect(prop.isLoading, isFalse);
      expect(prop.hasError, isFalse);
      expect(listenerCallCount, 1);
    });

    group('run()', () {
      test('handles success correctly', () async {
        final prop = Prop<String>.empty();
        var listenerCallCount = 0;
        prop.addListener(() => listenerCallCount++);

        final future = prop.run(
          mockCallbacks.futureSuccess,
          onSucces: mockCallbacks.onSucces,
        );

        // State during execution
        expect(prop.isLoading, isTrue);
        expect(prop.valid, isFalse);
        expect(listenerCallCount, 1); // For isLoading=true

        await future;

        // State after success
        expect(prop.isLoading, isFalse);
        expect(prop.valid, isTrue);
        expect(prop.value, 'Success');
        expect(prop.hasError, isFalse);
        expect(listenerCallCount, 2); // isLoading=true, final state (success)
        verify(mockCallbacks.onSucces('Success')).called(1);
      });

      test('handles failure correctly', () async {
        final prop = Prop<String>.empty();
        var listenerCallCount = 0;
        prop.addListener(() => listenerCallCount++);

        final future = prop.run(
          mockCallbacks.futureFailure,
          onFailure: mockCallbacks.onFailure,
        );

        expect(prop.isLoading, isTrue);
        expect(listenerCallCount, 1);

        await future;

        expect(prop.isLoading, isFalse);
        expect(prop.valid, isFalse);
        expect(prop.hasError, isTrue);
        expect(prop.error, 'Failure');
        expect(listenerCallCount, 2); // isLoading=true, isLoading=false + error
        verify(mockCallbacks.onFailure('Failure', any)).called(1);
      });
    });

    group('runSync()', () {
      test('handles success correctly', () {
        final prop = Prop<String>.empty();
        var listenerCallCount = 0;
        prop.addListener(() => listenerCallCount++);

        prop.runSync(
          mockCallbacks.syncSuccess,
          onSucces: mockCallbacks.onSucces,
        );

        expect(prop.valid, isTrue);
        expect(prop.value, 'Success');
        expect(prop.hasError, isFalse);
        expect(listenerCallCount, 1);
        verify(mockCallbacks.onSucces('Success')).called(1);
      });

      test('handles failure correctly', () {
        final prop = Prop<String>.empty();
        var listenerCallCount = 0;
        prop.addListener(() => listenerCallCount++);

        prop.runSync(
          mockCallbacks.syncFailure,
          onFailure: mockCallbacks.onFailure,
        );

        expect(prop.valid, isFalse);
        expect(prop.hasError, isTrue);
        expect(prop.error, 'Failure');
        expect(listenerCallCount, 1);
        verify(mockCallbacks.onFailure('Failure', any)).called(1);
      });
    });

    test('require throws StateError when not valid', () {
      final prop = Prop<String>.empty();
      expect(() => prop.require, throwsStateError);
    });
  });

  group('SyncProp', () {
    test('initializes with a value and is valid', () {
      final prop = SyncProp('initial');
      expect(prop.value, 'initial');
      expect(prop.valid, isTrue);
      expect(prop.hasError, isFalse);
    });

    test('set() updates value, marks as valid, and notifies', () {
      final prop = SyncProp('initial');
      var listenerCallCount = 0;
      prop.addListener(() => listenerCallCount++);

      prop.set('new');

      expect(prop.value, 'new');
      expect(prop.valid, isTrue);
      expect(listenerCallCount, 1);
    });
  });

  group('StreamProp', () {
    late StreamController<String> streamController;

    setUp(() {
      streamController = StreamController<String>();
    });

    tearDown(() {
      streamController.close();
    });

    test('initializes without a stream', () {
      final prop = StreamProp<String>();
      expect(prop.isHooked, isFalse);
      expect(prop.valid, isFalse);
    });

    test('hooks to a stream and receives data', () async {
      final prop = StreamProp<String>(streamController.stream);
      var listenerCallCount = 0;
      prop.addListener(() => listenerCallCount++);

      expect(prop.isHooked, isTrue);

      streamController.add('data1');
      await Future.delayed(Duration.zero); // allow stream to process

      expect(prop.value, 'data1');
      expect(prop.valid, isTrue);
      expect(prop.hasError, isFalse);
      expect(listenerCallCount, 1);
    });

    test('handles stream error', () async {
      final prop = StreamProp<String>(streamController.stream);
      var listenerCallCount = 0;
      prop.addListener(() => listenerCallCount++);

      streamController.addError('error');
      await Future.delayed(Duration.zero);

      expect(prop.hasError, isTrue);
      expect(prop.error, 'error');
      expect(prop.valid, isFalse);
      expect(listenerCallCount, 1);
    });

    test('handles stream done', () async {
      final prop = StreamProp<String>(streamController.stream);
      var listenerCallCount = 0;
      prop.addListener(() => listenerCallCount++);

      await streamController.close();
      await Future.delayed(Duration.zero);

      expect(prop.isCompleted, isTrue);
      expect(prop.isHooked, isFalse); // subscription is cancelled onDone
      expect(listenerCallCount, 1);
    });

    test('unhook() cancels subscription', () {
      final prop = StreamProp<String>(streamController.stream);
      expect(streamController.hasListener, isTrue);
      prop.unhook();
      expect(streamController.hasListener, isFalse);
      expect(prop.isHooked, isFalse);
    });
  });

  group('FutureProp', () {
    test('handles success', () async {
      final completer = Completer<String>();
      final prop = FutureProp(completer.future);

      expect(prop.isLoading, isTrue);
      expect(prop.valid, isFalse);

      completer.complete('done');
      await Future.delayed(Duration.zero); // allow future to complete

      expect(prop.isLoading, isFalse);
      expect(prop.valid, isTrue);
      expect(prop.value, 'done');
    });

    test('handles failure', () async {
      final completer = Completer<String>();
      final prop = FutureProp(completer.future);

      completer.completeError('error');
      await Future.delayed(Duration.zero);

      expect(prop.isLoading, isFalse);
      expect(prop.hasError, isTrue);
      expect(prop.error, 'error');
    });

    test('refresh re-runs with a new future', () async {
      final prop = FutureProp(Future.value('first'));
      await Future.delayed(Duration.zero);
      expect(prop.value, 'first');

      prop.refresh(Future.value('second'));
      await Future.delayed(Duration.zero);
      expect(prop.value, 'second');
    });
  });

  group('DebouncedProp', () {
    test('debounce waits for duration before running', () async {
      final prop = DebouncedProp<String>(
        debounceDuration: const Duration(milliseconds: 50),
      );

      prop.debounce(mockCallbacks.futureSuccess);
      expect(prop.isLoading, isFalse);

      await Future.delayed(const Duration(milliseconds: 60));

      expect(prop.isLoading, isFalse); // It will be false after the run
      expect(prop.value, 'Success');
      verify(mockCallbacks.futureSuccess()).called(1);
    });

    test('subsequent debounce calls cancel previous ones', () async {
      final prop = DebouncedProp<String>(
        debounceDuration: const Duration(milliseconds: 50),
      );

      prop.debounce(mockCallbacks.futureSuccess); // This will be cancelled
      await Future.delayed(const Duration(milliseconds: 20));
      prop.debounce(mockCallbacks.futureSuccess); // This will run

      await Future.delayed(const Duration(milliseconds: 60));

      verify(mockCallbacks.futureSuccess()).called(1);
    });
  });

  group('PaginatedProp', () {
    late PaginatedProp<int> prop;
    Future<List<int>> fetcher(int page) async {
      if (page < 1) throw 'Invalid page';
      return List.generate(3, (i) => (page - 1) * 3 + i);
    }

    setUp(() {
      prop = PaginatedProp(fetcher, initialPage: 1);
    });

    test('initial state is empty', () {
      expect(prop.valid, isFalse);
      expect(prop.currentPage, 1);
    });

    test('fetchInitialPage fetches page 1', () async {
      await prop.fetchInitialPage();
      expect(prop.valid, isTrue);
      expect(prop.value, [0, 1, 2]);
      expect(prop.currentPage, 1);
    });

    test('fetchNextPage increments page and fetches', () async {
      await prop.fetchInitialPage();
      await prop.fetchNextPage();
      expect(prop.value, [3, 4, 5]);
      expect(prop.currentPage, 2);
    });

    test('fetchPreviousPage decrements page and fetches', () async {
      await prop.fetchPage(2);
      await prop.fetchPreviousPage();
      expect(prop.value, [0, 1, 2]);
      expect(prop.currentPage, 1);
    });

    test('fetchPreviousPage does nothing on initial page', () async {
      await prop.fetchInitialPage();
      await prop.fetchPreviousPage();
      expect(prop.value, [0, 1, 2]); // Unchanged
      expect(prop.currentPage, 1);
    });

    test('reset() resets to initial state', () async {
      await prop.fetchPage(3);
      prop.reset();
      expect(prop.valid, isFalse);
      expect(prop.value, isNull);
      expect(prop.currentPage, 1);
    });

    test('fetcher failure is handled correctly', () async {
      prop.setFetcher((page) async => throw 'Fetcher failed');
      await prop.fetchInitialPage();
      expect(prop.hasError, isTrue);
      expect(prop.error, 'Fetcher failed');
    });
  });
}
