import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:view_shell/src/observation_helper.dart';
import 'package:view_shell/view_shell.dart';

/// A [StatusResolver] is a function that takes a list of props and resolves them into a single [ShellStatus]
typedef StatusResolver = ShellStatus Function(List<PropBase> props);

/// A ShellAction is a function that takes context and returns a value or null.
///
/// This is usefull for running things like dialogs, sheets or toasts from the notifier.
/// This is a bit of controversial thing to do but i prefer it since things like dialogs are imperative, not declarative like most things flutter.
/// That means a dialog can be treated like an information source, similar to an API call.
///
/// [Shell] provides a bunch of methods to do testing on ShellActions, allowing you to test them using only dart.
typedef ShellAction<T> = FutureOr<T?> Function(BuildContext context);

/// A controller that manages the state and properties for a `ViewShell`.
abstract class Shell with ChangeNotifier {
  /// The list of props that determine the control's overall status.
  ///
  /// Props in this list will get automatically disposed if the [Shell] is removed.
  ///
  /// If you have props that are not in this list, they need to be manually disposed of.
  List<PropBase> get viewProps;

  /// An optional custom resolver to determine the `ViewStatus` from `viewProps`.
  StatusResolver? statusResolver;

  bool _testing = false;

  bool _isMounted = false;

  final _active = <ShellAction, Completer>{};

  BuildContext? Function()? _contextProvider;

  /// Creates an instance of `ViewShellControl`.
  Shell({this.statusResolver}) {
    {
      _status = statusResolver?.call(viewProps) ?? _fallbackResolver(viewProps);

      for (final prop in viewProps) {
        prop.addListener(_propListener);
      }
    }
  }

  late ShellStatus _status;

  /// The current [ShellStatus] of this control.
  ShellStatus get state => _status;

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
    _active.remove(action);
  }

  /// Check wether or not an action is pending for completion by [shellReturnForAction].
  @visibleForTesting
  bool shellIsActionPending<T>(ShellAction<T> action) {
    return _active.containsKey(action);
  }

  /// Registers a new context provider function that this [Shell] will use.
  ///
  /// This method is used internally by [ShellWidget] and should generally be avoided.
  void _registerContextProvider(BuildContext? Function() provider) {
    _contextProvider = provider;
  }

  /// Deregisters the current context provider.
  void _deregisterContextProvider() {
    _contextProvider = null;
  }

  /// Run a [ShellAction] in the context that this [Shell] was created in.
  ///
  /// This function can only be used if the [Shell] is fully initialized,
  /// this means you can only use it in methods that do not get called on the [Shell]s construction
  FutureOr<T?> shellRun<T>(ShellAction<T> action) {
    if (_testing) {
      final completer = Completer<T>();
      _active[action] = completer;

      return completer.future;
    }

    if (!_isMounted) {
      assert(
        _isMounted,
        '''Called [shellRun] in $runtimeType while $runtimeType was not fully initialized yet
           This means you either called shellRun in the constructor or a field body.
           This is not allowed, [shellRun] should only be called from methods not tied to the objects construction.
        ''',
      );
      return null;
    }

    final context = _contextProvider?.call();
    if (context == null || !context.mounted) return null;

    return action(context);
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
  @protected
  @mustCallSuper
  void dispose() {
    for (final prop in viewProps) {
      prop.dispose();
    }
    _deregisterContextProvider();
    super.dispose();
  }
}

ShellStatus _fallbackResolver(List<PropBase> props) {
  final errors = <PropBase, PropError>{};
  for (final prop in props) {
    if (prop.hasError) {
      errors[prop] = PropError(prop.error!, prop.stackTrace);
    }
  }

  if (errors.isNotEmpty) {
    return ErrorShell(errors);
  }

  for (final prop in props) {
    if (!prop.valid) {
      return PendingShell(staleData: prop.value);
    }
  }

  return const ValidShell();
}

class ShellWidget<T extends Shell> extends InheritedWidget {
  const ShellWidget({
    super.key,
    required this.create,
    this.builder,
    required super.child,
  });

  final T Function(BuildContext context) create;
  final ShellBuilder? builder;

  @override
  bool updateShouldNotify(ShellWidget<T> oldWidget) => false;

  @override
  InheritedElement createElement() => _ShellElement<T>(this);
}

class _ShellElement<T extends Shell> extends InheritedElement
    with ObservationHelper {
  late T shell;

  _ShellElement(super.widget) {
    initObservatory();
    final widget = super.widget as ShellWidget<T>;
    shell = widget.create(this as BuildContext);
    shell._registerContextProvider(() => (mounted) ? this : null);
    shell.addListener(_stateListener);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    shell._isMounted = true;
  }

  @override
  Widget build() {
    final builder =
        widget.builder ??
        ViewShellConfig.of(this)?.shellBuilder ??
        const DefaultShellBuilder();

    return builder.build(this, shell.state, () => super.build());
  }

  @override
  void unmount() {
    shell._isMounted = false;
    shell.dispose();
    super.unmount();
  }

  void _stateListener() {
    markNeedsBuild();
  }

  @override
  ShellWidget<T> get widget => super.widget as ShellWidget<T>;
}

extension DependOnInheritedStateOfExactType on BuildContext {
  /// Find the closest shell of type [T]
  ///
  /// This method uses a similar method to [InheritedWidget], meaning performance is O(1).
  S shell<S extends Shell>() {
    final element =
        getElementForInheritedWidgetOfExactType<ShellWidget<S>>()
            as _ShellElement<S>?;

    assert(
      element != null,
      "A ShellWidget of type $S does not exist in the given context.",
    );

    return element!.shell;
  }

  /// Make the widget observe the selected prop, if you want to just read the value of the prop use [shell].
  P prop<T extends Shell, P extends PropBase>(P Function(T shell) selector) {
    final element =
        getElementForInheritedWidgetOfExactType<ShellWidget<T>>()
            as _ShellElement<T>?;

    assert(
      element != null,
      "A ShellWidget of type $T does not exist in the given context.",
    );

    final selectedProp = selector(element!.shell);

    element.addObserverFor(this as Element, selectedProp);

    return selectedProp;
  }
}
