import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:view_shell/src/prop.dart';
import 'package:view_shell/src/shell_state.dart';

typedef StatusResolver = ViewShellState Function(List<PropBase> props);

/// A ShellAction is a function that takes context and returns a value or null.
///
/// This is usefull for running things like dialogs, sheets or toasts from the notifier.
/// This is a bit of controversial thing to do but i prefer it since things like dialogs are imperative, not declarative like most things flutter.
/// That means a dialog can be treated like an information source, similar to an API call.
///
/// [ViewShellControl] provides a bunch of methods to do testing on ShellActions, allowing you to test them using only dart.
typedef ShellAction<T> = FutureOr<T?> Function(BuildContext context);

/// A controller that manages the state and properties for a `ViewShell`.
abstract class ViewShellControl with ChangeNotifier {
  /// The list of props that determine the control's overall status.
  ///
  /// Props in this list will get automatically disposed if the [ViewShell] is removed.
  ///
  /// If you have props that are not in this list, they need to be manually disposed of.
  List<PropBase> get viewProps;

  /// An optional custom resolver to determine the `ViewStatus` from `viewProps`.
  StatusResolver? statusResolver;

  bool _testing = false;

  final _active = <ShellAction, Completer>{};

  BuildContext? _shellContext;

  /// Creates an instance of `ViewShellControl`.
  ViewShellControl({ViewShellState? initialStatus, this.statusResolver}) {
    // Initial status calculation
    _status =
        initialStatus ??
        statusResolver?.call(viewProps) ??
        _fallbackResolver(viewProps);

    // Add listeners to all props to recalculate status on change
    for (final prop in viewProps) {
      prop.addListener(_propListener);
    }
  }

  late ViewShellState _status;

  /// The current [ViewShellState] of this control.
  ViewShellState get state => _status;

  /// Manually calls the controller to reevaluate its props.
  @visibleForTesting
  void reevaluateProps() => _propListener();

  /// Make the controller behave like its in a ViewShell eventhough its not.
  /// This is usefull for running dart only tests on [ShellAction]s
  ///
  /// Calling this activates the [shellIsActionPending] and [shellReturnForAction] test methods.
  @visibleForTesting
  void fakeShell() {
    _testing = true;
  }

  /// Return a value for a currently pending action.
  /// If no action of this type is pending this method will throw.
  @visibleForTesting
  void shellReturnForAction<T>(ShellAction<T> action, T value) {
    if (!shellIsActionPending(action)) {
      throw StateError(
        "Attempted to return for shell action while action is not pending completion.",
      );
    }
    final completer = _active[action];
    completer!.complete(value);
  }

  /// Check wether or not an action is pending for completion by [shellReturnForAction].
  @visibleForTesting
  bool shellIsActionPending<T>(ShellAction<T> action) {
    return _active.containsKey(action);
  }

  ///Registers a new context that this [ViewShellControl] will treat as the [ViewShell].
  ///
  ///This method is used internally by [ViewShell] and should generally be avoided.
  void registerContext(BuildContext context) {
    _shellContext = context;
  }

  ///Deregisters the current shell context.
  void deregisterContext() {
    _shellContext = null;
  }

  /// Run a [ShellAction] in the context that this [ViewShellControl] was created in.
  FutureOr<T?> shellRun<T>(ShellAction<T> action) {
    if (_testing) {
      final completer = Completer<T>();
      _active[action] = completer;

      return completer.future;
    }

    if (_shellContext == null || !_shellContext!.mounted) return null;

    return action(_shellContext!);
  }

  void _propListener() {
    final newStatus =
        statusResolver?.call(viewProps) ?? _fallbackResolver(viewProps);

    if (newStatus.runtimeType != _status.runtimeType) {
      _status = newStatus;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final prop in viewProps) {
      prop.dispose();
    }
    deregisterContext();
    super.dispose();
  }
}

ViewShellState _fallbackResolver(List<PropBase> props) {
  for (final prop in props) {
    if (prop.hasError) {
      return ErrorView(prop.error!, prop.stackTrace, staleData: prop.value);
    }
  }

  for (final prop in props) {
    if (!prop.valid) {
      return PendingView(staleData: prop.value);
    }
  }

  return const ValidView();
}
