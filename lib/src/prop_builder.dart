import 'package:flutter/material.dart';
import 'package:view_shell/view_shell.dart';

/// A widget that extracts and rebuilds the UI out of a selected prop from [TControl].
///
/// The builder provides the selected [TProp].
class PropBuilder<T extends Shell, TProp extends PropBase>
    extends StatelessWidget {
  /// Creates a [PropBuilder] widget.
  const PropBuilder({super.key, required this.selector, required this.builder});

  /// Selects the [PropBase] from the [TControl].
  final TProp Function(T shell) selector;

  /// The builder to use when the prop is in a valid state.
  final Widget Function(BuildContext context, TProp value) builder;

  @override
  Widget build(BuildContext context) {
    final prop = context.prop<T, TProp>(selector);

    return ListenableBuilder(
      listenable: prop,
      builder: (context, _) => builder(context, prop),
    );
  }
}
