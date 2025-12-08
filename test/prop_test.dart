import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:view_shell/view_shell.dart';

void main() {
  group('Prop', () {
    test('run completes with success', () async {
      final prop = Prop<int>.empty();
      await prop.run(() async => 42);
      expect(prop.state, PropState.success);
      expect(prop.require, 42);
    });

    test('run completes with error', () async {
      final prop = Prop<int>.empty();
      final error = Exception('Test Error');
      await prop.run(() async => throw error);
      expect(prop.state, PropState.error);
      expect(prop.error, error);
    });

    test('transformSync modifies value', () {
      final prop = Prop.withValue(10);
      prop.transformSync((current) => current * 2);
      expect(prop.require, 20);
    });
  });

  group('SyncProp', () {
    test('transform modifies value', () {
      final prop = SyncProp(5);
      prop.transform((current) => current + 5);
      expect(prop.value, 10);
    });
  });

  group('StreamProp', () {
    test('updates on stream events', () async {
      final controller = StreamController<int>();
      final prop = StreamProp(controller.stream);

      expect(prop.state, PropState.initial);

      controller.add(1);
      await Future.delayed(Duration.zero);
      expect(prop.state, PropState.success);
      expect(prop.value, 1);

      final error = Exception('Stream Error');
      controller.addError(error);
      await Future.delayed(Duration.zero);
      expect(prop.state, PropState.error);
      expect(prop.error, error);

      controller.add(2);
      await Future.delayed(Duration.zero);
      expect(prop.value, 2);

      await controller.close();
      await Future.delayed(Duration.zero);
      expect(prop.isCompleted, isTrue);
    });
  });

  group('FutureProp', () {
    test('reflects future states', () async {
      final completer = Completer<int>();
      final prop = FutureProp(completer.future);

      expect(prop.state, PropState.loading);

      completer.complete(100);
      await Future.delayed(Duration.zero);
      expect(prop.state, PropState.success);
      expect(prop.value, 100);
    });
  });

  group('PaginatedProp', () {
    test('fetches pages correctly', () async {
      final prop = PaginatedProp<int>((page) async {
        return [page * 10, page * 10 + 1];
      }, initialPage: 1);

      await prop.fetchInitialPage();
      expect(prop.require, [10, 11]);
      expect(prop.currentPage, 1);

      await prop.fetchNextPage();
      expect(prop.require, [20, 21]);
      expect(prop.currentPage, 2);

      await prop.fetchPreviousPage();
      expect(prop.require, [10, 11]);
      expect(prop.currentPage, 1);
    });
  });
}
