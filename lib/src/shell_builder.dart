import 'package:flutter/material.dart';
import 'package:view_shell/src/shell_status.dart';

typedef ValidViewBuilder = Widget Function();

/// An abstract class that provides an interface to build view for a `ViewShell`
/// based on the current [ShellStatus].
abstract class ShellBuilder {
  /// Base constructor for a [ShellBuilder].
  const ShellBuilder();

  /// Builds the widget tree for the current state.
  ///
  /// The [builder] callback returns the widget tree that is
  /// typically only shown when the state is `ValidView`.
  Widget build(
    BuildContext context,
    ShellStatus state,
    ValidViewBuilder builder,
  );
}

/// An implementation of [ShellBuilder] that does not show any animation.
class NoAnimationShellBuilder extends ShellBuilder {
  /// Creates a [NoAnimationShellBuilder].
  const NoAnimationShellBuilder();

  @override
  Widget build(
    BuildContext context,
    ShellStatus state,
    ValidViewBuilder builder,
  ) {
    return _switcher(state, builder);
  }
}

Widget _switcher(ShellStatus state, ValidViewBuilder builder) =>
    switch (state) {
      ValidShell _ => builder(),
      ErrorShell _ => const Text('An unexpected error occurred'),
      _ => const _LoadingIndicator(),
    };

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}

/// The default [ShellBuilder] implementation for `ViewShell`.
///
/// It shows a [CircularProgressIndicator] for the pending state (including
/// [PendingView]) and any other unhandled states, a centered [Text] widget for
/// the error state, and the `builder`'s result for the valid state.
///
/// It does a smooth fade transition in between states.
class DefaultShellBuilder extends ShellBuilder {
  /// Creates a [DefaultShellBuilder].
  const DefaultShellBuilder();

  @override
  Widget build(
    BuildContext context,
    ShellStatus state,
    ValidViewBuilder builder,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _switcher(state, builder),
    );
  }
}

/// A shell builder abstract class that can be implemented to easily create
/// custom loading and error views.
///
/// It provides a smooth fade transition between states.
abstract class SimpleShellBuilder extends ShellBuilder {
  /// Base constructor for a [SimpleShellBuilder].
  const SimpleShellBuilder();

  /// Builds the widget to display when the shell is in a loading state.
  Widget loadingBuilder(BuildContext context);

  /// Builds the widget to display when the shell is in an error state.
  Widget errorBuilder(BuildContext context, ErrorShell state);

  @override
  Widget build(
    BuildContext context,
    ShellStatus state,
    ValidViewBuilder builder,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: switch (state) {
        ValidShell _ => builder(),
        ErrorShell e => errorBuilder(context, e),
        _ => loadingBuilder(context),
      },
    );
  }
}
