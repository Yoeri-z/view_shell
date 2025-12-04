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

/// Represents a state where an error has occurred.
class ErrorView extends ViewShellState {
  /// The error object that was thrown.
  final Object error;

  /// The stack trace associated with the error.
  final StackTrace? stackTrace;

  /// The last valid data before the error occurred, if available.
  final Object? staleData;

  /// Creates an [ErrorView] status.
  const ErrorView(this.error, this.stackTrace, {this.staleData});
}

/// Represents a pending state, e.g., while data is loading.
class PendingView extends ViewShellState {
  /// The last valid data while the new data is pending, if available.
  final Object? staleData;

  /// Creates a [PendingView] status.
  const PendingView({this.staleData});
}
