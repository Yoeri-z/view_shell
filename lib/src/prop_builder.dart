import 'package:flutter/material.dart';
import 'package:view_shell/src/prop.dart';
import 'package:view_shell/src/shell_widget.dart';

/// A widget that extracts and rebuilds the UI out of a selected prop from [TControl].
///
/// The builder provides the selected [TProp].
class PropBuilder<
  TWidget extends ShellWidget,
  TState extends ShellState<TWidget>,
  TProp extends PropBase
>
    extends StatelessWidget {
  /// Creates a [PropBuilder] widget.
  const PropBuilder({super.key, required this.selector, required this.builder});

  /// Selects the [PropBase] from the [TControl].
  final TProp Function(TState) selector;

  /// The builder to use when the prop is in a valid state.
  final Widget Function(BuildContext context, TProp value) builder;

  @override
  Widget build(BuildContext context) {
    final prop = context.prop<TWidget, TState, TProp>(selector);

    return ListenableBuilder(
      listenable: prop,
      builder: (context, _) => builder(context, prop),
    );
  }
}
