import 'package:flutter/widgets.dart';
import 'package:view_shell/src/prop.dart';
import 'package:view_shell/src/shell_state.dart';

typedef StatusResolver = ViewShellState Function(List<PropBase> props);

/// A controller that manages the state and properties for a `ViewShell`.
abstract class ViewShellControl with ChangeNotifier {
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

  /// The list of props that determine the control's overall status.
  ///
  /// Props in this list will get automatically disposed if the [ViewShell] is removed.
  ///
  /// If you have props that are not in this list, they need to be manually disposed of.
  List<PropBase> get viewProps;

  /// An optional custom resolver to determine the `ViewStatus` from `viewProps`.
  StatusResolver? statusResolver;

  late ViewShellState _status;

  /// The current [ViewShellState] of this control.
  ViewShellState get state => _status;

  @visibleForTesting
  ///Manually calls the controller to reevaluate its props.
  void reevaluateProps() => _propListener();

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
