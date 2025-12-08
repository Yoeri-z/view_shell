import 'package:flutter/widgets.dart';
import 'package:view_shell/src/observation_helper.dart';
import 'package:view_shell/view_shell.dart';

//chose to extend inheritedwidget instead of proxy widget, because flutter does not allow
//me to easily create a custom dependency system, i also want my statefulinheritedwidget to be
//able to function as a regular inherited widget
abstract class ShellWidget extends InheritedWidget {
  const ShellWidget({super.key, this.builder, required super.child});

  final ShellBuilder? builder;

  @override
  ShellElement createElement() => ShellElement(this);

  ShellState createState();

  @override
  //updateShould notify should default to false, this is chosen behaviour
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class ShellElement extends InheritedElement with ObservationHelper {
  ShellElement(super.widget) : _state = (widget as ShellWidget).createState() {
    initObservatory(_state);
    _state._widget = widget as ShellWidget;
    _state._element = this;
    _state.initState();
  }

  final ShellState _state;

  @override
  Widget build() {
    final builder =
        (widget as ShellWidget).builder ??
        ViewShellConfig.of(this)?.shellBuilder ??
        const DefaultShellBuilder();

    return builder.build(this, _state._status, () => super.build());
  }

  @override
  void update(ShellWidget newWidget) {
    _state._widget = newWidget;
    _state.didUpdateWidget();
    super.update(newWidget);
  }

  @override
  void unmount() {
    _state.dispose();
    super.unmount();
  }
}

abstract class ShellState<T extends ShellWidget> {
  ShellStatus _status = PendingShell();

  T? _widget;

  /// The [ShellWidget] belonging to this [ShellState]
  T get widget => _widget!;

  ShellElement? _element;

  /// The location (element) where this shell builds in the tree
  ///
  /// Similar to: https://api.flutter.dev/flutter/widgets/State/context.html
  BuildContext get context {
    assert(() {
      if (_element == null) {
        throw FlutterError(
          'This Shell has been unmounted, so the State no longer has a context (and should be considered defunct). \n'
          'Consider canceling any active work during "dispose" or using the "mounted" getter to determine if the State is still active.',
        );
      }
      return true;
    }());
    return _element!;
  }

  /// Wether or not the shell is mounted.
  ///
  /// Similar to: https://api.flutter.dev/flutter/widgets/State/mounted.html
  bool get mounted => _element != null;

  /// The properties that were instantiated in this class and will be displayed in the ui.
  List<PropBase> get viewProps;

  @protected
  @mustCallSuper
  void initState() {
    for (final view in viewProps) {
      view.addListener(_propListener);
    }
  }

  @protected
  void didUpdateWidget() {}

  @protected
  @mustCallSuper
  void dispose() {
    for (final view in viewProps) {
      view.dispose();
    }
  }

  void _propListener() {
    final newStatus = _resolver(viewProps);

    if (newStatus.runtimeType != _status.runtimeType) {
      _status = newStatus;
      _element?.markNeedsBuild();
    }
  }
}

ShellStatus _resolver(List<PropBase> props) {
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

extension DependOnInheritedStateOfExactType on BuildContext {
  /// Find the closest shell of type [T]
  ///
  /// This method uses a similar method to [InheritedWidget], meaning performance is O(1).
  S shell<T extends ShellWidget, S extends ShellState<T>>() {
    final element =
        getElementForInheritedWidgetOfExactType<T>() as ShellElement?;

    assert(
      element != null,
      "A ShellWidget of type $T does not exist in the given context.",
    );

    return element?._state as S;
  }

  /// Make the widget observe the selected prop, if you want to just read the value of the prop use [shell].
  P prop<T extends ShellWidget, S extends ShellState<T>, P extends PropBase>(
    P Function(S shell) selector,
  ) {
    final prop = selector(shell<T, S>());

    final element =
        getElementForInheritedWidgetOfExactType<T>() as ShellElement?;

    element!.addObserverFor(this as Element, prop);

    return prop;
  }
}
