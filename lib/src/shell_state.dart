import 'package:view_shell/src/prop.dart';

/// Represents the overall status of a [ViewShellControl].
sealed class ViewShellState {
  /// Base constructor for a `ViewStatus`.
  const ViewShellState();
}

/// Represents a valid state where the UI can be built.
class ValidView extends ViewShellState {
  /// Creates a [ValidView] status.
  const ValidView();
}

/// A container for an error and its associated stack trace from a [PropBase].
class PropError {
  /// The error object that was thrown.
  final Object error;

  /// The stack trace associated with the error.
  final StackTrace? stackTrace;

  /// Creates a [PropError] instance.
  const PropError(this.error, this.stackTrace);
}

/// Represents a state where one or more errors have occurred in props.
class ErrorView extends ViewShellState {
  /// A map of all props that have an error, with details about the error.
  final Map<PropBase, PropError> errors;

  /// Creates an [ErrorView] status.
  const ErrorView(this.errors);
}

/// Represents a pending state, e.g., while data is loading.
class PendingView extends ViewShellState {
  /// The last valid data while the new data is pending, if available.
  final Object? staleData;

  /// Creates a [PendingView] status.
  const PendingView({this.staleData});
}
