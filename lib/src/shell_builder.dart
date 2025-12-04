import 'package:flutter/material.dart';
import 'package:view_shell/src/shell_control.dart';
import 'package:view_shell/src/shell_state.dart';

typedef ValidViewBuilder<T extends ViewShellControl> = Widget Function();

/// An abstract class that provides an interface to build view for a `ViewShell`
/// based on the current [ViewShellState].
abstract class ShellBuilder {
  /// Base constructor for a [ShellBuilder].
  const ShellBuilder();

  /// Builds the widget tree for the current state.
  ///
  /// The [child] parameter contains the widget tree that is built
  /// by the `builder` callback of the `ViewShell` and is typically
  /// only shown when the state is `ValidView`.
  Widget build(
    BuildContext context,
    ViewShellState state,
    ValidViewBuilder builder,
  );
}

/// The default [ShellBuilder] implementation for `ViewShell`.
///
/// It shows a [CircularProgressIndicator] for the pending state (including [PendingView])
/// and any other unhandled states, a centered [Text] widget for the error state,
/// and the [child] for the valid state.
class DefaultShellBuilder extends ShellBuilder {
  /// Creates a [DefaultShellBuilder].
  const DefaultShellBuilder();

  @override
  Widget build(
    BuildContext context,
    ViewShellState state,
    ValidViewBuilder builder,
  ) {
    return switch (state) {
      ValidView _ => builder(),
      ErrorView _ => const Center(child: Text('An unexpected error occurred')),
      _ => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator.adaptive(),
        ),
      ),
    };
  }
}
