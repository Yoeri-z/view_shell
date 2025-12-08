import 'package:view_shell/src/prop.dart';

/// Represents the overall status of a [ViewShellControl].
sealed class ShellStatus {
  /// Base constructor for a `ViewStatus`.
  const ShellStatus();
}

/// Represents a valid state where the UI can be built.
final class ValidShell extends ShellStatus {
  /// Creates a [ValidShell] status.
  const ValidShell();
}

/// A container for an error and its associated stack trace from a [PropBase].
final class PropError {
  /// The error object that was thrown.
  final Object error;

  /// The stack trace associated with the error.
  final StackTrace? stackTrace;

  /// Creates a [PropError] instance.
  const PropError(this.error, this.stackTrace);
}

/// Represents a state where one or more errors have occurred in props.
final class ErrorShell extends ShellStatus {
  /// A map of all props that have an error, with details about the error.
  final Map<PropBase, PropError> errors;

  /// Creates an [ErrorShell] status.
  const ErrorShell(this.errors);
}

/// Represents a pending state, e.g., while data is loading.
final class PendingShell extends ShellStatus {
  /// The last valid data while the new data is pending, if available.
  final Object? staleData;

  /// Creates a [PendingShell] status.
  const PendingShell({this.staleData});
}
