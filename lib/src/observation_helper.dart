import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:view_shell/src/prop.dart';
import 'package:view_shell/src/shell_widget.dart';

typedef ConditionCallback = bool Function<T extends ShellState>(T state);

mixin ObservationHelper {
  void initObservatory(ShellState state) {
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _isFirstFrame = false,
    );
  }

  bool get _isBuildPhase {
    final phase = SchedulerBinding.instance.schedulerPhase;
    return phase == SchedulerPhase.persistentCallbacks ||
        _isFirstFrame && phase == SchedulerPhase.idle;
  }

  bool _isFirstFrame = true;

  final _observers = HashMap<PropBase, HashSet<Element>>();
  final _callBacks = HashMap<Element, HashSet<VoidCallback>>();

  void markObserversForBuild(PropBase prop) {
    final elements = _observers[prop];

    if (elements == null) return;

    final unmounted = elements.where((e) => !e.mounted).toList();

    for (final element in unmounted) {
      //If the element is registered as observing the prop it must have a registered callback
      for (final callback in _callBacks[element]!) {
        prop.removeListener(callback);
      }

      _callBacks.remove(element);

      _observers[prop]!.remove(element);

      if (_observers[prop]!.isEmpty) {
        _observers.remove(prop);
      }
    }

    if (_isBuildPhase) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => markObserversForBuild(prop),
      );
      return;
    }
    for (final element in elements) {
      element.markNeedsBuild();
    }
  }

  void addObserverFor(Element element, PropBase prop) {
    assert(
      _isBuildPhase,
      'Attempted to observe prop outside of the build method',
    );
    _observers[prop] ??= HashSet.identity();
    _observers[prop]!.add(element);

    void callback() {
      markObserversForBuild(prop);
    }

    prop.addListener(callback);

    _callBacks[element] ??= HashSet.identity();
    _callBacks[element]!.add(callback);
  }
}
